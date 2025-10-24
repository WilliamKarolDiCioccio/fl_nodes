import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../../controller/core.dart';
import '../../models/data.dart';
import '../rendering/renderbox.dart';

/// Utility class for the node editor.
class FlNodesUtils {
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

  /// Checks if a link already exists between two ports.
  static bool linkExists(
    String node1Id,
    String port1Id,
    String node2Id,
    String port2Id,
    List<FlLinkDataModel> links,
  ) {
    for (final link in links) {
      final a = link.ports.$1;
      final b = link.ports.$2;

      final sameOrder = a.nodeId == node1Id &&
          a.portId == port1Id &&
          b.nodeId == node2Id &&
          b.portId == port2Id;
      final swappedOrder = a.nodeId == node2Id &&
          a.portId == port2Id &&
          b.nodeId == node1Id &&
          b.portId == port1Id;

      if (sameOrder || swappedOrder) return true;
    }

    return false;
  }

  /// Get the source node ID of a link.
  static PortLocator getSource(
    FlNodesController controller,
    FlLinkDataModel link,
  ) {
    bool isOutputPort(FlPortDataModel port) {
      return port.prototype is FlDataOutputPortPrototype ||
          port.prototype is FlControlOutputPortPrototype;
    }

    final node1 = controller.nodes[link.ports.$1.nodeId]!;
    final port1 = node1.ports[link.ports.$1.portId]!;

    if (isOutputPort(port1)) {
      return (nodeId: link.ports.$1.nodeId, portId: link.ports.$1.portId);
    } else {
      return (nodeId: link.ports.$2.nodeId, portId: link.ports.$2.portId);
    }
  }

  /// Get the destination node ID of a link.
  static PortLocator getDestination(
    FlNodesController controller,
    FlLinkDataModel link,
  ) {
    bool isInputPort(FlPortDataModel port) {
      return port.prototype is FlDataInputPortPrototype ||
          port.prototype is FlControlInputPortPrototype;
    }

    final node1 = controller.nodes[link.ports.$1.nodeId]!;
    final port1 = node1.ports[link.ports.$1.portId]!;

    if (isInputPort(port1)) {
      return (nodeId: link.ports.$1.nodeId, portId: link.ports.$1.portId);
    } else {
      return (nodeId: link.ports.$2.nodeId, portId: link.ports.$2.portId);
    }
  }

  /// Returns the unique IDs of nodes connected to a given node trough ports of type [T].
  static Set<String> getConnectedNodesIdsForNode<T>(
    FlNodesController controller,
    FlNodeDataModel node,
  ) {
    final connectedNodeIds = <String>{};

    final ports = node.ports.values.where((port) => port.prototype is T);

    for (final port in ports) {
      for (final link in port.links) {
        if (T == FlControlInputPortPrototype || T == FlDataInputPortPrototype) {
          connectedNodeIds.add(
            FlNodesUtils.getSource(controller, link).nodeId,
          );
        } else {
          connectedNodeIds.add(
            FlNodesUtils.getDestination(controller, link).nodeId,
          );
        }
      }
    }

    return connectedNodeIds;
  }

  /// Returns the unique IDs of nodes connected to a given port.
  static Set<String> getConnectedNodesIdsForPort(
    FlNodesController controller,
    FlPortDataModel port,
  ) {
    final connectedNodeIds = <String>{};

    for (final link in port.links) {
      if (port.prototype is FlControlInputPortPrototype ||
          port.prototype is FlDataInputPortPrototype) {
        connectedNodeIds.add(
          FlNodesUtils.getSource(controller, link).nodeId,
        );
      } else {
        connectedNodeIds.add(
          FlNodesUtils.getDestination(controller, link).nodeId,
        );
      }
    }

    return connectedNodeIds;
  }
}
