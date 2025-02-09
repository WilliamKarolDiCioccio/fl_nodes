import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:uuid/uuid.dart';

import '../../../constants.dart';
import '../../models/entities.dart';
import '../../models/events.dart';
import '../../utils/json_extensions.dart';
import '../../utils/renderbox.dart';
import '../../utils/snackbar.dart';

import 'core.dart';
import 'event_bus.dart';
import 'utils.dart';

class FlNodeEditorClipboard {
  final FlNodeEditorController controller;

  NodeEditorEventBus get eventBus => controller.eventBus;
  Offset get viewportOffset => controller.viewportOffset;
  double get viewportZoom => controller.viewportZoom;
  Map<String, NodePrototype> get nodePrototypes => controller.nodePrototypes;
  Map<String, NodeInstance> get nodes => controller.nodes;
  Set<String> get selectedNodeIds => controller.selectedNodeIds;

  FlNodeEditorClipboard(this.controller);

  /// Copies the selected nodes to the clipboard.
  ///
  /// The copied nodes are deep copied to avoid altering the original nodes in the
  /// copyWith operations to reset the state of the nodes. The copied nodes are encoded
  /// to JSON and then encoded to base64 (to avoid direct tampering with the JSON data)
  /// and then copied to the clipboard.
  Future<String> copySelection() async {
    if (selectedNodeIds.isEmpty) return '';

    final encompassingRect = calculateEncompassingRect(selectedNodeIds, nodes);

    final selectedNodes = selectedNodeIds.map((id) {
      final nodeCopy = nodes[id]!.copyWith();

      final relativeOffset = nodeCopy.offset - encompassingRect.topLeft;

      // We make deep copies as we only want to copy the links that are within the selection.
      final updatedPorts = nodeCopy.ports.map((portId, port) {
        final deepCopiedLinks = port.links.where((link) {
          return selectedNodeIds.contains(link.fromTo.$1) &&
              selectedNodeIds.contains(link.fromTo.$3);
        }).toSet();

        return MapEntry(
          portId,
          port.copyWith(links: deepCopiedLinks),
        );
      });

      // Update the node with deep copied ports, state, and relative offset
      return nodeCopy.copyWith(
        offset: relativeOffset,
        state: NodeState(),
        ports: updatedPorts,
      );
    }).toList();

    late final String base64Data;

    try {
      final selectedNodesJson = selectedNodes
          .map((node) => node.toJson(controller.project.dataHandlers))
          .toList();

      final nodesJsonData = jsonEncode(selectedNodesJson);
      final encompassingRectJsonData = jsonEncode(encompassingRect.toJson());

      final jsonData = jsonEncode({
        'nodes': nodesJsonData,
        'encompassingRect': encompassingRectJsonData,
      });

      base64Data = base64Encode(utf8.encode(jsonData));
    } catch (e) {
      showNodeEditorSnackbar(
        'Failed to copy nodes. Invalid clipboard data. ($e)',
        SnackbarType.error,
      );
      return '';
    }

    await Clipboard.setData(ClipboardData(text: base64Data));

    showNodeEditorSnackbar(
      'Nodes copied to clipboard.',
      SnackbarType.success,
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
  void pasteSelection({Offset? position}) async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text!.isEmpty) return;

    late List<dynamic> nodesJson;
    late Rect encompassingRect;

    try {
      final base64Data = utf8.decode(base64Decode(clipboardData.text!));
      final jsonData = jsonDecode(base64Data) as Map<String, dynamic>;

      nodesJson = jsonDecode(jsonData['nodes']) as List<dynamic>;
      encompassingRect = JSONRect.fromJson(
        jsonDecode(jsonData['encompassingRect']),
      );
    } catch (e) {
      showNodeEditorSnackbar(
        'Failed to paste nodes. Invalid clipboard data. ($e)',
        SnackbarType.error,
      );
      return;
    }

    if (position == null) {
      final viewportSize = getSizeFromGlobalKey(kNodeEditorWidgetKey)!;

      position = Rect.fromLTWH(
        -viewportOffset.dx -
            (viewportSize.width / 2) -
            (encompassingRect.width / 2),
        -viewportOffset.dy -
            (viewportSize.height / 2) -
            (encompassingRect.height / 2),
        viewportSize.width,
        viewportSize.height,
      ).center;
    }

    // Create instances from the JSON data.
    final instances = nodesJson.map((node) {
      return NodeInstance.fromJson(
        node,
        nodePrototypes: controller.nodePrototypes,
        onRenderedCallback: controller.onRenderedCallback,
        dataHandlers: controller.project.dataHandlers,
      );
    }).toList();

    // Called on each paste, see [FlNodeEditorController._mapToNewIds] for more info.
    final newIds = await mapToNewIds(instances);

    final deepCopiedNodes = instances.map((instance) {
      return instance.copyWith(
        id: newIds[instance.id],
        offset: instance.offset + position!,
        fields: instance.fields,
        ports: instance.ports.map((key, port) {
          return MapEntry(
            port.prototype.idName,
            port.copyWith(
              links: port.links.map((link) {
                return link.copyWith(
                  id: newIds[link.id],
                  fromTo: (
                    newIds[link.fromTo.$1]!,
                    link.fromTo.$2,
                    newIds[link.fromTo.$3]!,
                    link.fromTo.$4,
                  ),
                );
              }).toSet(),
            ),
          );
        }),
      );
    }).toList();

    for (final node in deepCopiedNodes) {
      controller.addNodeFromExisting(node, isHandled: true);
    }

    eventBus.emit(
      PasteSelectionEvent(
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
  void cutSelection() async {
    final clipboardContent = await copySelection();
    for (final id in selectedNodeIds) {
      controller.removeNode(id, isHandled: true);
    }
    controller.clearSelection(isHandled: true);

    eventBus.emit(
      CutSelectionEvent(
        id: const Uuid().v4(),
        clipboardContent,
      ),
    );
  }
}
