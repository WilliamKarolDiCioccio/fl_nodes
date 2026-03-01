import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:fl_nodes_core/src/core/events/bus.dart';
import 'package:fl_nodes_core/src/core/events/events.dart';
import 'package:fl_nodes_core/src/core/localization/delegate.dart';
import 'package:fl_nodes_core/src/core/models/data.dart';
import 'package:fl_nodes_core/src/core/utils/misc/json_extensions.dart';
import 'package:fl_nodes_core/src/core/utils/misc/nodes.dart';
import 'package:fl_nodes_core/src/core/utils/rendering/renderbox.dart';
import 'package:fl_nodes_core/src/core/controller/callback.dart';
import 'package:fl_nodes_core/src/core/controller/core.dart';

/// A class that manages the clipboard operations of the node editor.
///
/// The clipboard operations include copying, pasting, and cutting nodes.
class FlNodesClipboardHelper {
  final FlNodesController controller;

  NodeEditorEventBus get eventBus => controller.eventBus;
  Offset get viewportOffset => controller.viewportOffset;
  double get viewportZoom => controller.viewportZoom;
  GlobalKey get editorKey => controller.editorKey;
  Map<String, FlNodePrototype> get nodePrototypes => controller.nodePrototypes;
  Map<String, FlNodeDataModel> get nodes => controller.nodes;
  Set<String> get selectedNodeIds => controller.selectedNodeIds;

  FlNodesClipboardHelper(this.controller);

  /// Copies the selected nodes to the clipboard.
  ///
  /// The copied nodes are deep copied to avoid altering the original nodes in the
  /// copyWith operations to reset the state of the nodes. The copied nodes are encoded
  /// to JSON and then encoded to base64 (to avoid direct tampering with the JSON data)
  /// and then copied to the clipboard.
  Future<String> copySelection({BuildContext? context}) async {
    final FlNodesLocalizations strings = FlNodesLocalizations.of(context);

    if (selectedNodeIds.isEmpty) return '';

    final Rect encompassingRect = FlNodesUtils.calculateEncompassingRect(selectedNodeIds, nodes);

    final List<FlNodeDataModel> selectedNodes = selectedNodeIds.map((id) {
      final FlNodeDataModel nodeCopy = nodes[id]!.copyWith();

      final Offset relativeOffset = nodeCopy.offset - encompassingRect.topLeft;

      // We make deep copies as we only want to copy the links that are within the selection.
      final Map<String, FlPortDataModel> updatedPorts = nodeCopy.ports.map((portId, port) {
        final Set<FlLinkDataModel> deepCopiedLinks = port.links
            .where(
              (link) =>
                  selectedNodeIds.contains(link.ports.$1.nodeId) &&
                  selectedNodeIds.contains(link.ports.$2.nodeId),
            )
            .toSet();

        return MapEntry(
          portId,
          port.copyWith(links: deepCopiedLinks),
        );
      });

      // Update the node with deep copied ports, state, and relative offset
      return nodeCopy.copyWith(
        offset: relativeOffset,
        state: FlNodeState(),
        ports: updatedPorts,
      );
    }).toList();

    late final String base64Data;

    try {
      final List<Map<String, dynamic>> selectedNodesJson =
          selectedNodes.map((node) => node.toJson(controller.project.dataHandlers)).toList();

      final String nodesJsonData = jsonEncode(selectedNodesJson);
      final String encompassingRectJsonData = jsonEncode(encompassingRect.toJson());

      final String jsonData = jsonEncode({
        'nodes': nodesJsonData,
        'encompassingRect': encompassingRectJsonData,
      });

      base64Data = base64Encode(utf8.encode(jsonData));
    } catch (e) {
      controller.onCallback?.call(
        FlCallbackType.error,
        strings.failedToCopySelectionErrorMsg(e.toString()),
      );
      return '';
    }

    await Clipboard.setData(ClipboardData(text: base64Data));

    controller.onCallback?.call(
      FlCallbackType.success,
      strings.selectionCopiedSuccessfullyMsg,
    );

    eventBus.emit(
      FlCopySelectionEvent(
        id: const Uuid().v4(),
        base64Data,
      ),
    );

    return base64Data;
  }

  /// Pastes the nodes from the clipboard to the node editor.
  ///
  /// The clipboard data is decoded from base64 and then decoded from JSON.
  /// The JSON data is then used to create instances of the nodes. All entities
  /// are then mapped to new IDs to avoid conflicts with existing nodes.
  /// The nodes are then deep copied with the new IDs and added to the node editor.
  ///
  /// See [mapToNewIds] for more info on how the new IDs are generated.
  Future<void> pasteSelection({
    Offset? position,
    BuildContext? context,
  }) async {
    final FlNodesLocalizations strings = FlNodesLocalizations.of(context);

    final ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text!.isEmpty) return;

    late List<dynamic> nodesJson;
    late Rect encompassingRect;

    try {
      final String base64Data = utf8.decode(base64Decode(clipboardData.text!));
      final jsonData = jsonDecode(base64Data) as Map<String, dynamic>;

      nodesJson = jsonDecode(jsonData['nodes'] as String) as List<dynamic>;
      encompassingRect = JSONRect.fromJson(
        jsonDecode(jsonData['encompassingRect'] as String) as Map<String, dynamic>,
      );
    } catch (e) {
      controller.onCallback?.call(
        FlCallbackType.error,
        strings.failedToPasteSelectionErrorMsg(e.toString()),
      );
      return;
    }

    if (position == null) {
      final Size viewportSize = RenderBoxUtils.getSizeFromGlobalKey(editorKey)!;

      position = Rect.fromLTWH(
        -viewportOffset.dx - (viewportSize.width / 2) - (encompassingRect.width / 2),
        -viewportOffset.dy - (viewportSize.height / 2) - (encompassingRect.height / 2),
        viewportSize.width,
        viewportSize.height,
      ).center;
    }

    // Create instances from the JSON data.
    final List<FlNodeDataModel> instances = nodesJson
        .map(
          (node) => FlNodeDataModel.fromJson(
            node as Map<String, dynamic>,
            nodePrototypes: controller.nodePrototypes,
            dataHandlers: controller.project.dataHandlers,
          ),
        )
        .toList();

    // Called on each paste, see [FlNodesController._mapToNewIds] for more info.
    final Map<String, String> newIds = FlNodesUtils.mapToNewIds(instances);

    final List<FlNodeDataModel> deepCopiedNodes = instances
        .map(
          (instance) => instance.copyWith(
            id: newIds[instance.id],
            offset: instance.offset + position!,
            fields: instance.fields,
            ports: instance.ports.map(
              (key, port) => MapEntry(
                port.prototype.idName,
                port.copyWith(
                  links: port.links
                      .map(
                        (link) => link.copyWith(
                          state: FlLinkState(),
                          id: newIds[link.id],
                          ports: (
                            (
                              nodeId: newIds[link.ports.$1.nodeId]!,
                              portId: link.ports.$1.portId,
                            ),
                            (
                              nodeId: newIds[link.ports.$2.nodeId]!,
                              portId: link.ports.$2.portId,
                            ),
                          ),
                        ),
                      )
                      .toSet(),
                ),
              ),
            ),
          ),
        )
        .toList();

    for (final node in deepCopiedNodes) {
      controller.addNodeFromExisting(node, isHandled: true);
    }

    eventBus.emit(
      FlPasteSelectionEvent(
        id: const Uuid().v4(),
        position,
        clipboardData.text!,
      ),
    );
  }

  /// Cuts the selected nodes to the clipboard.
  ///
  /// The selected nodes are copied to the clipboard and then removed from the node editor.
  /// The nodes are then removed from the node editor and the selection is cleared.
  Future<void> cutSelection({BuildContext? context}) async {
    final String clipboardContent = await copySelection();
    for (final String id in selectedNodeIds) {
      controller.removeNodeById(id, isHandled: true);
    }
    controller.clearSelection(isHandled: true);

    eventBus.emit(
      FlCutSelectionEvent(
        id: const Uuid().v4(),
        clipboardContent,
      ),
    );
  }
}
