import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/utils/constants.dart';
import 'package:fl_nodes/src/core/utils/renderbox.dart';
import 'package:fl_nodes/src/core/utils/snackbar.dart';
import 'package:fl_nodes/src/core/utils/spatial_hash_grid.dart';
import 'package:fl_nodes/src/core/utils/stack.dart';

import '../models/entities.dart';

import 'node_editor_event_bus.dart';
import 'node_editor_events.dart';

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
  final eventBus = NodeEditorEventBus();
  final NodeEditorBehavior behavior;
  final Future<bool> Function(Map<String, dynamic> jsonData)? projectSaver;
  final Future<Map<String, dynamic>?> Function(bool isSaved)? projectLoader;
  final Future<bool> Function(bool isSaved)? projectCreator;

  FlNodeEditorController({
    this.behavior = const NodeEditorBehavior(),
    this.projectSaver,
    this.projectLoader,
    this.projectCreator,
  }) {
    eventBus.events.listen((event) {
      // This ensures a reliable order of execution for event handlers.
      _handleUndoableEvents(event);
      _handleProjectEvents(event);
    });
  }

  void dispose() {
    eventBus.dispose();
    _nodes.clear();
    _spatialHashGrid.clear();
    _selectedNodeIds.clear();
    _renderLinks.clear();
    _undoStack.clear();
    _redoStack.clear();
  }

  // Viewport
  Offset _viewportOffset = Offset.zero;
  double _viewportZoom = 1.0;

  Offset get viewportOffset => _viewportOffset;
  double get viewportZoom => _viewportZoom;

  set viewportOffset(Offset offset) {
    _viewportOffset = offset;
    eventBus.emit(
      ViewportOffsetEvent(
        id: const Uuid().v4(),
        _viewportOffset,
        animate: false,
        isHandled: true,
      ),
    );
  }

  set viewportZoom(double zoom) {
    _viewportZoom = zoom;
    eventBus.emit(
      ViewportZoomEvent(
        id: const Uuid().v4(),
        _viewportZoom,
        isHandled: true,
      ),
    );
  }

  void setViewportOffset(
    Offset coords, {
    bool animate = true,
    bool absolute = false,
    bool isHandled = false,
  }) {
    if (absolute) {
      _viewportOffset = coords;
    } else {
      _viewportOffset += coords;
    }

    eventBus.emit(
      ViewportOffsetEvent(
        id: const Uuid().v4(),
        _viewportOffset,
        animate: animate,
        isHandled: isHandled,
      ),
    );
  }

  void setViewportZoom(
    double amount, {
    bool animate = true,
    isHandled = false,
  }) {
    _viewportZoom = amount;
    eventBus.emit(
      ViewportZoomEvent(
        id: const Uuid().v4(),
        _viewportZoom,
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
      if (_selectedNodeIds.contains(a.id) && !_selectedNodeIds.contains(b.id)) {
        return 1;
      } else if (!_selectedNodeIds.contains(a.id) &&
          _selectedNodeIds.contains(b.id)) {
        return -1;
      } else {
        return 0;
      }
    });

    return nodesList;
  }

  Map<String, NodeInstance> get nodes => _nodes;
  SpatialHashGrid get spatialHashGrid => _spatialHashGrid;

  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void registerNodePrototype(NodePrototype name) {
    _nodePrototypes.putIfAbsent(
      name.name,
      () => name,
    );
  }

  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void unregisterNodePrototype(String name) {
    if (!_nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    } else {
      _nodePrototypes.remove(name);
    }
  }

  NodeInstance addNode(String name, {Offset? offset}) {
    if (!_nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    }

    final instance = createNode(
      _nodePrototypes[name]!,
      offset: offset,
      // Layout is needed to insert the node into the spatial hash grid.
      onRendered: _onRenderedCallback,
    );

    _nodes.putIfAbsent(
      instance.id,
      () => instance,
    );

    eventBus.emit(
      AddNodeEvent(
        id: const Uuid().v4(),
        instance.id,
        instance,
      ),
    );

    return instance;
  }

  void addNodesFromExisting(
    Set<NodeInstance> nodes, {
    bool isHandled = false,
    String? eventId,
  }) {
    for (final node in nodes) {
      _nodes.putIfAbsent(
        node.id,
        () => node,
      );

      for (final port in node.ports.values) {
        for (final link in port.links) {
          _renderLinks.putIfAbsent(
            link.id,
            () => link,
          );
        }
      }

      eventBus.emit(
        AddNodeEvent(
          id: eventId ?? const Uuid().v4(),
          node.id,
          node,
          isHandled: isHandled,
        ),
      );
    }
  }

  void removeNodes(
    Set<String> ids, {
    String? eventId,
    bool isHandled = false,
  }) async {
    if (ids.isEmpty) return;

    final Set<String> linksToRemove = {};

    for (final id in ids) {
      for (final port in _nodes[id]!.ports.values) {
        linksToRemove.addAll(port.links.map((link) => link.id));
      }
    }

    for (final linkId in linksToRemove) {
      removeLinkById(linkId, isHandled: true);
    }

    for (final id in ids) {
      if (_nodes.containsKey(id)) {
        _spatialHashGrid.remove(id);
        _nodes.remove(id);
      }
    }

    eventBus.emit(
      RemoveNodesEvent(
        id: eventId ?? const Uuid().v4(),
        ids,
        isHandled: isHandled,
      ),
    );
  }

  Link? addLink(
    String fromNodeId,
    String fromPortId,
    String toNodeId,
    String toPortId, {
    String? eventId,
  }) {
    if (fromPortId == toPortId) return null;

    final fromPort = _nodes[fromNodeId]!.ports[fromPortId]!;
    final toPort = _nodes[toNodeId]!.ports[toPortId]!;

    if (fromPort.isInput == toPort.isInput) return null;
    if (fromPort.links.length > 1 && !fromPort.allowMultipleLinks) return null;
    if (toPort.links.length > 1 && !toPort.allowMultipleLinks) return null;

    for (final link in toPort.links) {
      if (link.fromTo.item1 == fromNodeId && link.fromTo.item2 == fromPortId) {
        return null;
      }
    }

    final link = Link(
      id: const Uuid().v4(),
      fromTo: Tuple4(fromNodeId, fromPortId, toNodeId, toPortId),
    );

    fromPort.links.add(link);
    toPort.links.add(link);

    _renderLinks.putIfAbsent(
      link.id,
      () => link,
    );

    eventBus.emit(
      AddLinkEvent(
        id: eventId ?? const Uuid().v4(),
        link.id,
        link,
      ),
    );

    return link;
  }

  void addLinksFromExisting(Set<Link> links, {String? eventId}) {
    for (final link in links) {
      final fromPort = _nodes[link.fromTo.item1]!.ports[link.fromTo.item2]!;
      final toPort = _nodes[link.fromTo.item3]!.ports[link.fromTo.item4]!;

      fromPort.links.add(link);
      toPort.links.add(link);

      _renderLinks.putIfAbsent(
        link.id,
        () => link,
      );
    }

    eventBus.emit(
      AddLinkEvent(
        id: eventId ?? const Uuid().v4(),
        links.first.id,
        links.first,
      ),
    );
  }

  void removeLinkById(
    String linkId, {
    String? eventId,
    bool isHandled = false,
  }) {
    final link = _renderLinks[linkId]!;

    // Remove the link from its associated ports
    final fromPort = _nodes[link.fromTo.item1]?.ports[link.fromTo.item2];
    final toPort = _nodes[link.fromTo.item3]?.ports[link.fromTo.item4];

    fromPort?.links.remove(link);
    toPort?.links.remove(link);

    _renderLinks.remove(linkId);

    eventBus.emit(
      RemoveLinksEvent(
        id: eventId ?? const Uuid().v4(),
        linkId,
        isHandled: isHandled,
      ),
    );
  }

  // This is used for rendering purposes only. For computation, use the links list in the Port class.
  final Map<String, Link> _renderLinks = {};
  Tuple2<Offset, Offset>? _renderTempLink;

  List<Link> get renderLinksAsList => _renderLinks.values.toList();
  Tuple2<Offset, Offset>? get renderTempLink => _renderTempLink;

  void drawTempLink(Offset from, Offset to) {
    _renderTempLink = Tuple2(from, to);
    eventBus.emit(DrawTempLinkEvent(id: const Uuid().v4(), from, to));
  }

  void clearTempLink() {
    _renderTempLink = null;
    eventBus.emit(
      DrawTempLinkEvent(id: const Uuid().v4(), Offset.zero, Offset.zero),
    );
  }

  void breakPortLinks(String nodeId, String portId, {bool isHandled = false}) {
    final node = _nodes[nodeId]!;
    final port = node.ports[portId]!;

    // Collect all link IDs associated with the port
    final linkIds = port.links.map((link) => link.id).toList();

    for (final linkId in linkIds) {
      removeLinkById(linkId, isHandled: true);
    }

    eventBus.emit(
      RemoveLinksEvent(
        id: const Uuid().v4(),
        portId,
        isHandled: isHandled,
      ),
    );
  }

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

  void setNodeOffset(String id, Offset offset) {
    final node = _nodes[id];
    node?.offset = offset;
  }

  void collapseSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = true;
    }

    eventBus.emit(CollapseNodeEvent(id: const Uuid().v4(), _selectedNodeIds));
  }

  void expandSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = false;
    }

    eventBus.emit(CollapseNodeEvent(id: const Uuid().v4(), _selectedNodeIds));
  }

  // Selection
  final Set<String> _selectedNodeIds = {};
  Rect _selectionArea = Rect.zero;

  Set<String> get selectedNodeIds => _selectedNodeIds;
  Rect get selectionArea => _selectionArea;

  void dragSelection(Offset delta, {String? eventId}) {
    if (_selectedNodeIds.isEmpty) return;

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.offset += delta / _viewportZoom;
    }

    eventBus.emit(
      DragSelectionEvent(
        id: eventId ?? const Uuid().v4(),
        _selectedNodeIds.toSet(),
        delta / _viewportZoom,
      ),
    );
  }

  void setSelectionArea(Rect area) {
    _selectionArea = area;
    eventBus.emit(SelectionAreaEvent(id: const Uuid().v4(), area));
  }

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

  void selectNodesByArea({bool holdSelection = false}) async {
    final containedNodes = _spatialHashGrid.queryNodeIdsInArea(_selectionArea);
    selectNodesById(containedNodes, holdSelection: holdSelection);
    _selectionArea = Rect.zero;
  }

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

  void focusNodesById(Set<String> ids) {
    final encompassingRect = _calculateEncompassingRect(ids, _nodes);

    selectNodesById(ids, holdSelection: false);

    final nodeEditorSize = getSizeFromGlobalKey(kNodeEditorWidgetKey)!;
    final paddedEncompassingRect = encompassingRect.inflate(50.0);
    final fitZoom = min(
      nodeEditorSize.width / paddedEncompassingRect.width,
      nodeEditorSize.height / paddedEncompassingRect.height,
    );

    setViewportZoom(fitZoom, animate: true);
    setViewportOffset(
      -encompassingRect.center,
      animate: true,
      absolute: true,
    );
  }

  Future<List<String>> searchNodesByName(String name) async {
    final results = <String>[];

    final regex = RegExp(name, caseSensitive: false);

    for (final node in _nodes.values) {
      if (regex.hasMatch(node.name)) {
        results.add(node.id);
      }
    }

    return results;
  }

  // Clipboard
  Future<String> copySelection() async {
    if (_selectedNodeIds.isEmpty) return '';

    final encompassingRect =
        _calculateEncompassingRect(_selectedNodeIds, _nodes);

    final selectedNodes = _selectedNodeIds.map((id) {
      final nodeCopy = _nodes[id]!.copyWith();

      final relativeOffset = nodeCopy.offset - encompassingRect.topLeft;

      // We make deep copies as we only want to copy the links that are within the selection.
      final updatedPorts = nodeCopy.ports.map((portId, port) {
        final deepCopiedLinks = port.links.where((link) {
          return _selectedNodeIds.contains(link.fromTo.item1) &&
              _selectedNodeIds.contains(link.fromTo.item3);
        }).toList();

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
        -_viewportOffset.dx - viewportSize.width / 2,
        -_viewportOffset.dy - viewportSize.height / 2,
        viewportSize.width,
        viewportSize.height,
      ).center;
    }

    // Create instances from the JSON data.
    final instances = nodesJson.map((node) {
      return NodeInstance.fromJson(
        node,
        prototypes: _nodePrototypes,
        onRendered: _onRenderedCallback,
      );
    }).toList();

    // Called on each paste, see [FlNodeEditorController._mapToNewIds] for more info.
    final newIds = await _mapToNewIds(instances);

    final deepCopiedInstances = instances.map((instance) {
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
              }).toList(),
            ),
          );
        }),
      );
    }).toSet();

    addNodesFromExisting(deepCopiedInstances, isHandled: true);

    eventBus.emit(
      PasteSelectionEvent(
        id: const Uuid().v4(),
        newIds.values.toSet(),
        position,
        clipboardData.text!,
      ),
    );
  }

  void cutSelection() async {
    final clipboardContent = await copySelection();
    removeNodes(_selectedNodeIds, isHandled: true);
    clearSelection(isHandled: true);

    eventBus.emit(
      CutSelectionEvent(
        id: const Uuid().v4(),
        _selectedNodeIds,
        clipboardContent,
      ),
    );
  }

  // History
  bool _isTraversingHistory = false;
  final _undoStack = Stack<NodeEditorEvent>(kMaxEventUndoHistory);
  final _redoStack = Stack<NodeEditorEvent>(kMaxEventRedoHistory);

  void _handleUndoableEvents(NodeEditorEvent event) {
    if (!event.isUndoable || _isTraversingHistory) return;

    final previousEvent = _undoStack.peek();
    final nextEvent = _redoStack.peek();

    if (event.id != previousEvent?.id && event.id != nextEvent?.id) {
      _redoStack.clear();
    } else {
      return;
    }

    if (event is DragSelectionEvent && previousEvent is DragSelectionEvent) {
      if (event.nodeIds.length == previousEvent.nodeIds.length &&
          event.nodeIds.every(previousEvent.nodeIds.contains)) {
        _undoStack.pop();
        _undoStack.push(
          DragSelectionEvent(
            id: event.id,
            event.nodeIds,
            event.delta + previousEvent.delta,
          ),
        );
        return;
      }
    }

    _undoStack.push(event);
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    _isTraversingHistory = true;
    final event = _undoStack.pop()!;
    _redoStack.push(event);

    try {
      if (event is DragSelectionEvent) {
        selectNodesById(event.nodeIds, isHandled: true);
        dragSelection(-event.delta, eventId: event.id);
        clearSelection();
      } else if (event is AddNodeEvent) {
        removeNodes({event.nodeId}, eventId: event.id);
      } else if (event is RemoveNodesEvent) {
        addNodesFromExisting(event.removedNodes, eventId: event.id);
      } else if (event is AddLinkEvent) {
        removeLinkById(event.linkId, eventId: event.id);
      } else if (event is RemoveLinksEvent) {
        addLinksFromExisting(event.removedLinks, eventId: event.id);
      } else if (event is CutSelectionEvent) {
        pasteSelection();
      }
    } finally {
      _isTraversingHistory = false;
    }
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    _isTraversingHistory = true;
    final event = _redoStack.pop()!;
    _undoStack.push(event);

    try {
      if (event is DragSelectionEvent) {
        selectNodesById(event.nodeIds, isHandled: true);
        dragSelection(event.delta, eventId: event.id);
        clearSelection();
      } else if (event is AddNodeEvent) {
        addNodesFromExisting({event.node}, eventId: event.id);
      } else if (event is RemoveNodesEvent) {
        removeNodes(event.nodeIds, eventId: event.id);
      } else if (event is AddLinkEvent) {
        addLinksFromExisting({event.link}, eventId: event.id);
      } else if (event is RemoveLinksEvent) {
        for (final link in event.removedLinks) {
          removeLinkById(
            link.id,
            eventId: event.id,
          );
        }
      }
    } finally {
      _isTraversingHistory = false;
    }
  }

  // Serialization and deserialization
  bool _isSaved = true;
  bool get isSaved => _isSaved;

  void _handleProjectEvents(NodeEditorEvent event) {
    if (event.isUndoable) _isSaved = false;

    if (event is SaveProjectEvent) {
      _isSaved = true;
    } else if (event is LoadProjectEvent) {
      _isSaved = true;
      _undoStack.clear();
      _redoStack.clear();
    } else if (event is NewProjectEvent) {
      _nodes.clear();
      _spatialHashGrid.clear();
      _selectedNodeIds.clear();
      _renderLinks.clear();
      _isSaved = true;
      _undoStack.clear();
      _redoStack.clear();
    }
  }

  Map<String, dynamic> _toJson() {
    final nodesJson = _nodes.values.map((node) => node.toJson()).toList();

    return {
      'viewport': {
        'offset': [_viewportOffset.dx, _viewportOffset.dy],
        'zoom': _viewportZoom,
      },
      'nodes': nodesJson,
    };
  }

  void _fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return;

    final viewportJson = json['viewport'] as Map<String, dynamic>;

    _viewportOffset = Offset(
      viewportJson['offset'][0] as double,
      viewportJson['offset'][1] as double,
    );

    setViewportOffset(_viewportOffset, absolute: true);

    _viewportZoom = viewportJson['zoom'] as double;

    setViewportZoom(_viewportZoom);

    final nodesJson = json['nodes'] as List<dynamic>;

    final instances = nodesJson.map((node) {
      return NodeInstance.fromJson(
        node,
        prototypes: _nodePrototypes,
        onRendered: _onRenderedCallback,
      );
    }).toSet();

    addNodesFromExisting(instances, isHandled: true);
  }

  void saveProject() async {
    final jsonData = _toJson();
    if (jsonData.isEmpty) return;

    final hasSaved = await projectSaver?.call(jsonData);
    if (hasSaved == false) return;

    _isSaved = true;

    eventBus.emit(SaveProjectEvent(id: const Uuid().v4()));

    showNodeEditorSnackbar(
      'Project saved successfully.',
      SnackbarType.success,
    );
  }

  void loadProject() async {
    final jsonData = await projectLoader?.call(isSaved);

    if (jsonData == null) {
      showNodeEditorSnackbar(
        'Failed to load project. Invalid project data.',
        SnackbarType.error,
      );
      return;
    }

    _nodes.clear();
    _spatialHashGrid.clear();
    _selectedNodeIds.clear();
    _renderLinks.clear();

    _fromJson(jsonData);

    eventBus.emit(LoadProjectEvent(id: const Uuid().v4()));

    showNodeEditorSnackbar(
      'Project loaded successfully.',
      SnackbarType.success,
    );
  }

  void newProject() async {
    final shouldProceed = await projectCreator?.call(isSaved);

    if (shouldProceed == false) return;

    eventBus.emit(NewProjectEvent(id: const Uuid().v4()));

    showNodeEditorSnackbar(
      'New project created successfully.',
      SnackbarType.success,
    );
  }

  // Utils

  /// Callback function that is called when a node is rendered.
  ///
  /// This function is used to update the spatial hash grid with the new bounds
  /// of the node after it has been rendered. This is necessary to keep the grid
  /// up to date with the latest positions of the nodes.
  void _onRenderedCallback(NodeInstance node) {
    _spatialHashGrid.remove(node.id);
    _spatialHashGrid.insert(
      Tuple2(node.id, getNodeBoundsInWorld(node)!),
    );
  }

  /// Maps the IDs of the nodes, ports, and links to new UUIDs.
  ///
  /// This function is used when pasting nodes to generate new IDs for the
  /// pasted nodes, ports, and links. This is done to avoid conflicts with
  /// existing nodes and to allow for multiple pastes of the same selection.
  Future<Map<String, String>> _mapToNewIds(List<NodeInstance> nodes) async {
    final Map<String, String> newIds = {};

    for (final node in nodes) {
      newIds[node.id] = const Uuid().v4();
      for (final port in node.ports.values) {
        newIds[port.id] = const Uuid().v4();
        for (final link in port.links) {
          newIds[link.id] = const Uuid().v4();
        }
      }

      for (var field in node.fields.values) {
        newIds[field.id] = const Uuid().v4();
      }
    }

    return newIds;
  }

  Rect _calculateEncompassingRect(
    Set<String> ids,
    Map<String, NodeInstance> nodes,
  ) {
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

    return encompassingRect;
  }
}
