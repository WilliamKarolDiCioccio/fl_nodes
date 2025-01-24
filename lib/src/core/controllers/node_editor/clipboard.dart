import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/core/controllers/node_editor/event_bus.dart';

import '../../models/events.dart';
import '../../utils/constants.dart';
import '../../utils/renderbox.dart';
import '../../utils/snackbar.dart';

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

  Future<String> copySelection() async {
    if (selectedNodeIds.isEmpty) return '';

    final encompassingRect = calculateEncompassingRect(selectedNodeIds, nodes);

    final selectedNodes = selectedNodeIds.map((id) {
      final nodeCopy = nodes[id]!.copyWith();

      final relativeOffset = nodeCopy.offset - encompassingRect.topLeft;

      // We make deep copies as we only want to copy the links that are within the selection.
      final updatedPorts = nodeCopy.ports.map((portId, port) {
        final deepCopiedLinks = port.links.where((link) {
          return selectedNodeIds.contains(link.fromTo.item1) &&
              selectedNodeIds.contains(link.fromTo.item3);
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

    final jsonData = jsonEncode(selectedNodes);
    final base64Data = base64Encode(utf8.encode(jsonData));
    await Clipboard.setData(ClipboardData(text: base64Data));

    showNodeEditorSnackbar(
      'Nodes copied to clipboard.',
      SnackbarType.success,
    );

    return base64Data;
  }

  void pasteSelection({Offset? position}) async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text!.isEmpty) return;

    late List<dynamic> nodesJson;

    try {
      final jsonData = utf8.decode(base64Decode(clipboardData.text!));
      nodesJson = jsonDecode(jsonData);
    } catch (e) {
      showNodeEditorSnackbar(
        'Failed to paste nodes. Invalid clipboard data.',
        SnackbarType.error,
      );
      return;
    }

    if (position == null) {
      final viewportSize = getSizeFromGlobalKey(kNodeEditorWidgetKey)!;

      position = Rect.fromLTWH(
        viewportOffset.dx - viewportSize.width / 2,
        viewportOffset.dy - viewportSize.height / 2,
        viewportSize.width,
        viewportSize.height,
      ).center;
    }

    // Create instances from the JSON data.
    final instances = nodesJson.map((node) {
      return NodeInstance.fromJson(
        node,
        prototypes: nodePrototypes,
        onRendered: controller.onRenderedCallback,
      );
    }).toList();

    // Called on each paste, see [FlNodeEditorController._mapToNewIds] for more info.
    final newIds = await mapToNewIds(instances);

    final deepCopiedNodes = instances.map((instance) {
      return instance.copyWith(
        id: newIds[instance.id],
        offset: instance.offset + position!,
        fields: instance.fields.map((key, field) {
          return MapEntry(
            newIds[field.id]!,
            field.copyWith(id: newIds[field.id]),
          );
        }),
        ports: instance.ports.map((key, port) {
          return MapEntry(
            newIds[port.id]!,
            port.copyWith(
              id: newIds[port.id]!,
              links: port.links.map((link) {
                return link.copyWith(
                  id: newIds[link.id],
                  fromTo: Tuple4(
                    newIds[link.fromTo.item1]!,
                    newIds[link.fromTo.item2]!,
                    newIds[link.fromTo.item3]!,
                    newIds[link.fromTo.item4]!,
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
