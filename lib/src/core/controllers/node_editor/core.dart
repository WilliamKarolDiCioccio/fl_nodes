import 'dart:math';

import 'package:flutter/material.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/controllers/node_editor/history.dart';
import 'package:fl_nodes/src/core/controllers/node_editor/project.dart';
import 'package:fl_nodes/src/core/models/events.dart';
import 'package:fl_nodes/src/core/utils/constants.dart';
import 'package:fl_nodes/src/core/utils/renderbox.dart';
import 'package:fl_nodes/src/core/utils/spatial_hash_grid.dart';

import '../../models/entities.dart';

import 'clipboard.dart';
import 'config.dart';
import 'event_bus.dart';
import 'runner.dart';
import 'utils.dart';

/// A controller class for the Node Editor.
///
/// This class is responsible for managing the state of the node editor,
/// including the nodes, links, and the viewport. It also provides methods
/// for adding, removing, and manipulating nodes and links.
///
/// The controller also provides an event bus for the node editor, allowing
/// different parts of the application to communicate with each other by
/// sending and receiving events.
class FlNodeEditorController {
  final NodeEditorConfig behavior;
  final eventBus = NodeEditorEventBus();

  late final FlNodeEditorClipboard clipboard;
  late final FlNodeEditorRunner runner;
  late final FlNodeEditorHistory history;
  late final FlNodeEditorProject project;

  FlNodeEditorController({
    this.behavior = const NodeEditorConfig(),
    Future<bool> Function(Map<String, dynamic> jsonData)? projectSaver,
    Future<Map<String, dynamic>?> Function(bool isSaved)? projectLoader,
    Future<bool> Function(bool isSaved)? projectCreator,
  }) {
    clipboard = FlNodeEditorClipboard(this);
    runner = FlNodeEditorRunner(this);
    history = FlNodeEditorHistory(this);
    project = FlNodeEditorProject(
      this,
      projectSaver: projectSaver,
      projectLoader: projectLoader,
      projectCreator: projectCreator,
    );
  }

  /// This method is used to dispose of the node editor controller and all of its resources, subsystems and members.
  void dispose() {
    eventBus.close();
    history.clear();
    project.clear();

    clear();
  }

  /// This method is used to clear all members of the node editor controller.
  void clear() {
    _nodes.clear();
    _spatialHashGrid.clear();
    _selectedNodeIds.clear();
    _renderLinks.clear();
  }

  // Viewport
  Offset viewportOffset = Offset.zero;
  double viewportZoom = 1.0;

  /// This method is used to set the offset of the viewport.
  ///
  /// The 'animate' parameter is used to animate the transition to the new offset.
  /// The 'absolute' parameter is used to choose whether the offset is added to the the current
  /// offset or set as an absolute value. The 'isHandled' parameter is used to indicate whether
  void setViewportOffset(
    Offset coords, {
    bool animate = true,
    bool absolute = false,
    bool isHandled = false,
  }) {
    if (absolute) {
      viewportOffset = coords;
    } else {
      viewportOffset += coords;
    }

    eventBus.emit(
      ViewportOffsetEvent(
        id: const Uuid().v4(),
        viewportOffset,
        animate: animate,
        isHandled: isHandled,
      ),
    );
  }

  /// This method is used to set the zoom level of the viewport.
  ///
  /// The 'animate' parameter is used to animate the zoom transition.
  void setViewportZoom(
    double amount, {
    bool animate = true,
    bool isHandled = false,
  }) {
    viewportZoom = amount;

    eventBus.emit(
      ViewportZoomEvent(
        id: const Uuid().v4(),
        viewportZoom,
        isHandled: isHandled,
      ),
    );
  }

  // Nodes, links and groups
  final Map<String, NodePrototype> _nodePrototypes = {};
  final SpatialHashGrid _spatialHashGrid = SpatialHashGrid();
  final Map<String, NodeInstance> _nodes = {};

  List<NodePrototype> get nodePrototypesAsList =>
      _nodePrototypes.values.map((e) => e).toList();
  Map<String, NodePrototype> get nodePrototypes => _nodePrototypes;

  List<NodeInstance> get nodesAsList {
    final nodesList = _nodes.values.toList();

    // We sort the nodes list so that selected nodes are rendered on top of others.
    nodesList.sort((a, b) {
      if (selectedNodeIds.contains(a.id) && !selectedNodeIds.contains(b.id)) {
        return 1;
      } else if (!selectedNodeIds.contains(a.id) &&
          selectedNodeIds.contains(b.id)) {
        return -1;
      } else {
        return 0;
      }
    });

    return nodesList;
  }

  Map<String, NodeInstance> get nodes => _nodes;
  SpatialHashGrid get spatialHashGrid => _spatialHashGrid;

  /// This method is used to register a node prototype with the node editor.
  ///
  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void registerNodePrototype(NodePrototype name) {
    _nodePrototypes.putIfAbsent(
      name.name,
      () => name,
    );
  }

  /// This method is used to remove a node prototype by its name.
  ///
  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void unregisterNodePrototype(String name) {
    if (!_nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    } else {
      _nodePrototypes.remove(name);
    }
  }

  /// This method is used to add a [NodeInstance] to the node editor by its prototype name.
  ///
  /// The method takes the name of the node prototype and creates an instance of the node
  /// based on the prototype. The method also takes an optional offset parameter to set the
  /// initial position of the node in the node editor. The node is also inserted into the
  /// spatial hash grid for efficient querying of nodes based on their positions
  ///
  /// See [SpatialHashGrid] and [selectNodesByArea].
  ///
  /// Emits an [AddNodeEvent] event.
  NodeInstance addNode(String name, {Offset? offset}) {
    if (!_nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    }

    final instance = createNode(
      _nodePrototypes[name]!,
      controller: this,
      offset: offset,
    );

    _nodes.putIfAbsent(
      instance.id,
      () => instance,
    );

    eventBus.emit(
      AddNodeEvent(id: const Uuid().v4(), instance),
    );

    return instance;
  }

  /// This method is used to add a node from an existing node object.
  ///
  /// This method is used when loading a project from a file or in copy/paste operations
  /// and preserves all properties of the node object.
  ///
  /// Emits an [AddNodeEvent] event.
  void addNodeFromExisting(
    NodeInstance node, {
    bool isHandled = false,
    String? eventId,
  }) {
    if (_nodes.containsKey(node.id)) return;

    _nodes.putIfAbsent(
      node.id,
      () => node,
    );

    eventBus.emit(
      AddNodeEvent(
        id: eventId ?? const Uuid().v4(),
        node,
        isHandled: isHandled,
      ),
    );

    for (final port in node.ports.values) {
      for (final link in port.links) {
        addLinkFromExisting(link, isHandled: isHandled);
      }
    }
  }

  /// This method is used to remove a node by its ID.
  ///
  /// Emits a [RemoveNodeEvent] event.
  void removeNode(
    String id, {
    String? eventId,
    bool isHandled = false,
  }) async {
    if (!_nodes.containsKey(id)) return;

    final node = _nodes[id]!;

    for (final port in node.ports.values) {
      final linksToRemove = port.links.map((link) => link.id).toList();

      for (final linkId in linksToRemove) {
        removeLinkById(linkId, isHandled: true);
      }
    }

    _spatialHashGrid.remove(id);
    _nodes.remove(id);

    eventBus.emit(
      RemoveNodeEvent(
        id: eventId ?? const Uuid().v4(),
        node,
        isHandled: isHandled,
      ),
    );
  }

  /// This method is used to add a link between two ports.
  ///
  /// The method takes the IDs of the two nodes and the two ports and creates a link
  /// between them. The method also checks if the link is valid based on the port types
  /// and the number of links allowed on each port. Moreover, the method enforces the
  /// direction of the link based on the port types, i.e., an output port can only be
  /// connected to an input port guaranteeing that the graph is directed the right way.
  ///
  /// Emits an [AddLinkEvent] event.
  Link? addLink(
    String node1Id,
    String port1Id,
    String node2Id,
    String port2Id, {
    String? eventId,
  }) {
    // Check for self-links
    if (node1Id == node2Id || port1Id == port2Id) return null;

    final port1 = _nodes[node1Id]!.ports[port1Id]!;
    final port2 = _nodes[node2Id]!.ports[port2Id]!;

    // Check if the ports are compatible
    if (port1.prototype.portType == port2.prototype.portType) return null;

    // Check if the ports allow multiple links
    if (port1.links.length > 1 && !port1.prototype.allowMultipleLinks ||
        port2.links.length > 1 && !port2.prototype.allowMultipleLinks) {
      return null;
    }

    // Check if the link already exists.
    if (port1.links.any((link) =>
            link.fromTo.item1 == node2Id && link.fromTo.item2 == port2Id) ||
        port2.links.any((link) =>
            link.fromTo.item1 == node1Id && link.fromTo.item2 == port1Id)) {
      return null;
    }

    late Tuple4<String, String, String, String> fromTo;

    // Determine the direction of the link based on the port types as we're building a directed graph.
    if (port1.prototype.portType == PortType.output) {
      fromTo = Tuple4(node1Id, port1Id, node2Id, port2Id);
    } else {
      fromTo = Tuple4(node2Id, port2Id, node1Id, port1Id);
    }

    final link = Link(
      id: const Uuid().v4(),
      fromTo: fromTo,
    );

    port1.links.add(link);
    port2.links.add(link);

    _renderLinks.putIfAbsent(
      link.id,
      () => link,
    );

    eventBus.emit(
      AddLinkEvent(id: eventId ?? const Uuid().v4(), link),
    );

    return link;
  }

  /// This method is used to add a link from an existing link object.
  ///
  /// This method is used when loading a project from a file or in copy/paste operations
  /// and preserves all properties of the link object.
  ///
  /// Emits an [AddLinkEvent] event.
  void addLinkFromExisting(
    Link link, {
    String? eventId,
    bool isHandled = false,
  }) {
    if (!_nodes.containsKey(link.fromTo.item1) ||
        !_nodes.containsKey(link.fromTo.item3)) {
      return;
    }

    final fromNode = _nodes[link.fromTo.item1]!;
    final toNode = _nodes[link.fromTo.item3]!;

    if (!fromNode.ports.containsKey(link.fromTo.item2) ||
        !toNode.ports.containsKey(link.fromTo.item4)) {
      return;
    }

    final fromPort = _nodes[link.fromTo.item1]!.ports[link.fromTo.item2]!;
    final toPort = _nodes[link.fromTo.item3]!.ports[link.fromTo.item4]!;

    fromPort.links.add(link);
    toPort.links.add(link);

    _renderLinks.putIfAbsent(
      link.id,
      () => link,
    );

    eventBus.emit(
      AddLinkEvent(
        id: eventId ?? const Uuid().v4(),
        link,
        isHandled: isHandled,
      ),
    );
  }

  /// This method is used to remove a link by its ID.
  ///
  /// Emits a [RemoveLinkEvent] event.
  void removeLinkById(
    String id, {
    String? eventId,
    bool isHandled = false,
  }) {
    if (!_renderLinks.containsKey(id)) return;

    final link = _renderLinks[id]!;

    // Remove the link from its associated ports
    final fromPort = _nodes[link.fromTo.item1]?.ports[link.fromTo.item2];
    final toPort = _nodes[link.fromTo.item3]?.ports[link.fromTo.item4];

    fromPort?.links.remove(link);
    toPort?.links.remove(link);

    _renderLinks.remove(id);

    eventBus.emit(
      RemoveLinkEvent(
        id: eventId ?? const Uuid().v4(),
        link,
        isHandled: isHandled,
      ),
    );
  }

  // This is used for rendering purposes only. For computation, use the links list in the Port class.
  final Map<String, Link> _renderLinks = {};
  Tuple2<Offset, Offset>? _renderTempLink;

  List<Link> get renderLinksAsList => _renderLinks.values.toList();
  Tuple2<Offset, Offset>? get renderTempLink => _renderTempLink;

  /// This method is used to draw a temporary link between two points in the node editor.
  ///
  /// Usually, this method is called when the user is dragging a link from a port to another port.
  ///
  /// Emits a [DrawTempLinkEvent] event.
  void drawTempLink(Offset from, Offset to) {
    _renderTempLink = Tuple2(from, to);
    eventBus.emit(DrawTempLinkEvent(id: const Uuid().v4(), from, to));
  }

  /// This method is used to clear the temporary link from the node editor.
  ///
  /// Emits a [DrawTempLinkEvent] event.
  void clearTempLink() {
    _renderTempLink = null;
    eventBus.emit(
      DrawTempLinkEvent(id: const Uuid().v4(), Offset.zero, Offset.zero),
    );
  }

  /// This method is used to break all links associated with a port.
  ///
  /// Emits a [RemoveLinkEvent] event for each link that is removed.
  void breakPortLinks(String nodeId, String portId, {bool isHandled = false}) {
    if (!_nodes.containsKey(nodeId)) return;
    if (!_nodes[nodeId]!.ports.containsKey(portId)) return;

    final port = _nodes[nodeId]!.ports[portId]!;
    final linksToRemove = port.links.map((link) => link.id).toList();

    for (final linkId in linksToRemove) {
      removeLinkById(linkId, isHandled: linkId != linksToRemove.last);
    }
  }

  /// This method is used to set the data of a field in a node.
  ///
  /// Emits a [NodeFieldEvent] event.
  void setFieldData(
    String nodeId,
    String fieldId, {
    dynamic data,
    required FieldEventType eventType,
  }) {
    if (eventType == FieldEventType.change) return;

    final node = _nodes[nodeId]!;
    final field = node.fields[fieldId]!;
    field.data = data;

    eventBus.emit(
      NodeFieldEvent(
        id: const Uuid().v4(),
        nodeId,
        data,
        eventType,
      ),
    );
  }

  /// This method is used to collapse all selected nodes.
  ///
  /// Emits a [NodeRenderModeEvent] event.
  void collapseSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = true;
    }

    eventBus.emit(
      NodeRenderModeEvent(id: const Uuid().v4(), true, _selectedNodeIds),
    );
  }

  /// This method is used to expand the selected nodes.
  ///
  /// Emit a [NodeRenderModeEvent] event.
  void expandSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = false;
    }

    eventBus.emit(
      NodeRenderModeEvent(id: const Uuid().v4(), false, _selectedNodeIds),
    );
  }

  // Selection
  final Set<String> _selectedNodeIds = {};
  Rect _selectionArea = Rect.zero;

  Set<String> get selectedNodeIds => _selectedNodeIds;
  Rect get selectionArea => _selectionArea;

  /// This method is used to drag the selected nodes by a given delta affecting their offsets.
  ///
  /// Emits a [DragSelectionEvent] event.
  void dragSelection(Offset delta, {String? eventId}) {
    if (_selectedNodeIds.isEmpty) return;

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.offset += delta / viewportZoom;
    }

    eventBus.emit(
      DragSelectionEvent(
        id: eventId ?? const Uuid().v4(),
        _selectedNodeIds.toSet(),
        delta / viewportZoom,
      ),
    );
  }

  /// This method is used to set the selection area for selecting nodes.
  ///
  /// See [selectNodesByArea] for more information.
  ///
  /// Emits a [SelectionAreaEvent] event.
  void setSelectionArea(Rect area) {
    _selectionArea = area;
    eventBus.emit(SelectionAreaEvent(id: const Uuid().v4(), area));
  }

  /// This method is used to select nodes by their IDs.
  ///
  /// Emits a [SelectionEvent] event.
  void selectNodesById(
    Set<String> ids, {
    bool holdSelection = false,
    bool isHandled = false,
  }) async {
    if (ids.isEmpty) {
      clearSelection();
      return;
    }

    if (!holdSelection) {
      for (final id in _selectedNodeIds) {
        final node = _nodes[id];
        node?.state.isSelected = false;
      }

      _selectedNodeIds.clear();
    }

    _selectedNodeIds.addAll(ids);

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isSelected = true;
    }

    eventBus.emit(
      SelectionEvent(id: const Uuid().v4(), _selectedNodeIds.toSet()),
    );
  }

  /// This method is used to select nodes that are contained within the selection area.
  ///
  /// This method is used in conjunction with the [setSelectionArea] method to select
  /// nodes that are contained within the selection area. The method queries the spatial
  /// hash grid to find nodes that are within the selection area and then selects them.
  ///
  /// See [selectNodesById] for more information.
  void selectNodesByArea({bool holdSelection = false}) async {
    final containedNodes = _spatialHashGrid.queryNodeIdsInArea(_selectionArea);
    selectNodesById(containedNodes, holdSelection: holdSelection);
    _selectionArea = Rect.zero;
  }

  /// This method is used to deselect all selected nodes.
  void clearSelection({bool isHandled = false}) {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isSelected = false;
    }

    _selectedNodeIds.clear();

    eventBus.emit(
      SelectionEvent(
        id: const Uuid().v4(),
        _selectedNodeIds.toSet(),
        isHandled: isHandled,
      ),
    );
  }

  /// This method is used to focus the viweport on a set of nodes by their IDs.
  ///
  /// The method calculates the encompassing rectangle of the nodes and then
  /// centers the viewport on the center of the rectangle. The method also
  /// calculates the zoom level required to fit all the nodes in the viewport.
  ///
  /// See [calculateEncompassingRect], [selectNodesById], [setViewportOffset], and [setViewportZoom] for more information.
  void focusNodesById(Set<String> ids) {
    final encompassingRect = calculateEncompassingRect(
      ids,
      _nodes,
      margin: 256,
    );

    selectNodesById(ids, holdSelection: false);

    final nodeEditorSize = getSizeFromGlobalKey(kNodeEditorWidgetKey)!;

    setViewportOffset(
      -encompassingRect.center,
      animate: true,
      absolute: true,
    );

    final fitZoom = min(
      nodeEditorSize.width / encompassingRect.width,
      nodeEditorSize.height / encompassingRect.height,
    );

    setViewportZoom(fitZoom, animate: true);
  }

  /// This method is used to find all nodes with the specified name.
  Future<List<String>> searchNodesByName(String name) async {
    final results = <String>[];

    final regex = RegExp(name, caseSensitive: false);

    for (final node in _nodes.values) {
      if (regex.hasMatch(node.prototype.name)) {
        results.add(node.id);
      }
    }

    return results;
  }

  /// Callback function that is called when a node is rendered.
  ///
  /// This function is used to update the spatial hash grid with the new bounds
  /// of the node after it has been rendered. This is necessary to keep the grid
  /// up to date with the latest positions of the nodes.
  ///
  /// See [SpatialHashGrid] and [getNodeBoundsInWorld] for more information.
  void onRenderedCallback(NodeInstance node) {
    _spatialHashGrid.remove(node.id);
    _spatialHashGrid.insert(
      Tuple2(node.id, getNodeBoundsInWorld(node)!),
    );
  }
}
