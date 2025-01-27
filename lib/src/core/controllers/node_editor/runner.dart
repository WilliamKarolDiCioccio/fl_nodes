import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/models/events.dart';

import '../../models/entities.dart';
import '../../models/exception.dart';
import '../../utils/snackbar.dart';

import 'core.dart';

class Subgraph {
  final String id;
  final List<NodeInstance> nodes;
  final List<Subgraph> children;

  Subgraph(this.nodes, this.children) : id = const Uuid().v4();
}

class FlNodeEditorRunner {
  final FlNodeEditorController controller;
  final List<Subgraph> _topSubgraphs = [];

  Map<String, NodeInstance> get nodes => controller.nodes;

  FlNodeEditorRunner(this.controller) {
    controller.eventBus.events.listen(_handleRunnerEvents);
  }

  void _handleRunnerEvents(NodeEditorEvent event) {
    if (event is AddNodeEvent ||
        event is RemoveNodeEvent ||
        event is AddLinkEvent ||
        event is RemoveLinkEvent) {
      _identifySubgraphs();
    }
  }

  /// Identifies independent subgraphs in the graph.
  void _identifySubgraphs() {
    _topSubgraphs.clear();

    final Set<NodeInstance> visitedNodes = {};

    // Find nodes with only input ports or no input links
    for (final node in controller.nodes.values) {
      final hasOnlyInputPorts = node.ports.values.every(
        (port) => port.prototype.portType == PortType.input,
      );

      if (hasOnlyInputPorts) {
        final Subgraph subgraph = Subgraph([], []);
        _collectSubgraphFromLinks(node, visitedNodes, subgraph);
        _topSubgraphs.add(subgraph);
      }
    }

    if (kDebugMode) _debugColorNodes();
  }

  /// Recursively collects nodes in a subgraph from input links.
  /// Handles subgraph nesting by spawning new subgraphs when inputs come from multiple nodes.
  void _collectSubgraphFromLinks(
    NodeInstance node,
    Set<NodeInstance> visitedNodes,
    Subgraph currentSubgraph,
  ) {
    if (visitedNodes.contains(node)) return;

    visitedNodes.add(node);
    currentSubgraph.nodes.add(node);

    final Set<String> connectedNodeIds = {};

    final inputPorts = node.ports.values.where(
      (port) => port.prototype.portType == PortType.input,
    );

    for (final port in inputPorts) {
      for (final link in port.links) {
        final connectedNode = controller.nodes[link.fromTo.item1]!;
        connectedNodeIds.add(connectedNode.id);
      }
    }

    if (connectedNodeIds.isEmpty) return;

    if (connectedNodeIds.length > 1) {
      for (final connectedNodeId in connectedNodeIds) {
        final nodeInstance = controller.nodes[connectedNodeId]!;
        final childSubgraph = Subgraph([], []);
        _collectSubgraphFromLinks(nodeInstance, visitedNodes, childSubgraph);
        currentSubgraph.children.add(childSubgraph);
      }
    } else {
      final connectedNode = controller.nodes[connectedNodeIds.first]!;
      _collectSubgraphFromLinks(connectedNode, visitedNodes, currentSubgraph);
    }
  }

  /// Executes the entire graph asynchronously
  Future<void> executeGraph() async {
    if (controller.nodes.isEmpty) return;

    final futures = <Future<void>>[];

    for (final subgraph in _topSubgraphs) {
      futures.add(_executeSubgraph(subgraph));
    }

    // Await all subgraph executions to complete
    await Future.wait(futures);
  }

  /// Executes a single subgraph asynchronously
  Future<void> _executeSubgraph(Subgraph subgraph) async {
    for (final child in subgraph.children) {
      await _executeSubgraph(child);
    }

    for (final node in subgraph.nodes.reversed) {
      await _executeNode(node);
    }
  }

  /// Executes a single node
  Future<void> _executeNode(NodeInstance node) async {
    try {
      await Future.microtask(() async {
        await node.onExecute(
          node.ports.map(
            (key, value) => MapEntry(value.prototype.name, value),
          ),
          node.fields.map(
            (key, value) => MapEntry(value.prototype.name, value),
          ),
        );

        for (final port in node.ports.values) {
          if (port.prototype.portType == PortType.output) {
            for (final link in port.links) {
              nodes[link.fromTo.item3]!.ports[link.fromTo.item4]!.data =
                  port.data;
            }
          }
        }
      });
    } on RunnerException catch (e) {
      controller.focusNodesById({node.id});
      showNodeEditorSnackbar(
        'Error executing node ${node.id}: $e',
        SnackbarType.error,
      );
    } catch (e) {
      if (kDebugMode) {
        controller.focusNodesById({node.id});
        showNodeEditorSnackbar(
          'Error executing node ${node.id}: $e',
          SnackbarType.error,
        );
        debugPrint('Error executing node ${node.id}: $e');
      }
      rethrow;
    }
  }

  void _debugColorNodes() {
    Color generateRandomColor() {
      return Color.fromARGB(
        255,
        Random().nextInt(256),
        Random().nextInt(256),
        Random().nextInt(256),
      );
    }

    // Assign a unique color to each subgraph recursively
    void assignColorsToSubgraphs(Subgraph subgraph) {
      final randomColor = generateRandomColor();

      for (final node in subgraph.nodes) {
        node.debugColor = randomColor;
      }

      for (final child in subgraph.children) {
        assignColorsToSubgraphs(child);
      }
    }

    for (final subgraph in _topSubgraphs) {
      assignColorsToSubgraphs(subgraph);
    }
  }
}
