import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../models/data.dart';
import '../utils/rendering/renderbox.dart';

/// Utility class for the node editor.
class FlNodeEditorUtils {
  /// Calculates the encompassing rectangle of the selected nodes.
  ///
  /// The encompassing rectangle is calculated by taking the top-left and bottom-right
  /// corners of the selected nodes and expanding the rectangle to include all of them.
  ///
  /// The `margin` parameter can be used to add padding to the encompassing rectangle.
  static Rect calculateEncompassingRect(
    Set<String> ids,
    Map<String, FlNodeDataModel> nodes, {
    double margin = 100.0,
  }) {
    final rects = ids
        .map((id) => RenderBoxUtils.getEntityBoundsInWorld(nodes[id]!))
        .whereType<Rect>();

    return RenderBoxUtils.calculateBoundingRect(rects, margin: margin);
  }

  /// Maps the IDs of the nodes, ports, and links to new UUIDs.
  ///
  /// This function is used when pasting nodes to generate new IDs for the
  /// pasted nodes, ports, and links. This is done to avoid conflicts with
  /// existing nodes and to allow for multiple pastes of the same selection.
  static Future<Map<String, String>> mapToNewIds(
    List<FlNodeDataModel> nodes,
  ) async {
    final Map<String, String> newIds = {};

    for (final node in nodes) {
      newIds[node.id] = const Uuid().v4();

      for (final port in node.ports.values) {
        for (final link in port.links) {
          newIds[link.id] = const Uuid().v4();
        }
      }
    }

    return newIds;
  }

  /// Get link IDs connected to the given nodes IDs.
  static Set<String> getConnectedLinkIds(
    Set<String> nodeIds,
    Map<String, FlNodeDataModel> nodes,
  ) {
    final Set<String> linkIds = {};

    for (final nodeId in nodeIds) {
      final node = nodes[nodeId];
      if (node == null) continue;

      for (final port in node.ports.values) {
        for (final link in port.links) {
          linkIds.add(link.id);
        }
      }
    }

    return linkIds;
  }
}
