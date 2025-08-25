import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/entities.dart';
import '../utils/rendering/renderbox.dart';

/// Calculates the encompassing rectangle of the selected nodes.
///
/// The encompassing rectangle is calculated by taking the top-left and bottom-right
/// corners of the selected nodes and expanding the rectangle to include all of them.
///
/// The `margin` parameter can be used to add padding to the encompassing rectangle.
Rect calculateEncompassingRect(
  Set<String> ids,
  Map<String, FlNodeInstance> nodes, {
  double margin = 100.0,
}) {
  Rect encompassingRect = Rect.zero;

  for (final id in ids) {
    final nodeBounds = getNodeBoundsInWorld(nodes[id]!);
    if (nodeBounds == null) continue;

    if (encompassingRect.isEmpty) {
      encompassingRect = nodeBounds;
    } else {
      encompassingRect = encompassingRect.expandToInclude(nodeBounds);
    }
  }

  return encompassingRect.inflate(margin);
}

/// Maps the IDs of the nodes, ports, and links to new UUIDs.
///
/// This function is used when pasting nodes to generate new IDs for the
/// pasted nodes, ports, and links. This is done to avoid conflicts with
/// existing nodes and to allow for multiple pastes of the same selection.
Future<Map<String, String>> mapToNewIds(List<FlNodeInstance> nodes) async {
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
