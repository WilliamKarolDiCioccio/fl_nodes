import 'dart:math';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/constants.dart';
import 'package:fl_nodes/src/core/controller/callback.dart';
import 'package:fl_nodes/src/core/controller/history.dart';
import 'package:fl_nodes/src/core/controller/project.dart';
import 'package:fl_nodes/src/core/models/events.dart';
import 'package:fl_nodes/src/core/utils/dsa/spatial_hash_grid.dart';
import 'package:fl_nodes/src/core/utils/rendering/renderbox.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/config.dart';
import '../models/entities.dart';
import 'clipboard.dart';
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
class FlNodeEditorController with ChangeNotifier {
  FlCallback? onCallback;

  FlNodeEditorController({
    this.config = const FlNodeEditorConfig(),
    this.style = const FlNodeEditorStyle(),
    FlProjectSaver? projectSaver,
    FlProjectLoader? projectLoader,
    FlProjectCreator? projectCreator,
    this.onCallback,
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
  @override
  void dispose() {
    eventBus.close();
    history.clear();
    project.clear();
    runner.dispose();

    clear();

    super.dispose();
  }

  /// This method is used to clear the core controller and all of its subsystems.
  void clear() {
    nodes.clear();
    spatialHashGrid.clear();
    selectedNodeIds.clear();
    selectedLinkIds.clear();
    _linksById.clear();

    linksDataDirty = true;
    nodesDataDirty = true;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Controller subsystems are used to manage the state of the node editor.
  ////////////////////////////////////////////////////////////////////////////////

  /// The event bus is used to communicate between different susbsystems and with the UI.
  final eventBus = NodeEditorEventBus();

  late final FlNodeEditorClipboard clipboard;
  late final FlNodeEditorRunner runner;
  late final FlNodeEditorHistory history;
  late final FlNodeEditorProject project;

  ////////////////////////////////////////////////////////////////////////////////
  /// Viewport properties are used to manage the viewport of the node editor.
  ////////////////////////////////////////////////////////////////////////////////

  final ValueNotifier<Offset> viewportOffsetNotifier =
      ValueNotifier(Offset.zero);
  final ValueNotifier<double> viewportZoomNotifier = ValueNotifier(1.0);

  Offset get viewportOffset => viewportOffsetNotifier.value;
  double get viewportZoom => viewportZoomNotifier.value;

  void updateViewportOffsetFromUI(Offset offset) {
    viewportOffsetNotifier.value = offset;

    eventBus.emit(
      ViewportOffsetEvent(
        id: const Uuid().v4(),
        viewportOffsetNotifier.value,
        animate: false,
        isHandled: true,
      ),
    );
  }

  /// The update...FromUI methods are helpers used to update the viewport properties from the UI
  /// defaulting event parameters to the correct values.

  void updateViewportZoomFromUI(double zoom) {
    viewportZoomNotifier.value = zoom;

    eventBus.emit(
      ViewportZoomEvent(
        id: const Uuid().v4(),
        viewportZoom,
        animate: false,
        isHandled: true,
      ),
    );

    lodLevelNotifier.value = _computeLODLevel(viewportZoom);
  }

  /// This method is used to set the offset of the viewport.
  ///
  /// The 'animate' parameter is used to animate the transition to the new offset.
  /// The 'absolute' parameter is used to choose whether the offset is added to the the current
  /// offset or set as an absolute value. The 'isHandled' parameter is used to indicate whether
  void setViewportOffset(
    Offset offset, {
    bool animate = true,
    bool absolute = false,
    bool isHandled = false,
  }) {
    eventBus.emit(
      ViewportOffsetEvent(
        id: const Uuid().v4(),
        absolute ? offset : viewportOffset + offset,
        animate: animate,
        isHandled: isHandled,
      ),
    );
  }

  /// This method is used to set the zoom level of the viewport.
  ///
  /// The 'animate' parameter is used to animate the zoom transition.
  ///
  /// NOTE: The focal point deafults to the current viewport offset if not provided and uses cursor position from mouse events.
  void setViewportZoom(
    double zoom, {
    bool animate = true,
    bool isHandled = false,
  }) {
    eventBus.emit(
      ViewportZoomEvent(
        id: const Uuid().v4(),
        zoom,
        animate: animate,
        isHandled: isHandled,
      ),
    );

    lodLevelNotifier.value = _computeLODLevel(viewportZoom);
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Rendering accelerators are data stored in the controller to speed up rendering.
  ////////////////////////////////////////////////////////////////////////////////

  late final lodLevelNotifier =
      ValueNotifier<int>(_computeLODLevel(viewportZoom));
  int get lodLevel => lodLevelNotifier.value;

  bool nodesDataDirty = false;
  bool linksDataDirty = false;

  /// This method is used to compute the level of detail (LOD) based on the zoom level and
  /// it's called automatically by the controller when the zoom level is changed.
  static int _computeLODLevel(double zoom) {
    if (zoom > 0.5) {
      return 4;
    } else if (zoom > 0.25) {
      return 3;
    } else if (zoom > 0.125) {
      return 2;
    } else if (zoom > 0.0625) {
      return 1;
    } else {
      return 0;
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Node editor configuration and style.
  //////////////////////////////////////////////////////////////////////////////////

  FlNodeEditorConfig config;

  /// Set the global configuration of the node editor.
  void setConfig(FlNodeEditorConfig config) {
    this.config = config;

    nodesDataDirty = true;
    linksDataDirty = true;

    eventBus.emit(
      ConfigurationChangeEvent(
        config,
        id: const Uuid().v4(),
      ),
    );
  }

  /// Quick access to frequently used configuration properties.

  /// Enable or disable zooming in the node editor.
  void enableSnapToGrid(bool enable) async {
    setConfig(config.copyWith(enableSnapToGrid: enable));

    if (!enable) {
      for (final node in nodes.values) {
        node.offset = _unboundNodeOffsets[node.id]!;
      }
    } else {
      for (final node in nodes.values) {
        if (enable) {
          node.offset = Offset(
            (node.offset.dx / config.snapToGridSize).round() *
                config.snapToGridSize,
            (node.offset.dy / config.snapToGridSize).round() *
                config.snapToGridSize,
          );
        }
      }
    }

    nodesDataDirty = true;
    linksDataDirty = true;
  }

  /// Set the size of the grid to snap to in the node editor.
  void setSnapToGridSize(double size) =>
      setConfig(config.copyWith(snapToGridSize: size));

  /// Enable or disable auto placement of nodes in the node editor.
  void enableAutoPlacement(bool enable) =>
      setConfig(config = config.copyWith(enableAutoPlacement: enable));

  FlNodeEditorStyle style;

  /// Set the style of the node editor.
  void setStyle(FlNodeEditorStyle style) {
    this.style = style;

    nodesDataDirty = true;
    linksDataDirty = true;

    eventBus.emit(
      StyleChangeEvent(
        style,
        id: const Uuid().v4(),
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////////
  /// Localization.
  ////////////////////////////////////////////////////////////////////////

  Locale locale = const Locale('en');

  /// Set the locale of the node editor.
  void setLocale(Locale locale) {
    if (locale == this.locale) return;

    this.locale = locale;

    eventBus.emit(
      LocaleChangeEvent(
        locale,
        id: const Uuid().v4(),
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////////
  /// Nodes and links management.
  ////////////////////////////////////////////////////////////////////////

  final Map<String, NodePrototype> nodePrototypes = {};
  final Map<String, NodeInstance> nodes = {};

  List<NodePrototype> get nodePrototypesAsList =>
      nodePrototypes.values.map((e) => e).toList();
  List<NodeInstance> get nodesAsList => nodes.values.toList();

  final SpatialHashGrid spatialHashGrid = SpatialHashGrid();

  /// This map holds the raw nodes offsets before they are snapped to the grid.
  final Map<String, Offset> _unboundNodeOffsets = {};

  /// This method is used to register a node prototype with the node editor.
  ///
  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void registerNodePrototype(NodePrototype prototype) {
    nodePrototypes.putIfAbsent(
      prototype.idName,
      () => prototype,
    );
  }

  /// This method is used to remove a node prototype by its name.
  ///
  /// NOTE: node prototypes are identified by human-readable strings instead of UUIDs.
  void unregisterNodePrototype(String name) {
    if (!nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    } else {
      nodePrototypes.remove(name);
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
  NodeInstance addNode(String name, {Offset offset = Offset.zero}) {
    if (!nodePrototypes.containsKey(name)) {
      throw Exception('Node prototype $name does not exist.');
    }

    if (config.enableSnapToGrid) {
      offset = Offset(
        (offset.dx / config.snapToGridSize).round() * config.snapToGridSize,
        (offset.dy / config.snapToGridSize).round() * config.snapToGridSize,
      );
    }

    final instance = createNode(
      nodePrototypes[name]!,
      controller: this,
      offset: offset,
    );

    nodes.putIfAbsent(instance.id, () => instance);
    _unboundNodeOffsets.putIfAbsent(instance.id, () => instance.offset);

    nodesDataDirty = true;

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
    if (nodes.containsKey(node.id)) return;

    Offset offset = node.offset;

    if (config.enableSnapToGrid) {
      offset = Offset(
        (offset.dx / config.snapToGridSize).round() * config.snapToGridSize,
        (offset.dy / config.snapToGridSize).round() * config.snapToGridSize,
      );
    }

    nodes.putIfAbsent(node.id, () => node.copyWith(offset: offset));

    _unboundNodeOffsets.putIfAbsent(node.id, () => node.offset);

    if (node.state.isSelected) selectedNodeIds.add(node.id);

    nodesDataDirty = true;

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
  void removeNodeById(
    String id, {
    String? eventId,
    bool isHandled = false,
  }) async {
    if (!nodes.containsKey(id)) return;

    final node = nodes[id]!;

    for (final port in node.ports.values) {
      final linksToRemove = port.links.map((link) => link.id).toList();

      for (final linkId in linksToRemove) {
        removeLinkById(linkId, isHandled: true);
      }
    }

    spatialHashGrid.remove(id);
    nodes.remove(id);

    // selectedNodeIds.remove(id); We don't remove the node from the selected nodes because you might be iterating over them.

    // The links data is set to dirty by the removeLinkById method.
    nodesDataDirty = true;

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
    String port1IdName,
    String node2Id,
    String port2IdName, {
    String? eventId,
  }) {
    // Check for self-links
    if (node1Id == node2Id) return null;

    final node1 = nodes[node1Id]!;
    final port1 = node1.ports[port1IdName]!;
    final node2 = nodes[node2Id]!;
    final port2 = node2.ports[port2IdName]!;

    String getErrorMessage(PortPrototype port1, PortPrototype port2) {
      // display a specific message if they're incompatible because of different types (e.g. control vs data ports)
      if (port1.type != port2.type) {
        return 'Cannot connect a ${port1.type.name} port to a ${port2.type.name} port';
      }

      // display a specific message if they're incompatible because they're both the same direction (e.g. input & input)
      if (port1.direction == port2.direction) {
        return 'Cannot connect two ${port1.direction.name} ports';
      }

      if (port1.dataType != port2.dataType) {
        return "Cannot connect a port of type '${port1.dataType}' to a port of type '${port2.dataType}'";
      }

      // We don't know why they incompatible, so just show a generic error message
      return "These two ports are incompatible";
    }

    if (!port1.prototype.compatibleWith(port2.prototype)) {
      onCallback?.call(
        FlCallbackType.error,
        getErrorMessage(port1.prototype, port2.prototype),
      );
      return null;
    }

    // if this exact link already exists, don't do anything
    if (port1.links.any(
          (link) =>
              link.fromTo.from == node2Id && link.fromTo.to == port2IdName,
        ) ||
        port2.links.any(
          (link) =>
              link.fromTo.from == node1Id && link.fromTo.to == port1IdName,
        )) {
      return null;
    }

    late FromTo fromTo;

    // Determine the order to insert the node references in the link based on the port direction.
    if (port1.prototype.direction == PortDirection.output) {
      fromTo = (
        from: node1Id,
        to: port1IdName,
        fromPort: node2Id,
        toPort: port2IdName
      );
    } else {
      fromTo = (
        from: node2Id,
        to: port2IdName,
        fromPort: node1Id,
        toPort: port1IdName
      );
    }

    final link = Link(
      id: const Uuid().v4(),
      fromTo: fromTo,
      state: LinkState(),
    );

    port1.links.add(link);
    port2.links.add(link);

    linksById.putIfAbsent(
      link.id,
      () => link,
    );

    linksDataDirty = true;

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
    if (!nodes.containsKey(link.fromTo.from) ||
        !nodes.containsKey(link.fromTo.fromPort)) {
      return;
    }

    final fromNode = nodes[link.fromTo.from]!;
    final toNode = nodes[link.fromTo.fromPort]!;

    if (!fromNode.ports.containsKey(link.fromTo.to) ||
        !toNode.ports.containsKey(link.fromTo.toPort)) {
      return;
    }

    final fromPort = nodes[link.fromTo.from]!.ports[link.fromTo.to]!;
    final toPort = nodes[link.fromTo.fromPort]!.ports[link.fromTo.toPort]!;

    fromPort.links.add(link);
    toPort.links.add(link);

    linksById.putIfAbsent(
      link.id,
      () => link,
    );

    if (link.state.isSelected) selectedLinkIds.add(link.id);

    linksDataDirty = true;

    eventBus.emit(
      AddLinkEvent(
        id: eventId ?? const Uuid().v4(),
        link,
        isHandled: isHandled,
      ),
    );
  }

  final Map<String, Link> _linksById = {};
  Map<String, Link> get linksById => _linksById;

  /// This method is used to remove a link by its ID.
  ///
  /// Emits a [RemoveLinkEvent] event.
  void removeLinkById(
    String id, {
    String? eventId,
    bool isHandled = false,
  }) {
    if (!linksById.containsKey(id)) return;

    final link = linksById[id]!;

    // Remove the link from its associated ports
    final fromPort = nodes[link.fromTo.from]?.ports[link.fromTo.to];
    final toPort = nodes[link.fromTo.fromPort]?.ports[link.fromTo.toPort];

    fromPort?.links.remove(link);
    toPort?.links.remove(link);

    linksById.remove(id);

    // selectedLinkIds.remove(id); We don't remove the link from the selected links because you might be iterating over them.

    linksDataDirty = true;

    eventBus.emit(
      RemoveLinkEvent(
        id: eventId ?? const Uuid().v4(),
        link,
        isHandled: isHandled,
      ),
    );
  }

  /// Represents a link in the process of being drawn.
  TempLink? _tempLink;
  TempLink? get tempLink => _tempLink;

  /// This method is used to draw a temporary link between two points in the node editor.
  ///
  /// Usually, this method is called when the user is dragging a link from a port to another port.
  ///
  /// Emits a [DrawTempLinkEvent] event.
  void drawTempLink(FlLinkStyle style, Offset from, Offset to) {
    _tempLink = TempLink(style: style, from: from, to: to);

    // The temp link is treated differently from regular links, so we don't need to mark the links data as dirty.

    eventBus.emit(DrawTempLinkEvent(id: const Uuid().v4(), from, to));
  }

  /// This method is used to clear the temporary link from the node editor.
  ///
  /// Emits a [DrawTempLinkEvent] event.
  void clearTempLink() {
    _tempLink = null;

    // The temp link is treated differently from regular links, so we don't need to mark the links data as dirty.

    eventBus.emit(
      DrawTempLinkEvent(id: const Uuid().v4(), Offset.zero, Offset.zero),
    );
  }

  /// This method is used to break all links associated with a port.
  ///
  /// Emits a [RemoveLinkEvent] event for each link that is removed.
  void breakPortLinks(String nodeId, String portId, {bool isHandled = false}) {
    if (!nodes.containsKey(nodeId)) return;
    if (!nodes[nodeId]!.ports.containsKey(portId)) return;

    final port = nodes[nodeId]!.ports[portId]!;
    final linksToRemove = port.links.map((link) => link.id).toList();

    for (final linkId in linksToRemove) {
      removeLinkById(linkId, isHandled: linkId != linksToRemove.last);
    }

    linksDataDirty = true;
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

    final node = nodes[nodeId]!;
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

  /// This method is used to toggle the collapse state of all selected nodes.
  ///
  /// Emit a [NodeRenderModeEvent] event.
  void toggleCollapseSelectedNodes(bool collapse) {
    for (final id in selectedNodeIds) {
      final node = nodes[id];
      node?.state.isCollapsed = collapse;
    }

    linksDataDirty = true;
    nodesDataDirty = true;

    eventBus.emit(
      CollapseEvent(id: const Uuid().v4(), collapse, selectedNodeIds),
    );
  }

  ////////////////////////////////////////////////////////////////////////////
  /// Selection management.
  ///////////////////////////////////////////////////////////////////////////

  final Set<String> selectedNodeIds = {};
  final Set<String> selectedLinkIds = {};

  Rect? _highlightArea;
  Rect? get highlightArea => _highlightArea;

  /// This method is used to drag the selected nodes by a given delta affecting their offsets.
  ///
  /// Emits a [DragSelectionEvent] event.
  void dragSelection(
    Offset delta, {
    String? eventId,
    bool isWorldDelta = false,
    bool resetUnboundOffset = false,
  }) async {
    if (selectedNodeIds.isEmpty) return;

    // If the delta is not already in world coordinates,
    // convert it by dividing by the viewport zoom.
    final Offset effectiveDelta = isWorldDelta ? delta : delta / viewportZoom;

    for (final id in selectedNodeIds) {
      final node = nodes[id]!;

      // Reset the unbound offset if requested (e.g. during undo/redo)
      if (resetUnboundOffset) {
        _unboundNodeOffsets[id] = node.offset;
      } else {
        _unboundNodeOffsets.putIfAbsent(id, () => node.offset);
      }

      // Update the unbound offset by adding the effective delta.
      _unboundNodeOffsets[id] = _unboundNodeOffsets[id]! + effectiveDelta;

      if (config.enableSnapToGrid) {
        final unboundOffset = _unboundNodeOffsets[id]!;

        // Snap the node's offset to the grid using rounding.
        node.offset = Offset(
          (unboundOffset.dx / config.snapToGridSize).round() *
              config.snapToGridSize,
          (unboundOffset.dy / config.snapToGridSize).round() *
              config.snapToGridSize,
        );
      } else {
        // Apply the effective delta directly to the node's offset.
        node.offset += effectiveDelta;
      }
    }

    linksDataDirty = true;
    nodesDataDirty = true;

    // Emit a DragSelectionEvent with the effective delta (in world coordinates).
    eventBus.emit(
      DragSelectionEvent(
        id: eventId ?? const Uuid().v4(),
        selectedNodeIds.toSet(),
        effectiveDelta,
      ),
    );
  }

  /// This method is used to set the selection area for selecting nodes.
  ///
  /// See [selectNodesByArea] for more information.
  ///
  /// Emits a [highlightAreaEvent] event.
  void setHighlightArea(Rect? area) {
    _highlightArea = area;
    eventBus.emit(AreaHighlightEvent(id: const Uuid().v4(), area));
  }

  /// This method is used to select nodes by their IDs.
  ///
  /// Emits a [NodeSelectionEvent] event.
  void selectNodesById(
    Set<String> ids, {
    bool holdSelection = false,
    bool isHandled = false,
  }) async {
    if (ids.isEmpty) {
      return clearSelection();
    } else if (!holdSelection) {
      clearSelection();
    }

    selectedNodeIds.addAll(ids);

    for (final id in selectedNodeIds) {
      final node = nodes[id];
      node?.state.isSelected = true;
    }

    eventBus.emit(
      NodeSelectionEvent(
        id: const Uuid().v4(),
        selectedNodeIds.toSet(),
        isHandled: isHandled,
      ),
    );
  }

  /// This method is used to select nodes that are contained within the selection area.
  ///
  /// This method is used in conjunction with the [sethighlightArea] method to select
  /// nodes that are contained within the selection area. The method queries the spatial
  /// hash grid to find nodes that are within the selection area and then selects them.
  ///
  /// See [selectNodesById] for more information.
  void selectNodesByArea({bool holdSelection = false}) async {
    if (_highlightArea == null || _highlightArea == Rect.zero) {
      return clearSelection();
    }

    final containedNodes = spatialHashGrid.queryArea(_highlightArea!);

    selectNodesById(
      containedNodes,
      holdSelection: holdSelection,
    );

    _highlightArea = Rect.zero;
  }

  /// This method is used to select a link by its ID.
  ///
  /// Emits a [NodeSelectionEvent] event.
  void selectLinkById(
    String id, {
    bool holdSelection = false,
    bool isHandled = false,
  }) async {
    if (id.isEmpty) {
      return clearSelection();
    } else if (!holdSelection) {
      clearSelection();
    }

    selectedLinkIds.add(id);

    for (final id in selectedLinkIds) {
      final link = linksById[id];
      link?.state.isSelected = true;
    }

    linksDataDirty = true;

    eventBus.emit(
      LinkSelectionEvent(
        id: const Uuid().v4(),
        selectedLinkIds.toSet(),
        isHandled: isHandled,
      ),
    );
  }

  /// This method is used to deselect all selected nodes.
  void clearSelection({bool isHandled = false}) {
    for (final id in selectedNodeIds) {
      final node = nodes[id];
      node?.state.isSelected = false;
    }

    for (final id in selectedLinkIds) {
      final link = linksById[id];
      link?.state.isSelected = false;
    }

    linksDataDirty = true;
    nodesDataDirty = true;

    eventBus.emit(
      NodeDeselectionEvent(
        id: const Uuid().v4(),
        selectedNodeIds.toSet(),
        isHandled: isHandled,
      ),
    );

    eventBus.emit(
      LinkDeselectionEvent(
        id: const Uuid().v4(),
        selectedLinkIds.toSet(),
        isHandled: isHandled,
      ),
    );

    selectedNodeIds.clear();
    selectedLinkIds.clear();
  }

  /////////////////////////////////////////////////////////////////////
  /// Miscellaneous helpers useful for node editors.
  /////////////////////////////////////////////////////////////////////

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
      nodes,
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

  /// This method is used to find all nodes with the specified display name.
  Future<List<String>> searchNodesByName(
    BuildContext context,
    String name,
  ) async {
    final results = <String>[];

    final regex = RegExp(name, caseSensitive: false);

    for (final node in nodes.values) {
      if (regex.hasMatch(node.prototype.displayName(context))) {
        results.add(node.id);
      }
    }

    return results;
  }
}
