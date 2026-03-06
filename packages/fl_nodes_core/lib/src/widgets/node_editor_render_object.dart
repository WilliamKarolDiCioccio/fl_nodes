import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:fl_nodes_core/src/constants.dart';
import 'package:fl_nodes_core/src/core/controller/core.dart';
import 'package:fl_nodes_core/src/core/events/events.dart';
import 'package:fl_nodes_core/src/core/models/data.dart';
import 'package:fl_nodes_core/src/core/models/paint.dart';
import 'package:fl_nodes_core/src/core/utils/rendering/paths.dart';
import 'package:fl_nodes_core/src/painters/links.dart';
import 'package:fl_nodes_core/src/painters/selection_area.dart';
import 'package:fl_nodes_core/src/painters/tmp_link.dart';
import 'package:fl_nodes_core/src/styles/styles.dart';
import 'package:fl_nodes_core/src/widgets/builders.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart' as vec;
import 'package:vector_math/vector_math_64.dart' hide Colors;

class _NodeDiffCheckData {
  String id;
  Offset offset;
  FlNodeState state;

  _NodeDiffCheckData({
    required this.id,
    required this.offset,
    required this.state,
  });
}

/// This extends the [ContainerBoxParentData] class from the Flutter framework
/// for the data to be passed down to children for layout and painting.
class _ParentData extends ContainerBoxParentData<RenderBox> {
  String id = '';
  Offset nodeOffset = Offset.zero;
  FlNodeState state = FlNodeState();

  // This is used to store the border radius of the node for more accurate hit testing and rendering
  double borderRadius = 8.0;

  // // // This is used to prevent unnecessary layout and painting of children
  // // bool hasBeenLaidOut = false;

  // This is used to avoid unnecessary recomputations of the renderbox rect
  Rect rect = Rect.zero;
}

class NodeEditorRenderObjectWidget extends MultiChildRenderObjectWidget {
  final FlNodesController controller;
  final FragmentShader gridShader;
  final NodeBuilder nodeBuilder;
  final void Function(String linkId, Offset position)? showLinkContextMenu;

  NodeEditorRenderObjectWidget({
    super.key,
    required this.controller,
    required this.gridShader,
    required this.nodeBuilder,
    this.showLinkContextMenu,
  }) : super(
          children: controller.nodesAsList
              .map(
                (node) => nodeBuilder(node, controller),
              )
              .toList(),
        );

  @override
  NodeEditorRenderBox createRenderObject(BuildContext context) => NodeEditorRenderBox(
        controller: controller,
        gridShader: gridShader,
        isModalPresent: ModalRoute.of(context)?.isCurrent ?? false,
        showLinkContextMenu: showLinkContextMenu,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    NodeEditorRenderBox renderObject,
  ) {
    renderObject
      ..gridShader = gridShader
      ..isModalPresent = ModalRoute.of(context)?.isCurrent == false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // dart format off
    properties
      ..add(DiagnosticsProperty<FlNodesController>('controller', controller))
      ..add(DiagnosticsProperty<ui.FragmentShader>('gridShader', gridShader))
      ..add(ObjectFlagProperty<NodeBuilder>.has('nodeBuilder', nodeBuilder))
      ..add(ObjectFlagProperty<void Function(String linkId, ui.Offset position)?>.has(
          'showLinkContextMenu', showLinkContextMenu));
    // dart format on
  }
}

class NodeEditorRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  NodeEditorRenderBox({
    required FlNodesController controller,
    required FragmentShader gridShader,
    required bool isModalPresent,
    required void Function(String portId, Offset position)? showLinkContextMenu,
  })  : _controller = controller,
        _gridShader = gridShader,
        _isModalPresent = isModalPresent,
        _showLinkContextMenu = showLinkContextMenu,
        _selectionAreaPainter = SelectionAreaCustomPainter(controller),
        _tmpLinkCustomPainter = TmpLinkCustomPainter(controller),
        _linksCustomPainter = LinksCustomPainter(controller) {
    _loadGridShader();

    _updateNodes();

    _offset = _controller.viewportOffset;
    _zoom = _controller.viewportZoom;

    _eventSubscription = _controller.eventBus.events.listen(_handleControllerEvent);
  }

  late final StreamSubscription<NodeEditorEvent> _eventSubscription;

  void _handleControllerEvent(NodeEditorEvent event) {
    if (event is! FlPaintEventCat && event is! FlLayoutEventCat) return;

    // In the following code we must account for the possibility of events affecting nodes outside the viewport

    // Node widgets state related events trigger style updates. Arbitrary styles might require layout updates.
    // Therefore all node widgets must be marked for layout updates when receiving these events.

    // Handle special cases and data updates first
    if (event is FlViewportOffsetEvent) {
      _offset = event.offset;
      _transformChanged = true;
    } else if (event is FlViewportZoomEvent) {
      _zoom = event.zoom;
      _transformChanged = true;
    } else if (event is FlAreaHighlightEvent) {
      _selectionAreaPainter.highlightArea = event.area;
    } else if (event is FlDrawTempLinkEvent) {
      _tmpLinkCustomPainter.tmpLinkData = _getTmpLinkData();
    } else if (event is FlTreeEventCat ||
        event is FlDragSelectionEvent ||
        event is FlConfigurationChangeEvent) {
      return _updateNodes(); // This handles marking for layout/paint as needed on its own
    } else if (event is FlNodeSelectionEvent) {
      _childrenNotLaidOut.addAll(event.nodeIds);
      markNeedsLayout();
    } else if (event is FlNodeHoverEvent) {
      _childrenNotLaidOut.add(event.nodeId);
      markNeedsLayout();
    } else if (event is FlCollapseNodeEvent) {
      _childrenNotLaidOut.addAll(event.nodeIds);
      markNeedsLayout();
    } else if (event is FlNodeFieldEvent) {
      _childrenNotLaidOut.add(event.nodeId);
      markNeedsLayout();
    } else if (event is FlLocaleChangeEvent || event is FlStyleChangeEvent) {
      _childrenNotLaidOut.addAll(_childrenById.keys);

      markNeedsLayout();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Locale changes trigger a repaint that clears dirty flags, but port positions
        // need recalculation for proper node rendering. This forces an additional repaint.
        _controller.linksDataDirty = true;
        _controller.nodesDataDirty = true;
        _portsChanged = true;

        _childrenNotPainted.addAll(_childrenById.keys);

        markNeedsPaint();
      });
    } else if (event is FlLoadProjectEvent || event is FlNewProjectEvent) {
      _transformMatrix = null;
      _transformChanged = true;

      _childrenNotLaidOut.addAll(_childrenById.keys);
      return _updateNodes();
    }

    // Mark the render object for the correct rendering operation based on the event type.
    if (event is FlPaintEventCat) {
      markNeedsPaint();
    } else if (event is FlLayoutEventCat) {
      markNeedsLayout();
    }
  }

  final FlNodesController _controller;
  final void Function(String linkId, Offset position)? _showLinkContextMenu;

  final Map<String, RenderBox> _childrenById = {};

  // We keep track of the layout operation manually beacuse the hasSize getter
  // calls the size method which implementation causes assertions to be thrown.
  // See: https://api.flutter.dev/flutter/rendering/RenderBox/size.html
  final Set<String> _childrenNotLaidOut = {};
  final Set<String> _childrenNotPainted = {};

  FragmentShader _gridShader;
  FragmentShader get gridShader => _gridShader;
  set gridShader(FragmentShader value) {
    if (_gridShader == value) return;
    _gridShader = value;
    markNeedsPaint();
  }

  bool _isModalPresent = false;
  set isModalPresent(bool value) {
    if (_isModalPresent == value) return;
    _isModalPresent = value;
  }

  Matrix4? _transformMatrix;
  bool _transformChanged = true;

  Set<String> _visibleNodes = {};
  int get lodLevel => _controller.lodLevel;

  late Offset _offset;
  late double _zoom;

  final SelectionAreaCustomPainter _selectionAreaPainter;
  final TmpLinkCustomPainter _tmpLinkCustomPainter;
  final LinksCustomPainter _linksCustomPainter;

  List<_NodeDiffCheckData> _nodesDiffCheckData = [];

  List<_NodeDiffCheckData> _getNodeDiffData() => _controller.nodesAsList
      .map(
        (node) => _NodeDiffCheckData(
          id: node.id,
          offset: node.offset,
          state: node.state,
        ),
      )
      .toList();

  LinkPaintModel? _getTmpLinkData() {
    if (_controller.tempLink == null) return null;

    final TempLinkDataModel link = _controller.tempLink!;

    return LinkPaintModel(
      linkId: 'temp_link',
      outPortOffset: link.startOffset,
      inPortOffset: link.endOffset,
      outPortGeometricOrientation: link.outPortGeometricOrientation,
      inPortGeometricOrientation: link.inPortGeometricOrientation,
      linkStyle: link.linkStyle,
    );
  }

  void _loadGridShader() => gridShader.setFloatUniforms((uniforms) {
        final FlGridStyle gridStyle = _controller.style.gridStyle;

        uniforms

          // uniform vec2 uGridSpacing
          ..setVector(vec.Vector2(gridStyle.gridSpacingX, gridStyle.gridSpacingY))

          // uniform float uLineWidth
          ..setFloat(gridStyle.lineWidth)

          // uniform vec4 uLineColor
          ..setColor(gridStyle.lineColor, premultiply: true)

          // uniform float uIntersectionRadius
          ..setFloat(gridStyle.intersectionRadius)

          // uniform vec4 uIntersectionColor
          ..setColor(gridStyle.intersectionColor, premultiply: true);
      });

  /// This method can be called directly only if the event is affecting the existing nodes data and not the widget tree.
  /// This means that events related to node position, size, or state changes can call this method. If the event is
  /// affecting the widget tree, it should go through updateRenderObject() method.
  void _updateNodes() {
    if (!_controller.nodesDataDirty) return;

    RenderBox? child = firstChild;
    int index = 0;
    bool dataUpdated = false;

    // Start by assuming all current children are removed
    final Set<String> removedNodes = _childrenById.keys.toSet();

    // Refresh diff data from controller
    _nodesDiffCheckData = _getNodeDiffData();

    // Walk current children in order
    while (child != null && index < _nodesDiffCheckData.length) {
      final childParentData = child.parentData! as _ParentData;
      final _NodeDiffCheckData nodeData = _nodesDiffCheckData[index];

      // This node still exists, remove it from the "removed" set
      removedNodes.remove(nodeData.id);

      // Check if this child's metadata is stale
      if (childParentData.id != nodeData.id ||
          childParentData.offset != nodeData.offset ||
          childParentData.state.isCollapsed != nodeData.state.isCollapsed ||
          _childrenById[nodeData.id] != child) {
        childParentData
          ..id = nodeData.id
          ..offset = nodeData.offset
          ..state = nodeData.state
          ..rect = Rect.zero;

        _childrenById[nodeData.id] = child;
        _childrenNotLaidOut.add(nodeData.id);

        dataUpdated = true;
      }

      child = childParentData.nextSibling;
      index++;
    }

    // Any IDs left in `removedNodes` are gone from diff data
    for (final removedId in removedNodes) {
      _visibleNodes.remove(removedId);
      _childrenById.remove(removedId);
      _childrenNotLaidOut.remove(removedId);
      _childrenNotPainted.remove(removedId);
      _controller.nodesSpatialHashGrid.remove(removedId);

      dataUpdated = true;
    }

    // If counts don't match, data is out of sync (nodes added/removed)
    final bool treeUpdated = index != _nodesDiffCheckData.length;

    if (dataUpdated || treeUpdated) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParentData) {
      child.parentData = _ParentData();
    }
  }

  @override
  void insert(RenderBox child, {RenderBox? after}) {
    setupParentData(child);

    super.insert(child, after: after);

    final int currentIdx = lastChildIdx();

    if (currentIdx >= _nodesDiffCheckData.length) {
      throw Exception(
        'NodeEditorRenderBox: Found $currentIdx children, but only ${_nodesDiffCheckData.length} nodes in the controller.',
      );
    }

    final parentData = child.parentData! as _ParentData;

    final _NodeDiffCheckData diffCheckData = _nodesDiffCheckData[currentIdx];

    parentData
      ..id = diffCheckData.id
      ..offset = diffCheckData.offset
      ..state = diffCheckData.state;

    final BoxDecoration? decoration =
        _controller.getNodeById(diffCheckData.id)?.builtStyle.decoration;

    if (decoration?.borderRadius is BorderRadius) {
      final borderRadius = decoration!.borderRadius! as BorderRadius;
      parentData.borderRadius = borderRadius.topLeft.x;
    } else if (decoration?.borderRadius is Radius) {
      final radius = decoration!.borderRadius! as Radius;
      parentData.borderRadius = radius.x;
    } else {
      parentData.borderRadius = 8.0;
    }

    _childrenById[parentData.id] = child;
    _childrenNotLaidOut.add(parentData.id);
  }

  int lastChildIdx() {
    int index = 0;
    RenderBox? current = firstChild;

    while (current != null) {
      if (current == lastChild) return index;
      current = childAfter(current);
      index++;
    }

    return -1;
  }

  @override
  void performLayout() {
    // On Flutter Web, opening overlay portals (dialogs, modals, sheets, etc.) triggers
    // a full layout pass rather than a simple repaint, unlike native platforms.
    // This can desynchronize cached layout data inside custom RenderObjects,
    // especially when locale changes occur within a modal — font fallback chains
    // may change without property updates, causing text to render incorrectly.
    //
    // To ensure consistency, we detect when overlays are active and force a full
    // layout pass. This keeps cached geometry and text metrics synchronized across
    // modals, locale switches, and platform-specific rendering behaviors.
    //
    // TLDR: Flutter trickery. Don't question it.
    if (_isModalPresent) _childrenNotLaidOut.addAll(_childrenById.keys);

    size = constraints.biggest;

    // If the child has not been laid out yet, we need to layout it.
    // Otherwise, we only need to layout it if it's within the viewport.

    for (final String nodeId in _childrenNotLaidOut) {
      final RenderBox? child = _childrenById[nodeId];

      if (child == null) continue;

      final childParentData = child.parentData! as _ParentData;

      child.layout(
        const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
        ),
        parentUsesSize: true,
      );

      final renderBoxRect = Rect.fromLTWH(
        childParentData.offset.dx,
        childParentData.offset.dy,
        child.size.width,
        child.size.height,
      );

      childParentData.rect = renderBoxRect;

      _controller.nodesSpatialHashGrid.update((id: nodeId, rect: renderBoxRect));

      _controller.getNodeById(nodeId)!.cachedRenderboxRect = renderBoxRect;
    }

    _childrenNotLaidOut.clear();

    // Here we should be updating the visibleNodes set with the nodes that are within the viewport.
    // This action is delayed until the paint method to ensure all layout operations are done.
  }

  Rect _calculateViewport() => Rect.fromLTWH(
        -size.width / 2 / _zoom - _offset.dx,
        -size.height / 2 / _zoom - _offset.dy,
        size.width / _zoom,
        size.height / _zoom,
      );

  /// We need to manually mark the transform matrix when the viewport resizes
  Size _lastViewportSize = Size.zero;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_lastViewportSize != size) {
      _lastViewportSize = size;
      _transformChanged = true;
    }

    final ui.Rect viewport = _prepareCanvas(context.canvas, size);

    // Performing the visibility update here ensures all layout operations are done.

    _visibleNodes = _controller.nodesSpatialHashGrid
        .queryArea(
          // Inflate the viewport to include nodes that are close to the edges
          viewport.inflate(300),
        )
        .union(_childrenNotPainted);

    _paintGrid(context.canvas, viewport);

    _linksCustomPainter.paint(
      context.canvas,
      viewport,
      transformChanged: _transformChanged,
      portsChanged: _portsChanged,
    );

    _paintChildren(context);

    _tmpLinkCustomPainter.paint(context.canvas, viewport);

    _selectionAreaPainter.paint(context.canvas, viewport);

    if (kDebugMode) {
      paintDebugViewport(context.canvas, viewport);
      paintDebugOffset(context.canvas, size);
    }

    _controller.nodesDataDirty = false;
    _controller.linksDataDirty = false;
    _transformChanged = false;

    _childrenNotPainted.clear();
  }

  Matrix4 _getTransformMatrix() {
    if (_transformMatrix != null && !_transformChanged) {
      return _transformMatrix!;
    }

    _transformMatrix = Matrix4.identity()
      ..translateByVector3(Vector3(size.width / 2, size.height / 2, 0))
      ..scaleByDouble(_zoom, _zoom, 1.0, 1.0)
      ..translateByVector3(Vector3(_offset.dx, _offset.dy, 0));

    return _transformMatrix!;
  }

  Rect _prepareCanvas(Canvas canvas, Size size) {
    canvas.transform(_getTransformMatrix().storage);

    final ui.Rect viewport = _calculateViewport();

    canvas.clipRect(
      viewport,
      clipOp: ui.ClipOp.intersect,
      doAntiAlias: false,
    );

    return viewport;
  }

  ////////////////////////////////////////////////////////////////////
  /// Painting methods
  ////////////////////////////////////////////////////////////////////

  void _paintGrid(Canvas canvas, Rect viewport) {
    if (!_controller.style.gridStyle.showGrid) return;

    canvas.drawRect(viewport, Paint()..shader = gridShader);
  }

  bool _portsChanged = true;

  final List<RenderBox> selectedChildren = [];
  final Path selectedShadowPath = Path();
  final Map<FlPortStyle, (Path, Paint)> batchSelectedPortByStyle = {};

  final List<RenderBox> unselectedChildren = [];
  final Path unselectedShadowPath = Path();
  final Map<FlPortStyle, (Path, Paint)> batchUnselectedPortByStyle = {};

  final List<(PortLocator, Rect)> portsHitTestData = [];

  void _paintChildren(PaintingContext context) {
    if (_controller.nodesDataDirty ||
        _controller.linksDataDirty ||
        _transformChanged ||
        _portsChanged) {
      // Clear the old frame data

      selectedChildren.clear();
      selectedShadowPath.reset();

      unselectedChildren.clear();
      unselectedShadowPath.reset();

      batchSelectedPortByStyle.clear();
      batchUnselectedPortByStyle.clear();
      portsHitTestData.clear();

      // Acquire new frame data

      final Set<PortPaintModel> portData = {};

      for (final String nodeId in _visibleNodes) {
        final RenderBox? child = _childrenById[nodeId];

        final childParentData = child!.parentData! as _ParentData;

        if (childParentData.state.isSelected) {
          selectedChildren.add(child);

          if (_controller.style.nodesShadow != null) {
            final BoxShadow shadow = _controller.style.nodesShadow!;

            selectedShadowPath.addRRect(
              RRect.fromRectAndRadius(
                childParentData.rect.inflate(shadow.blurRadius),
                Radius.circular(childParentData.borderRadius),
              ),
            );
          }

          if (lodLevel <= 2 || childParentData.state.isCollapsed) continue;

          for (final FlPortDataModel port in _controller.getNodeById(nodeId)!.ports.values) {
            portData.add(
              PortPaintModel(
                locator: (nodeId: nodeId, portId: port.prototype.idName),
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.style,
              ),
            );
          }
        } else {
          unselectedChildren.add(child);

          if (_controller.style.nodesShadow != null) {
            final BoxShadow shadow = _controller.style.nodesShadow!;

            unselectedShadowPath.addRRect(
              RRect.fromRectAndRadius(
                childParentData.rect.inflate(shadow.blurRadius),
                Radius.circular(childParentData.borderRadius),
              ),
            );
          }

          if (lodLevel <= 2 || childParentData.state.isCollapsed) continue;

          for (final FlPortDataModel port in _controller.getNodeById(nodeId)!.ports.values) {
            portData.add(
              PortPaintModel(
                locator: (nodeId: nodeId, portId: port.prototype.idName),
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.style,
              ),
            );
          }
        }
      }

      for (final data in portData) {
        final FlPortStyle style = data.style;

        final Map<FlPortStyle, (ui.Path, ui.Paint)> batchPortByStyle =
            data.isSelected ? batchSelectedPortByStyle : batchUnselectedPortByStyle;

        batchPortByStyle.putIfAbsent(
          style,
          () => (
            Path(),
            Paint()
              ..color = style.color
              ..style = PaintingStyle.fill,
          ),
        );

        late Path path;

        switch (style.shape) {
          case FlPortShape.circle:
            path = PathUtils.computeCirclePortPath(data);
            break;
          case FlPortShape.triangle:
            path = PathUtils.computeTrianglePortPath(data);
            break;
        }

        portsHitTestData.add((data.locator, path.getBounds()));

        batchPortByStyle[style]!.$1.addPath(path, Offset.zero);
      }

      if (!_portsChanged) {
        _portsChanged = true;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          markNeedsPaint();
        });
      } else {
        _portsChanged = false;
      }
    }

    // First we paint the unselected nodes, so they appear below the selected ones.

    final BoxShadow? shadow = _controller.style.nodesShadow;

    if (lodLevel == 4 && shadow != null) {
      context.canvas.drawShadow(
        unselectedShadowPath.shift(shadow.offset),
        shadow.color,
        4,
        true,
      );
    }

    for (final RenderBox unselectedChild in unselectedChildren) {
      final childParentData = unselectedChild.parentData! as _ParentData;
      context.paintChild(unselectedChild, childParentData.offset);
    }

    if (lodLevel >= 3) {
      for (final MapEntry<FlPortStyle, (ui.Path, ui.Paint)> entry
          in batchUnselectedPortByStyle.entries) {
        final (ui.Path path, ui.Paint paint) = entry.value;
        context.canvas.drawPath(path, paint);
      }
    }

    // Then we paint the selected nodes, so they appear above the unselected ones.

    if (lodLevel == 4 && shadow != null) {
      context.canvas.drawShadow(
        selectedShadowPath.shift(shadow.offset),
        shadow.color,
        4,
        true,
      );
    }

    for (final RenderBox selectedChild in selectedChildren) {
      final childParentData = selectedChild.parentData! as _ParentData;
      context.paintChild(selectedChild, childParentData.offset);
    }

    if (lodLevel >= 3) {
      for (final MapEntry<FlPortStyle, (ui.Path, ui.Paint)> entry
          in batchSelectedPortByStyle.entries) {
        final (ui.Path path, ui.Paint paint) = entry.value;
        context.canvas.drawPath(path, paint);
      }
    }
  }

  ///////////////////////////////////////////////////////////////////
  /// Debug methods
  ///////////////////////////////////////////////////////////////////

  @visibleForTesting
  void paintDebugViewport(Canvas canvas, Rect viewport) {
    final Paint debugPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    // Draw the viewport rect
    canvas.drawRect(viewport, debugPaint);
  }

  @visibleForTesting
  void paintDebugOffset(Canvas canvas, Size size) {
    final Paint debugPaint = Paint()
      ..color = Colors.green.withAlpha(200)
      ..style = PaintingStyle.fill;

    // Draw the offset point
    canvas.drawCircle(Offset.zero, 5, debugPaint);
  }

  //////////////////////////////////////////////////////////////////
  /// Built-in hit testing methods
  //////////////////////////////////////////////////////////////////

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final Offset centeredPosition = position - Offset(size.width / 2, size.height / 2);
    final Offset scaledPosition = centeredPosition.scale(1 / _zoom, 1 / _zoom);
    final Offset transformedPosition = scaledPosition - _offset;

    for (final String nodeId in _controller.nodesSpatialHashGrid.queryCoords(
      transformedPosition,
    )) {
      final RenderBox child = _childrenById[nodeId]!;
      final childParentData = child.parentData! as _ParentData;

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: transformedPosition,
        hitTest: (BoxHitTestResult result, Offset transformed) =>
            child.hitTest(result, position: transformed),
      );

      if (isHit) {
        return true;
      }
    }

    return false;
  }

  //////////////////////////////////////////////////////////////////
  /// Hover state management methods
  //////////////////////////////////////////////////////////////////

  // Note: This hover state management doesn't belong in the controller
  // as it doesn't trigger events and can't be set externally.
  String? lastHoveredNodeId;
  String? lastHoveredLinkId;
  PortLocator? lastHoveredPortLocator;

  /// Tests for hits on nodes and handles hover/selection events
  bool hitTestNodes(
    Offset transformedPosition,
    Rect checkRect,
    PointerEvent event,
  ) {
    if (event is! PointerDownEvent && event is! PointerHoverEvent) return false;

    final Set<String> nodeIds = _controller.nodesSpatialHashGrid.queryCoords(transformedPosition);

    if (nodeIds.isEmpty) {
      if (event is PointerHoverEvent) {
        _clearNodeHover();
      }
      return false;
    }

    // Find the topmost node that contains the position
    String? hitNodeId;
    for (final nodeId in nodeIds) {
      final RenderBox child = _childrenById[nodeId]!;
      final childParentData = child.parentData! as _ParentData;

      // Based on the level of detail, we use reduce the complexity of the hit testing.
      if (lodLevel >= 3) {
        final childRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            childParentData.offset.dx,
            childParentData.offset.dy,
            child.size.width,
            child.size.height,
          ),
          Radius.circular(childParentData.borderRadius),
        );

        if (childRect.contains(transformedPosition)) {
          hitNodeId = nodeId;
          break;
        }
      } else {
        final childRect = Rect.fromLTWH(
          childParentData.offset.dx,
          childParentData.offset.dy,
          child.size.width,
          child.size.height,
        );

        if (childRect.contains(transformedPosition)) {
          hitNodeId = nodeId;
          break;
        }
      }
    }

    if (hitNodeId == null) {
      if (event is PointerHoverEvent) {
        _clearNodeHover();
      }
      return false;
    }

    _handleNodeHit(hitNodeId, event);
    _clearLinkHover();
    _clearPortHover();

    return true;
  }

  /// Tests for hits on links and handles hover/selection events
  bool hitTestLinks(
    Offset transformedPosition,
    Rect checkRect,
    PointerEvent event,
  ) {
    if (event is! PointerDownEvent && event is! PointerHoverEvent) {
      return false;
    }

    final String? hitLinkId = _findHitLink(transformedPosition, checkRect);
    if (hitLinkId == null) {
      if (event is PointerHoverEvent) {
        _clearLinkHover();
      }
      return false;
    }

    // Check if there's a node overlapping the link at this position
    // Nodes have higher priority than links
    final Set<String> nodeIds = _controller.nodesSpatialHashGrid.queryCoords(transformedPosition);

    if (nodeIds.isNotEmpty) {
      for (final nodeId in nodeIds) {
        final RenderBox child = _childrenById[nodeId]!;
        final childParentData = child.parentData! as _ParentData;

        final childRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            childParentData.offset.dx,
            childParentData.offset.dy,
            child.size.width,
            child.size.height,
          ),
          Radius.circular(childParentData.borderRadius),
        );

        if (childRect.contains(transformedPosition)) {
          if (event is PointerHoverEvent) {
            _clearLinkHover();
          }
          return false; // Node takes priority
        }
      }
    }

    _handleLinkHit(hitLinkId, event);
    _clearPortHover();
    _clearNodeHover();

    return true;
  }

  /// Tests for hits on ports and handles hover events
  bool hitTestPorts(
    Offset transformedPosition,
    Rect checkRect,
    PointerEvent event,
  ) {
    if (event is! PointerHoverEvent) return false;

    final PortLocator? hitPortLocator = _findHitPort(transformedPosition, checkRect);
    final isHit = hitPortLocator != null;

    if (isHit) {
      _handlePortHover(hitPortLocator);
      _clearLinkHover();
      _clearNodeHover();
    } else {
      _clearPortHover();
    }

    return isHit;
  }

  //////////////////////////////////////////////////////////////////
  /// Hit detection methods
  //////////////////////////////////////////////////////////////////

  /// Finds a link that is hit by the given position within tolerance
  String? _findHitLink(Offset transformedPosition, Rect checkRect) {
    const tolerance = 4.0;

    for (final MapEntry<String, (ui.Rect, ui.Path)> entry
        in _linksCustomPainter.linksHitTestData.entries) {
      final String id = entry.key;
      final (ui.Rect, ui.Path) pathData = entry.value;

      if (checkRect.overlaps(pathData.$1)) {
        if (PathUtils.isPointNearPath(
          pathData.$2,
          transformedPosition,
          tolerance,
        )) {
          return id;
        }
      }
    }

    return null;
  }

  /// Finds a port that is hit by the given position within tolerance
  PortLocator? _findHitPort(Offset transformedPosition, Rect checkRect) {
    const tolerance = 4.0;

    for (final (locator, rect) in portsHitTestData) {
      if (checkRect.overlaps(rect.inflate(tolerance))) {
        return locator;
      }
    }
    return null;
  }

  //////////////////////////////////////////////////////////////////
  /// Hover state setters
  //////////////////////////////////////////////////////////////////

  /// Sets hover state for a node
  void _setNodeHover(String nodeId) {
    if (lastHoveredNodeId == nodeId) return;

    _clearNodeHover();

    _controller.getNodeById(nodeId)!.state.isHovered = true;
    _controller.nodesDataDirty = true;
    lastHoveredNodeId = nodeId;

    _controller.eventBus.emit(
      FlNodeHoverEvent(
        nodeId,
        type: FlHoverEventType.enter,
        id: const Uuid().v4(),
      ),
    );

    markNeedsPaint();
  }

  /// Sets hover state for a link
  void _setLinkHover(String linkId) {
    if (lastHoveredLinkId == linkId) return;

    _clearLinkHover();

    _controller.links[linkId]!.state.isHovered = true;
    _controller.linksDataDirty = true;
    lastHoveredLinkId = linkId;

    markNeedsPaint();
  }

  /// Sets hover state for a port
  void _setPortHover(PortLocator portLocator) {
    if (lastHoveredPortLocator == portLocator) return;

    // Clear other hover states when port is hovered (ports have highest priority)
    _clearLinkHover();
    _clearNodeHover();
    _clearPortHover();

    _controller.getNodeById(portLocator.nodeId)!.ports[portLocator.portId]!.state.isHovered = true;
    _controller.nodesDataDirty = true;
    lastHoveredPortLocator = portLocator;

    markNeedsPaint();
  }

  //////////////////////////////////////////////////////////////////
  /// Hover state clearers
  //////////////////////////////////////////////////////////////////

  /// Clears hover state for nodes
  void _clearNodeHover() {
    if (lastHoveredNodeId == null || !_controller.isNodePresent(lastHoveredNodeId!)) {
      return;
    }

    _controller.getNodeById(lastHoveredNodeId!)!.state.isHovered = false;
    _controller.nodesDataDirty = true;

    _controller.eventBus.emit(
      FlNodeHoverEvent(
        lastHoveredNodeId!,
        type: FlHoverEventType.enter,
        id: const Uuid().v4(),
      ),
    );

    lastHoveredNodeId = null;

    markNeedsPaint();
  }

  /// Clears hover state for links
  void _clearLinkHover() {
    if (lastHoveredLinkId == null || !_controller.links.containsKey(lastHoveredLinkId)) {
      return;
    }

    _controller.links[lastHoveredLinkId!]!.state.isHovered = false;
    _controller.linksDataDirty = true;
    lastHoveredLinkId = null;

    markNeedsPaint();
  }

  /// Clears hover state for ports
  void _clearPortHover() {
    if (lastHoveredPortLocator == null) return;

    _controller
        .getNodeById(lastHoveredPortLocator!.nodeId)!
        .ports[lastHoveredPortLocator!.portId]!
        .state
        .isHovered = false;
    _controller.nodesDataDirty = true;
    lastHoveredPortLocator = null;

    markNeedsPaint();
  }

  /// Clears all hover states
  // ignore: unused_element
  void _clearAllHoverStates() {
    _clearNodeHover();
    _clearLinkHover();
    _clearPortHover();
  }

  //////////////////////////////////////////////////////////////////
  /// Render object event handlers
  //////////////////////////////////////////////////////////////////

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    super.handleEvent(event, entry);

    final Offset centeredPosition = event.localPosition - Offset(size.width / 2, size.height / 2);
    final Offset scaledPosition = centeredPosition.scale(1 / _zoom, 1 / _zoom);
    final Offset transformedPosition = scaledPosition - _offset;

    // Ignore middle mouse button events
    if (event is PointerDownEvent && event.buttons == kMiddleMouseButton ||
        _controller.tempLink != null) {
      return;
    }

    final Rect checkRect = Rect.fromCircle(
      center: transformedPosition,
      radius: 6.0,
    );

    // Skip link and port hit testing at very low zoom levels
    if (_zoom <= kLowZoomThreshold) {
      // Only test nodes when zoomed out this far
      hitTestNodes(transformedPosition, checkRect, event);
      return;
    }

    // Normal hit test order (Ports > Nodes > Links)
    if (!hitTestPorts(transformedPosition, checkRect, event)) {
      if (!hitTestNodes(transformedPosition, checkRect, event)) {
        hitTestLinks(transformedPosition, checkRect, event);
      }
    }
  }

  /// Handles node hit events (click/hover)
  void _handleNodeHit(String nodeId, PointerEvent event) {
    if (event is PointerHoverEvent) _setNodeHover(nodeId);
  }

  /// Handles link hit events (click/hover)
  void _handleLinkHit(String linkId, PointerEvent event) {
    if (_tmpLinkCustomPainter.tmpLinkData != null) return;

    if (event is PointerDownEvent) {
      if (event.buttons == kSecondaryMouseButton) {
        if (_showLinkContextMenu != null) {
          _showLinkContextMenu(linkId, event.position);
        }
      }

      _controller.selectLinkById(
        linkId,
        holdSelection: HardwareKeyboard.instance.isControlPressed,
      );

      _clearLinkHover();
    } else if (event is PointerHoverEvent) {
      _setLinkHover(linkId);
    }
  }

  /// Handles port hover events
  void _handlePortHover(PortLocator locator) {
    if (lastHoveredPortLocator != locator) {
      _clearPortHover();
      _setPortHover(locator);
    }
  }

  //////////////////////////////////////////////////////////////////
  /// Misc methods
  //////////////////////////////////////////////////////////////////

  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // dart format off
    properties
      ..add(DiagnosticsProperty<ui.FragmentShader>('gridShader', gridShader))
      ..add(IntProperty('lodLevel', lodLevel))
      ..add(IterableProperty<RenderBox>('selectedChildren', selectedChildren))
      ..add(DiagnosticsProperty<ui.Path>('selectedShadowPath', selectedShadowPath))
      ..add(DiagnosticsProperty<Map<FlPortStyle, (ui.Path, ui.Paint)>>(
          'batchSelectedPortByStyle', batchSelectedPortByStyle))
      ..add(IterableProperty<RenderBox>('unselectedChildren', unselectedChildren))
      ..add(DiagnosticsProperty<ui.Path>('unselectedShadowPath', unselectedShadowPath))
      ..add(DiagnosticsProperty<Map<FlPortStyle, (ui.Path, ui.Paint)>>(
          'batchUnselectedPortByStyle', batchUnselectedPortByStyle))
      ..add(IterableProperty<(PortLocator, ui.Rect)>('portsHitTestData', portsHitTestData))
      ..add(StringProperty('lastHoveredNodeId', lastHoveredNodeId))
      ..add(StringProperty('lastHoveredLinkId', lastHoveredLinkId))
      ..add(DiagnosticsProperty<PortLocator?>('lastHoveredPortLocator', lastHoveredPortLocator));
    // dart format on
  }
}
