import 'dart:async';

import 'package:fl_nodes/src/core/models/events.dart';
import 'package:fl_nodes/src/core/utils/snackbar.dart';

import '../../models/entities.dart';

import 'core.dart';

typedef OnExecute = Future<void> Function(
  Map<String, dynamic> ports,
  Map<String, dynamic> fields,
  Map<String, dynamic> execState,
  Future<void> Function(Set<String>) forward,
  void Function(Set<(String, dynamic)>) put,
);

class FlNodeEditorRunner {
  final FlNodeEditorController controller;
  Map<String, NodeInstance> _nodes = {};
  Map<String, Set<String>> _dataDeps = {};

  Set<String> _executedNodes = {};
  Map<String, Map<String, dynamic>> _execState = {};

  FlNodeEditorRunner(this.controller) {
    controller.eventBus.events.listen(_handleRunnerEvents);
  }

  /// Handles events from the controller and updates the graph accordingly.
  void _handleRunnerEvents(NodeEditorEvent event) {
    if (event is AddNodeEvent ||
        event is RemoveNodeEvent ||
        event is AddLinkEvent ||
        event is RemoveLinkEvent ||
        (event is NodeFieldEvent && event.eventType == FieldEventType.submit)) {
      _buildDepsMap();
    }
  }

  /// Identifies independent subgraphs in the graph.
  void _copyNodes() {
    // This isolates and avoids async access issues
    _nodes = controller.nodes.map((id, node) {
      final deepCopiedPorts = node.ports.map((portId, port) {
        final deepCopiedLinks = port.links.map((link) {
          return link.copyWith();
        }).toSet();

        return MapEntry(
          portId,
          port.copyWith(links: deepCopiedLinks),
        );
      });

      final deepCopiedFields = node.fields.map((fieldId, field) {
        return MapEntry(
          fieldId,
          field.copyWith(),
        );
      });

      return MapEntry(
        id,
        node.copyWith(
          ports: deepCopiedPorts,
          fields: deepCopiedFields,
        ),
      );
    });
  }

  /// Builds the data dependency map.
  void _buildDepsMap() {
    _dataDeps = {};

    _copyNodes();

    final Set<String> visited = {};

    for (final node in _nodes.values) {
      if (!node.ports.values.every(
        (port) => port.prototype.direction == PortDirection.output,
      )) {
        continue;
      }

      _findDeps(node.id, visited);
    }
  }

  // Returns the unique IDs of nodes connected to a given port.
  Set<String> _getConnectedNodeIdsFromPort(PortInstance port) {
    final connectedNodeIds = <String>{};

    for (final link in port.links) {
      final connectedNode = _nodes[
          port.prototype.direction == PortDirection.input
              ? link.fromTo.item1
              : link.fromTo.item3]!;
      connectedNodeIds.add(connectedNode.id);
    }

    return connectedNodeIds;
  }

  /// Returns the unique IDs of nodes connected to a given node's input or output ports.
  Set<String> _getConnectedNodeIdsFromNode(
    NodeInstance node,
    PortDirection direction,
    PortType type,
  ) {
    final connectedNodeIds = <String>{};

    final ports = node.ports.values.where(
      (port) =>
          port.prototype.direction == direction && port.prototype.type == type,
    );

    for (final port in ports) {
      connectedNodeIds.addAll(_getConnectedNodeIdsFromPort(port));
    }

    return connectedNodeIds;
  }

  void _findDeps(String nodeId, Set<String> visited) {
    if (visited.contains(nodeId)) return;

    visited.add(nodeId);

    _dataDeps[nodeId] = _getConnectedNodeIdsFromNode(
      _nodes[nodeId]!,
      PortDirection.input,
      PortType.data,
    );

    final connectedOutputNodeIds = _getConnectedNodeIdsFromNode(
      _nodes[nodeId]!,
      PortDirection.output,
      PortType.control,
    );

    for (final connectedNodeId in connectedOutputNodeIds) {
      _findDeps(connectedNodeId, visited);
    }
  }

  /// Executes the entire graph asynchronously
  Future<void> executeGraph() async {
    _executedNodes = {};
    _execState = {};

    for (final node in _nodes.values) {
      if (!node.ports.values.every(
        (port) => port.prototype.direction == PortDirection.output,
      )) {
        continue;
      }

      await _executeNode(node);
    }
  }

  /// Executes a node asynchronously
  Future<void> _executeNode(NodeInstance node) async {
    Future<void> forward(Set<String> portIdNames) async {
      final futures = <Future<void>>[];

      for (final portIdName in portIdNames) {
        final port = node.ports[portIdName]!;

        final connectedNodeIds = _getConnectedNodeIdsFromPort(
          port,
        );

        if (port.prototype.type != PortType.control) {
          throw Exception('Port ${port.prototype.idName} is not of type event');
        }

        for (final nodeId in connectedNodeIds) {
          futures.add(_executeNode(_nodes[nodeId]!));
        }
      }

      await Future.wait(futures);
    }

    void put(Set<(String, dynamic)> idNamesAndData) {
      for (final idNameAndData in idNamesAndData) {
        final (idName, data) = idNameAndData;

        final port = node.ports[idName]!;
        port.data = data;

        if (port.prototype.type != PortType.data) {
          throw Exception('Port ${port.prototype.idName} is not of type data');
        }

        for (final link in port.links) {
          final connectedNode = _nodes[link.fromTo.item3]!;
          final connectedPort = connectedNode.ports[link.fromTo.item4]!;

          connectedPort.data = data;
        }
      }
    }

    _executedNodes.add(node.id);

    for (final dep in _dataDeps[node.id]!) {
      if (_executedNodes.contains(dep)) continue;
      await _executeNode(_nodes[dep]!);
    }

    try {
      await node.prototype.onExecute(
        node.ports.map((portId, port) => MapEntry(portId, port.data)),
        node.fields.map((fieldId, field) => MapEntry(fieldId, field.data)),
        _execState.putIfAbsent(node.id, () => {}),
        forward,
        put,
      );
    } catch (e) {
      controller.focusNodesById({node.id});
      showNodeEditorSnackbar(
        'Error executing node: ${node.prototype.displayName}: $e',
        SnackbarType.error,
      );
      return;
    }

    _execState.remove(node.id);
  }
}
