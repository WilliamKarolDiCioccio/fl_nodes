import 'dart:async';

import 'package:fl_nodes_core/src/core/containers/ordered_set.dart';
import 'package:fl_nodes_core/src/core/controller/callback.dart';
import 'package:fl_nodes_core/src/core/controller/core.dart';
import 'package:fl_nodes_core/src/core/localization/delegate.dart';
import 'package:fl_nodes_core/src/core/utils/misc/nodes.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../events/events.dart';
import '../models/data.dart';

/// The smallest units of execution in the graph, representing a
/// linear sequence of nodes with defined control flow branching.
class _LinearizedSubgraph {
  /// The parent subgraph that this subgraph belongs to
  final _LinearizedSubgraph? parent;

  /// The control port ID that connects this subgraph to its parent
  final String? parentControlPortIdName;

  /// Child subgraphs organized by control port IDs
  /// Each control port can map to multiple branching subgraphs
  final Map<String, List<_LinearizedSubgraph>> children = {};

  /// Execution order of nodes in this subgraph, maintaining insertion order
  /// while ensuring uniqueness
  final OrderedSet<String> order = OrderedSet<String>();

  _LinearizedSubgraph({this.parent, this.parentControlPortIdName});
}

/// Represents the execution state of a node during graph execution.
enum FlNodeExecutionState {
  /// Node has not been stepped yet
  idle,

  /// Node execution has been requested and is waiting for dependencies
  pending,

  /// Node is currently executing
  executing,

  /// Node has stepped but hasn't completed its lifecycle (e.g., feedback loops)
  stepped,

  /// Node has completed execution successfully
  completed,

  /// Node execution failed with an exception
  exception,
}

/// Represents the overall state of the execution helper.
enum ExecutionHelperState {
  /// The execution helper is idle and not building or executing
  idle,

  /// The execution helper is currently building the graph
  building,

  /// The execution helper is currently executing the graph
  executing,

  /// The execution helper has been aborted
  aborted,

  /// The execution helper encountered an exception
  exception,
}

/// A graph execution engine for visual scripting nodes.
///
/// This class manages the execution of node-based visual scripts by:
/// - Building an execution graph through topological sorting
/// - Handling hierarchical subgraphs for control flow
/// - Managing data dependencies between nodes
/// - Executing nodes in the correct order while respecting dependencies
class FlNodesExecutionHelper {
  final FlNodesController controller;

  // Debounce timers for automatic graph rebuilding and execution
  Timer? _buildGraphDelayTimer;
  Timer? _runGraphDelayTimer;

  // Current project data snapshot
  FlNodesProjectDataModel projectData = FlNodesProjectDataModel(
    nodes: {},
    links: {},
  );

  Map<String, FlNodeDataModel> get nodes => projectData.nodes;

  // Execution state management
  final List<_LinearizedSubgraph> _independentGraphs = [];
  final Map<String, FlNodeExecutionState> _nodeStates = {};
  final Map<String, Map<String, dynamic>> _execState = {};

  FlNodesExecutionHelper(this.controller) {
    controller.eventBus.events.listen(_handleRunnerEvents);
  }

  void clear() {
    projectData = FlNodesProjectDataModel(
      nodes: {},
      links: {},
    );

    _execState.clear();
    _nodeStates.clear();
    _independentGraphs.clear();

    dispose();
  }

  void dispose() {
    _buildGraphDelayTimer?.cancel();
    _runGraphDelayTimer?.cancel();
    _abortController.close();
  }

  /// Handles events from the controller and updates the graph accordingly.
  void _handleRunnerEvents(NodeEditorEvent event) {
    if (event.isHandled) return;

    if (event is FlLoadProjectEvent || event is FlNewProjectEvent) {
      _buildGraphDelayTimer?.cancel();
      _runGraphDelayTimer?.cancel();

      if (controller.config.autoBuildGraph) {
        buildGraph();

        if (controller.config.autoExecGraph) {
          executeGraph();
        }
      }
    }

    if (event is FlAddNodeEvent ||
        event is FlRemoveNodeEvent ||
        event is FlAddLinkEvent ||
        event is FlRemoveLinkEvent ||
        event is FlCutSelectionEvent ||
        event is FlPasteSelectionEvent ||
        (event is FlNodeFieldEvent &&
            event.eventType == FlFieldEventType.submit)) {
      if (controller.config.autoBuildGraph) {
        _buildGraphDelayTimer?.cancel();
        _buildGraphDelayTimer =
            Timer(controller.config.autoBuildGraphDelay, () {
          buildGraph();

          if (controller.config.autoExecGraph) {
            _runGraphDelayTimer?.cancel();
            _runGraphDelayTimer =
                Timer(controller.config.autoExecGraphDelay, () {
              executeGraph();
            });
          }
        });
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Abort handling.
  ////////////////////////////////////////////////////////////////////////////////

  final _abortController = StreamController<bool>.broadcast();
  var _currentBuildToken = Object();
  var _currentExecutionToken = Object();
  ExecutionHelperState _state = ExecutionHelperState.idle;

  ExecutionHelperState get state => _state;

  /// Signal to abort current operations
  void abort({String reason = 'User requested abort'}) {
    if (_state == ExecutionHelperState.aborted) return;

    final wasBuilding = _state == ExecutionHelperState.building;
    final wasExecuting = _state == ExecutionHelperState.executing;

    _state = ExecutionHelperState.aborted;
    _abortController.add(true);
    _buildGraphDelayTimer?.cancel();
    _runGraphDelayTimer?.cancel();
    _execState.clear();
    _nodeStates.clear();

    if (wasBuilding) {
      controller.eventBus.emit(
        FlGraphBuildAbortedEvent(
          id: const Uuid().v4(),
          reason: reason,
        ),
      );
    } else if (wasExecuting) {
      controller.eventBus.emit(
        FlGraphRunAbortedEvent(
          id: const Uuid().v4(),
          reason: reason,
        ),
      );
    }
  }

  /// Check if abort was requested
  bool _shouldAbort(Object token) {
    // Invalidate old tokens when new operations start
    if (token != _currentBuildToken && token != _currentExecutionToken) {
      return true;
    }

    return _state == ExecutionHelperState.aborted;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Graph building.
  ////////////////////////////////////////////////////////////////////////////////

  /// Builds the execution graph by analyzing node dependencies and control flow
  void buildGraph() {
    if (_state == ExecutionHelperState.building) {
      abort(reason: 'New build requested');
    }

    _state = ExecutionHelperState.building;
    final buildToken = _currentBuildToken = Object();

    try {
      projectData = controller.project.projectData.copyWith();

      _independentGraphs.clear();

      final startTime = DateTime.now();

      controller.eventBus.emit(
        FlGraphBuildStartEvent(
          id: const Uuid().v4(),
          startTime: startTime,
        ),
      );

      if (_shouldAbort(buildToken)) return;

      _independentGraphs.addAll(
        _findAndLinearizeSubgraphs(token: buildToken),
      );

      if (!_shouldAbort(buildToken)) {
        _state = ExecutionHelperState.idle;
      } else {
        return;
      }

      controller.eventBus.emit(
        FlGraphBuildCompleteEvent(
          id: const Uuid().v4(),
          timeTaken: DateTime.now().difference(startTime).abs(),
        ),
      );
    } catch (e) {
      if (!_shouldAbort(buildToken)) {
        _state = ExecutionHelperState.exception;
        rethrow;
      }
    }
  }

  /// Finds starting nodes and builds independent subgraphs
  ///
  /// A starting node is defined as a node with no data inputs, no control inputs,
  /// but at least one control output. These nodes serve as entry points for
  /// independent execution graphs. Such graphs will be executed sequentially and won't interfere with each other.
  /// It's in the nature of visul scripting that partially (but no totally) overlapping independent graphs can exist.
  List<_LinearizedSubgraph> _findAndLinearizeSubgraphs(
      {required Object token}) {
    // Find starting nodes (no data inputs, no control inputs, but has control outputs)
    final startingNodes = nodes.keys.where((nodeId) {
      final node = nodes[nodeId]!;

      final hasDataInputs =
          FlNodesUtils.getConnectedNodesIdsForNode<FlDataInputPortPrototype>(
        controller,
        node,
      ).isNotEmpty;

      final hasControlInputs =
          FlNodesUtils.getConnectedNodesIdsForNode<FlControlInputPortPrototype>(
        controller,
        node,
      ).isNotEmpty;

      final hasControlOutputs = FlNodesUtils.getConnectedNodesIdsForNode<
          FlControlOutputPortPrototype>(
        controller,
        node,
      ).isNotEmpty;

      return !hasDataInputs && !hasControlInputs && hasControlOutputs;
    }).toList();

    final linearized = <_LinearizedSubgraph>[];

    // Build subgraphs starting from each starting node (independent graphs might overlap)
    for (final start in startingNodes) {
      final nodeToSubgraph = <String, _LinearizedSubgraph>{};

      if (nodeToSubgraph.containsKey(start)) {
        throw Exception(
          'Node $start has already been processed in another subgraph.',
        );
      }

      final sub = _linearizeSubgraphs(
        start,
        parent: null,
        nodeToSubgraph: nodeToSubgraph,
        token: token,
      );

      if (sub == null) return linearized; // Aborted during linearization

      linearized.add(sub);
    }

    return linearized;
  }

  /// Recursively linearizes the graph into hierarchical subgraphs for execution
  ///
  /// This method performs a modified topological sort that respects both:
  /// - Data dependencies (executed before dependent nodes, forbids cycles)
  /// - Control flow (creates subgraphs for branching, allows cycles)
  _LinearizedSubgraph? _linearizeSubgraphs(
    String rootNodeId, {
    _LinearizedSubgraph? parent,
    String? parentControlPortIdName,
    required Object token,
    required Map<String, _LinearizedSubgraph> nodeToSubgraph,
  }) {
    if (_shouldAbort(token)) return null;

    // Create new child subgraph for this control port branch
    final current = _LinearizedSubgraph(
      parent: parent,
      parentControlPortIdName: parentControlPortIdName,
    );

    // Register child into parent's children map
    if (parent != null) {
      if (parentControlPortIdName == null) {
        throw Exception(
          'parentControlPortIdName must be provided when parent is not null.',
        );
      }

      parent.children.putIfAbsent(parentControlPortIdName, () => []);
      parent.children[parentControlPortIdName]!.add(current);
    }

    // Recursively backward traverse data dependencies
    void collectDataDependencies(
      String nodeId,
      _LinearizedSubgraph owner,
    ) {
      if (_shouldAbort(token)) return;

      // For simplicity, we don't check if data dependencies are already assigned to subgraphs.
      // Double execution of data dependencies is prevented in the execution phase by checking node states.
      // This means data dependencies can figure in multiple subgraphs without issues.

      final node = nodes[nodeId]!;
      final dataDeps =
          FlNodesUtils.getConnectedNodesIdsForNode<FlDataInputPortPrototype>(
              controller, node);

      // First collect all data dependencies recursively to ensure execution order correctness
      for (final dep in dataDeps) {
        collectDataDependencies(dep, owner);
      }

      // Then add the current node itself if not already added (which would mean all its dependencies are already added too)
      if (!owner.order.contains(nodeId) &&
          !nodeToSubgraph.containsKey(nodeId)) {
        owner.order.add(nodeId);
        nodeToSubgraph[nodeId] = owner;
      }
    }

    // Recursively forward traverse control flow
    void traverseControl(
      String nodeId,
      _LinearizedSubgraph owner,
    ) {
      if (_shouldAbort(token)) return;

      // If the node is already assigned to a subgraph, abort traversal
      if (nodeToSubgraph.containsKey(nodeId)) return;

      // Ensure data dependencies are placed before this node inside the same owner subgraph
      collectDataDependencies(
        nodeId,
        owner,
      );

      // Add the control node itself
      nodeToSubgraph[nodeId] = owner;
      owner.order.add(nodeId);

      final node = nodes[nodeId]!;
      final nodesForControlPort = <String, Set<String>>{};

      // Gather all control output connections
      final controlPorts = node.ports.values
          .where((port) => port.prototype is FlControlOutputPortPrototype);

      if (controlPorts.isEmpty) return;

      // Map all control outputs to their connected nodes
      for (final controlPort in controlPorts) {
        nodesForControlPort.putIfAbsent(
            controlPort.prototype.idName, () => <String>{});
        nodesForControlPort[controlPort.prototype.idName]!.addAll(
          FlNodesUtils.getConnectedNodesIdsForPort(
            controller,
            controlPort,
          ),
        );
      }

      // Determine branching strategy based on number of control ports and connected nodes
      //
      // - Single control port:
      //   - Single connected node: continue traversal in the same subgraph
      //   - Multiple connected nodes: each node gets its own subgraph
      // - Multiple control ports:
      //  - Each control port gets its own subgraph, even if it has a single connection
      //  - Each connected node gets its own subgraph if there are multiple connections
      //
      // This phase also performs a lookahead to see if connected nodes are already assigned to subgraphs,
      // in which case it links to those subgraphs directly instead of creating new ones.
      if (controlPorts.length == 1) {
        final portIdName = controlPorts.first.prototype.idName;
        final connectedNodes = nodesForControlPort[portIdName]!;

        if (connectedNodes.length == 1) {
          final nextNodeId = connectedNodes.first;

          if (nodeToSubgraph.containsKey(nextNodeId)) {
            current.children.putIfAbsent(portIdName, () => []);
            current.children[portIdName]!.add(nodeToSubgraph[nextNodeId]!);
          } else {
            traverseControl(nextNodeId, owner);
          }
        } else {
          for (final nextNodeId in connectedNodes) {
            if (nodeToSubgraph.containsKey(nextNodeId)) {
              current.children.putIfAbsent(portIdName, () => []);
              current.children[portIdName]!.add(nodeToSubgraph[nextNodeId]!);
              continue;
            }

            _linearizeSubgraphs(
              nextNodeId,
              parent: owner,
              parentControlPortIdName: portIdName,
              nodeToSubgraph: nodeToSubgraph,
              token: token,
            );
          }
        }
      } else {
        for (final entry in nodesForControlPort.entries) {
          final portIdName = entry.key;
          final connectedNodes = entry.value;

          if (connectedNodes.isEmpty) continue;

          for (final nextNodeId in connectedNodes) {
            if (nodeToSubgraph.containsKey(nextNodeId)) {
              current.children.putIfAbsent(portIdName, () => []);
              current.children[portIdName]!.add(nodeToSubgraph[nextNodeId]!);
              continue;
            }

            _linearizeSubgraphs(
              nextNodeId,
              parent: owner,
              parentControlPortIdName: portIdName,
              nodeToSubgraph: nodeToSubgraph,
              token: token,
            );
          }
        }
      }
    }

    // Start traversal from the root node of the current subgraph
    traverseControl(rootNodeId, current);

    return current;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Graph execution.
  //////////////////////////////////////////////////////////////////////////////////

  /// Executes the entire graph by processing independent subgraphs sequentially
  ///
  /// [BuildContext] context: The build context for localization of error messages (optional).
  void executeGraph({BuildContext? context}) async {
    if (_state == ExecutionHelperState.executing) {
      abort(reason: 'New execution requested');
    }

    _state = ExecutionHelperState.executing;
    final executionToken = _currentExecutionToken = Object();

    context ??= controller.editorKey.currentContext;

    _execState.clear();
    _nodeStates.clear();

    for (final nodeId in nodes.keys) {
      _nodeStates[nodeId] = FlNodeExecutionState.idle;
    }

    if (_shouldAbort(executionToken)) return;

    final startTime = DateTime.now();

    controller.eventBus.emit(
      FlGraphRunStartEvent(
        id: const Uuid().v4(),
        startTime: startTime,
      ),
    );

    // Execute independent subgraphs sequentially
    for (final graph in _independentGraphs) {
      if (_shouldAbort(executionToken)) return;
      await _executeLinearizedGraph(graph, context: context);
    }

    if (!_shouldAbort(executionToken)) {
      _state = ExecutionHelperState.idle;
    } else {
      return;
    }

    controller.eventBus.emit(
      FlGraphRunCompleteEvent(
        id: const Uuid().v4(),
        timeTaken: DateTime.now().difference(startTime).abs(),
      ),
    );
  }

  /// Executes a linearized subgraph of nodes in order
  Future<void> _executeLinearizedGraph(
    _LinearizedSubgraph graph, {
    BuildContext? context,
  }) async {
    Set<String> lastSelectedControlPortIdNames = {};

    // Execute nodes in order
    for (final nodeId in graph.order.toList()) {
      lastSelectedControlPortIdNames =
          await _executeNode(nodes[nodeId]!, context: context);
    }

    // Execute child subgraphs for the selected control ports
    for (final controlPortIdName in lastSelectedControlPortIdNames) {
      final childSubgraphs = graph.children[controlPortIdName] ?? [];

      // Execute each child subgraph for the selected control port sequentially
      for (final childSubgraph in childSubgraphs) {
        await _executeLinearizedGraph(childSubgraph);
      }
    }
  }

  /// Executes a single node, managing its execution state and handling errors
  Future<Set<String>> _executeNode(
    FlNodeDataModel node, {
    BuildContext? context,
  }) async {
    void setNodeState(FlNodeExecutionState state) {
      _nodeStates[node.id] = state;

      controller.eventBus.emit(
        FlNodeExecutionStateEvent(
          id: const Uuid().v4(),
          node.id,
          state,
        ),
      );
    }

    // Cache localization strings
    final strings = FlNodesLocalizations.of(context);

    final Set<String> selectedControlPortIdNames = {};

    // Set node state to executing
    setNodeState(FlNodeExecutionState.executing);

    // Ensure all data dependencies are ready before execution (assertion)
    if (!_areDataDependenciesReady(node.id)) {
      throw Exception(
        'Data dependencies for node ${node.id} are not ready.',
      );
    }

    // Execute the node's onExecute callback
    // The whole execution is wrapped in a try-catch to handle user code exceptions gracefully
    try {
      await node.prototype.onExecute?.call(
        node.ports.map((portId, port) => MapEntry(portId, port.data)),
        node.fields.map((fieldId, field) => MapEntry(fieldId, field.data)),
        _execState.putIfAbsent(node.id, () => {}),
        (portIdNames, {definitive = false}) {
          if (_shouldAbort(_currentExecutionToken)) return;

          selectedControlPortIdNames.addAll(portIdNames);

          // Check the definitive flag to determine if execution is complete or stepped (for feedback loops)
          if (definitive) {
            setNodeState(FlNodeExecutionState.completed);
          } else {
            setNodeState(FlNodeExecutionState.stepped);
          }
        },
        (idNamesAndData) => _put(node, idNamesAndData),
      );

      if (_nodeStates[node.id] == FlNodeExecutionState.executing) {
        setNodeState(FlNodeExecutionState.stepped);
      }
    } catch (e) {
      // Immediately set node state to exception on error
      setNodeState(FlNodeExecutionState.exception);

      // Abort the entire execution on node error
      abort(reason: 'Node ${node.id} execution failed');

      // Focus the node that caused the error (UI feedback)
      controller.focusNodesById({node.id});

      // Invoke the error callback with a localized error message
      controller.onCallback?.call(
        FlCallbackType.error,
        strings.failedToExecuteNodeErrorMsg(e.toString()),
      );

      return {};
    }

    return selectedControlPortIdNames;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Helpers.
  //////////////////////////////////////////////////////////////////////////////////

  /// Check if all data dependencies for a node are ready (stepped and completed)
  bool _areDataDependenciesReady(String nodeId) {
    final dataDependencies =
        FlNodesUtils.getConnectedNodesIdsForNode<FlDataInputPortPrototype>(
      controller,
      nodes[nodeId]!,
    );

    for (final depNodeId in dataDependencies) {
      final depState = _nodeStates[depNodeId];

      // Data dependency must be completed to be considered ready
      if (depState != FlNodeExecutionState.completed &&
          depState != FlNodeExecutionState.stepped) {
        return false;
      }
    }

    return true;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Node execution callbacks.
  //////////////////////////////////////////////////////////////////////////////////

  /// A function that forwards events to connected nodes through control ports.
  ///
  /// The function takes a [Set] of unique IDs of the ports to forward events to and
  /// returns a [Future] that completes when all connected nodes have been stepped
  ///
  /// [Future] _forward(FlNodeDataModel node, [Set] portIdNames) async;

  /// A function that puts data into connected nodes through data ports.
  ///
  /// The function takes a [Set] of records containing the unique ID of the port and the data to be put into the port.
  void _put(FlNodeDataModel node, Set<(String, dynamic)> idNamesAndData) {
    for (final idNameAndData in idNamesAndData) {
      final (idName, data) = idNameAndData;

      final port = node.ports[idName]!;

      if (port.prototype is! FlDataInputPortPrototype &&
          port.prototype is! FlDataOutputPortPrototype) {
        throw Exception(
          'Port ${port.prototype.idName} is not of type data',
        );
      }

      for (final link in port.links) {
        final locator = FlNodesUtils.getDestination(
          controller,
          link,
        );

        final connectedPort = nodes[locator.nodeId]!.ports[locator.portId]!;

        connectedPort.data = data;
      }
    }
  }
}
