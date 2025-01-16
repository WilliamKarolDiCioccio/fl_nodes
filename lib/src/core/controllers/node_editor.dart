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

import 'node_editor_events.dart';

/// A class that acts as an event bus for the Node Editor.
///
/// This class is responsible for handling and dispatching events
/// related to the node editor. It allows different parts of the
/// application to communicate with each other by sending and
/// receiving events.
///
/// Events can object instances should extend the [NodeEditorEvent] class.
class _NodeEditorEventBus {
  final _streamController = StreamController<NodeEditorEvent>.broadcast();
  final _undoStack = LIFOStack<NodeEditorEvent>();
  final _redoStack = FIFOStack<NodeEditorEvent>();
  bool _isSaved = true;

  void emit(NodeEditorEvent event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
    _undoStack.clear();
    _redoStack.clear();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  Stream<NodeEditorEvent> get events => _streamController.stream;
  bool get isSaved => _isSaved;
}

/// A class that defines the behavior of a node editor.
///
/// This class is responsible for handling the interactions and
/// behaviors associated with a node editor, such as node selection,
/// movement, and other editor-specific functionalities.
class NodeEditorBehavior {
  final double zoomSensitivity;
  final double minZoom;
  final double maxZoom;
  final double panSensitivity;
  final double maxPanX;
  final double maxPanY;
  final bool enableKineticScrolling;

  const NodeEditorBehavior({
    this.zoomSensitivity = 0.1,
    this.minZoom = 0.1,
    this.maxZoom = 10.0,
    this.panSensitivity = 1.0,
    this.maxPanX = 100000.0,
    this.maxPanY = 100000.0,
    this.enableKineticScrolling = true,
  });
}

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
  final eventBus = _NodeEditorEventBus();
  final NodeEditorBehavior behavior;
  final Function(Map<String, dynamic> jsonData)? projectSaver;
  final Future<Map<String, dynamic>?> Function(bool isSaved)? projectLoader;
  final Future<bool> Function(bool isSaved)? projectCreator;

  FlNodeEditorController({
    this.behavior = const NodeEditorBehavior(),
    this.projectSaver,
    this.projectLoader,
    this.projectCreator,
  });

  void dispose() {
    eventBus.dispose();
  }

  // Viewport
  Offset viewportOffset = Offset.zero;
  double viewportZoom = 1.0;

  void setViewportOffset(
    Offset coords, {
    bool animate = true,
    bool absolute = false,
  }) {
    if (absolute) {
      viewportOffset = coords;
    } else {
      viewportOffset += coords;
    }

    eventBus.emit(ViewportOffsetEvent(viewportOffset, animate: animate));
  }

  void setViewportZoom(double amount, {bool animate = true}) {
    viewportZoom = amount;
    eventBus.emit(ViewportZoomEvent(viewportZoom));
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

    eventBus.emit(AddNodeEvent(instance.id));

    return instance;
  }

  NodeInstance addNodeFromInstance(
    NodeInstance instance, {
    bool isHandled = false,
  }) {
    _nodes.putIfAbsent(
      instance.id,
      () => instance,
    );

    for (final port in instance.ports.values) {
      for (final link in port.links) {
        _renderLinks.putIfAbsent(
          link.id,
          () => link,
        );
      }
    }

    eventBus.emit(AddNodeEvent(instance.id, isHandled: isHandled));

    return instance;
  }

  void removeNodes(Set<String> ids, {bool isHandled = false}) async {
    if (ids.isEmpty) return;

    // Collect all links associated with the nodes to be removed
    final Set<String> linksToRemove = {};

    for (final id in ids) {
      for (final port in _nodes[id]!.ports.values) {
        linksToRemove.addAll(port.links.map((link) => link.id));
      }
    }

    // Remove the links associated with the nodes
    for (final linkId in linksToRemove) {
      removeLinkById(linkId, isHandled: true);
    }

    // Remove the nodes themselves
    for (final id in ids) {
      if (_nodes.containsKey(id)) {
        _spatialHashGrid.remove(id);
        _nodes.remove(id);
      }
    }

    // Emit the event after the cleanup is complete
    eventBus.emit(RemoveNodesEvent(ids, isHandled: isHandled));
  }

  Link? addLink(
    String fromNodeId,
    String fromPortId,
    String toNodeId,
    String toPortId,
  ) {
    final fromPort = _nodes[fromNodeId]!.ports[fromPortId]!;
    final toPort = _nodes[toNodeId]!.ports[toPortId]!;

    if (fromPort.isInput == toPort.isInput) return null;

    if (fromPort.links.isNotEmpty && !fromPort.allowMultipleLinks) return null;
    if (toPort.links.isNotEmpty && !toPort.allowMultipleLinks) return null;

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

    eventBus.emit(AddLinkEvent(link.id));

    return link;
  }

  void removeLinkById(String linkId, {bool isHandled = false}) {
    final link = _renderLinks[linkId]!;

    // Remove the link from its associated ports
    final fromPort = _nodes[link.fromTo.item1]?.ports[link.fromTo.item2];
    final toPort = _nodes[link.fromTo.item3]?.ports[link.fromTo.item4];

    fromPort?.links.remove(link);
    toPort?.links.remove(link);

    _renderLinks.remove(linkId);

    eventBus.emit(RemoveLinksEvent(linkId, isHandled: isHandled));
  }

  // This is used for rendering purposes only. For computation, use the links list in the Port class.
  final Map<String, Link> _renderLinks = {};
  Tuple2<Offset, Offset>? _renderTempLink;

  List<Link> get renderLinksAsList => _renderLinks.values.toList();
  Tuple2<Offset, Offset>? get renderTempLink => _renderTempLink;

  void drawTempLink(Offset from, Offset to) {
    _renderTempLink = Tuple2(from, to);
    eventBus.emit(DrawTempLinkEvent(from, to));
  }

  void clearTempLink() {
    _renderTempLink = null;
    eventBus.emit(DrawTempLinkEvent(Offset.zero, Offset.zero));
  }

  void breakPortLinks(String nodeId, String portId, {bool isHandled = false}) {
    final node = _nodes[nodeId]!;
    final port = node.ports[portId]!;

    // Collect all link IDs associated with the port
    final linkIds = port.links.map((link) => link.id).toList();

    for (final linkId in linkIds) {
      removeLinkById(linkId, isHandled: true);
    }

    eventBus.emit(RemoveLinksEvent('$nodeId-$portId', isHandled: isHandled));
  }

  void setFieldData(String nodeId, String fieldId, dynamic data) {
    final node = _nodes[nodeId]!;
    final field = node.fields[fieldId]!;
    field.data = data;

    eventBus.emit(NodeFieldEditEvent(nodeId, fieldId, data));
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

    eventBus.emit(CollapseNodeEvent(_selectedNodeIds));
  }

  void expandSelectedNodes() {
    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      node?.state.isCollapsed = false;
    }

    eventBus.emit(CollapseNodeEvent(_selectedNodeIds));
  }

  // Selection
  final Set<String> _selectedNodeIds = {};
  Rect _selectionArea = Rect.zero;

  Set<String> get selectedNodeIds => _selectedNodeIds;
  Rect get selectionArea => _selectionArea;

  void dragSelection(Offset delta) {
    eventBus.emit(DragSelectionEvent(_selectedNodeIds.toSet(), delta));
  }

  void setSelectionArea(Rect area) {
    _selectionArea = area;
    eventBus.emit(SelectionAreaEvent(area));
  }

  void selectNodesById(Set<String> ids, {bool holdSelection = false}) async {
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

    eventBus.emit(SelectionEvent(_selectedNodeIds.toSet()));
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
      SelectionEvent(_selectedNodeIds.toSet(), isHandled: isHandled),
    );
  }

  void _clearAll() {
    _nodes.clear();
    _spatialHashGrid.clear();
    _selectedNodeIds.clear();
    _renderLinks.clear();
    viewportOffset = Offset.zero;
    viewportZoom = 1.0;
    _selectionArea = Rect.zero;
  }

  void focusNodesById(Set<String> ids) {
    final encompassingRect =
        _calculateEncompassingRect(_selectedNodeIds, _nodes);

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

    for (final node in _nodes.values) {
      if (node.name.contains(name)) {
        results.add(node.id);
      }
    }

    return results;
  }

  // Clipboard
  Future copySelection() async {
    if (_selectedNodeIds.isEmpty) return;

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
        -viewportOffset.dx - viewportSize.width / 2,
        -viewportOffset.dy - viewportSize.height / 2,
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

    for (final instance in instances) {
      addNodeFromInstance(
        isHandled: true,
        instance.copyWith(
          id: newIds[instance.id],
          offset: instance.offset + position,
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
        ),
      );
    }

    eventBus.emit(PasteSelectionEvent(newIds.values.toSet(), position));
  }

  void cutSelection() async {
    await copySelection();
    removeNodes(_selectedNodeIds, isHandled: true);
    clearSelection(isHandled: true);

    eventBus.emit(CutSelectionEvent(_selectedNodeIds));
  }

  // Serialization and deserialization

  Map<String, dynamic> _toJson() {
    final nodesJson = _nodes.values.map((node) => node.toJson()).toList();

    return {
      'viewport': {
        'offset': [viewportOffset.dx, viewportOffset.dy],
        'zoom': viewportZoom,
      },
      'nodes': nodesJson,
    };
  }

  void _fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return;

    final viewportJson = json['viewport'] as Map<String, dynamic>;

    viewportOffset = Offset(
      viewportJson['offset'][0] as double,
      viewportJson['offset'][1] as double,
    );
    viewportZoom = viewportJson['zoom'] as double;

    setViewportOffset(viewportOffset, absolute: true, animate: false);
    setViewportZoom(viewportZoom, animate: false);

    final nodesJson = json['nodes'] as List<dynamic>;

    for (final nodeJson in nodesJson) {
      final node = NodeInstance.fromJson(
        nodeJson,
        prototypes: _nodePrototypes,
        onRendered: _onRenderedCallback,
      );

      addNodeFromInstance(node, isHandled: true);
    }
  }

  void saveProject() {
    final jsonData = _toJson();
    projectSaver?.call(jsonData);
    eventBus.emit(SaveProjectEvent());
    eventBus._isSaved = true;

    showNodeEditorSnackbar(
      'Project saved successfully.',
      SnackbarType.success,
    );
  }

  void loadProject() async {
    final jsonData = await projectLoader?.call(eventBus._isSaved);

    if (jsonData == null) {
      showNodeEditorSnackbar(
        'Failed to load project. Invalid project data.',
        SnackbarType.error,
      );
      return;
    }

    _clearAll();
    _fromJson(jsonData);
    eventBus.emit(LoadProjectEvent());

    showNodeEditorSnackbar(
      'Project loaded successfully.',
      SnackbarType.success,
    );
  }

  void newProject() async {
    final shouldProceed = await projectCreator?.call(eventBus._isSaved);

    if (shouldProceed == true) {
      _clearAll();
      eventBus.emit(NewProjectEvent());
    }

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
