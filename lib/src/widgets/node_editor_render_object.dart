import 'dart:ui' as ui;
import 'dart:ui';

import 'package:fl_nodes/src/core/controller/core.dart';
import 'package:fl_nodes/src/core/events/events.dart';
import 'package:fl_nodes/src/core/models/data.dart';
import 'package:fl_nodes/src/core/models/paint.dart';
import 'package:fl_nodes/src/core/utils/rendering/paths.dart';
import 'package:fl_nodes/src/styles/styles.dart';
import 'package:fl_nodes/src/widgets/builders.dart';
import 'package:fl_nodes/src/widgets/default_node.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:vector_math/vector_math.dart' as vec;

class NodeDiffCheckData {
  String id;
  Offset offset;
  FlNodeState state;

  NodeDiffCheckData({
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
  final FlNodeEditorController controller;
  final FragmentShader gridShader;
  final NodeHeaderBuilder? headerBuilder;
  final NodeFieldBuilder? fieldBuilder;
  final NodePortBuilder? portBuilder;
  final NodeContextMenuBuilder? contextMenuBuilder;
  final NodeBuilder? nodeBuilder;

  NodeEditorRenderObjectWidget({
    super.key,
    required this.controller,
    required this.gridShader,
    this.headerBuilder,
    this.fieldBuilder,
    this.portBuilder,
    this.contextMenuBuilder,
    this.nodeBuilder,
  }) : super(
          children: controller.nodesAsList
              .map(
                (node) => DefaultNodeWidget(
                  controller: controller,
                  node: node,
                  headerBuilder: headerBuilder,
                  fieldBuilder: fieldBuilder,
                  portBuilder: portBuilder,
                  contextMenuBuilder: contextMenuBuilder,
                  nodeBuilder: nodeBuilder,
                ),
              )
              .toList() as List<Widget>,
        );

  @override
  NodeEditorRenderBox createRenderObject(BuildContext context) {
    return NodeEditorRenderBox(
      controller: controller,
      gridShader: gridShader,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    NodeEditorRenderBox renderObject,
  ) {
    renderObject.gridShader = gridShader;
  }
}

class NodeEditorRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  NodeEditorRenderBox({
    required FlNodeEditorController controller,
    required FragmentShader gridShader,
  })  : _controller = controller,
        _gridShader = gridShader {
    _loadGridShader();

    _updateNodes();

    _offset = _controller.viewportOffset;
    _zoom = _controller.viewportZoom;
    _highlightArea = _controller.highlightArea;

    _controller.eventBus.events.listen(_handleEvent);
  }

  void _handleEvent(NodeEditorEvent event) {
    if (event.isHandled) return;

    // In the following code we must account for the possibility of events affecting nodes outside the viewport

    // Node widgets state related events trigger style updates. Arbitrary styles might require layout updates.
    // Therefore all node widgets must be marked for layout updates when receiving these events.

    if (event is FlViewportOffsetEvent) {
      _offset = event.offset;
      _transformMatrixDirty = true;
      markNeedsPaint();
    } else if (event is FlViewportZoomEvent) {
      _zoom = event.zoom;
      _transformMatrixDirty = true;
      markNeedsPaint();
    } else if (event is FlAreaHighlightEvent) {
      _highlightArea = event.area;
      markNeedsPaint();
    } else if (event is FlDrawTempLinkEvent) {
      _tmpLinkData = _getTmpLinkData();
      markNeedsPaint();
    } else if (event is FlDragSelectionEvent) {
      _updateNodes();
    } else if (event is FlAddNodeEvent ||
        event is FlRemoveNodeEvent ||
        event is FlCutSelectionEvent ||
        event is FlPasteSelectionEvent) {
      _updateNodes();
    } else if (event is FlAddLinkEvent || event is FlRemoveLinkEvent) {
      markNeedsPaint();
    } else if (event is FlLinkSelectionEvent) {
      markNeedsPaint();
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
    } else if (event is FlConfigurationChangeEvent) {
      _updateNodes();
    } else if (event is FlLocaleChangeEvent || event is FlStyleChangeEvent) {
      _childrenNotLaidOut.addAll(_childrenById.keys);

      markNeedsLayout();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Locale changes trigger a repaint that clears dirty flags, but port positions
        // need recalculation for proper node rendering. This forces an additional repaint.
        _controller.linksDataDirty = true;
        _controller.nodesDataDirty = true;
        _portsPositionsDirty = true;

        _childrenNotPainted.addAll(_childrenById.keys);

        markNeedsPaint();
      });
    } else if (event is FlLoadProjectEvent || event is FlNewProjectEvent) {
      _transformMatrix = null;
      _transformMatrixDirty = true;

      _childrenNotLaidOut.addAll(_childrenById.keys);
      _updateNodes();
    }
  }

  final FlNodeEditorController _controller;
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

  Matrix4? _transformMatrix;
  bool _transformMatrixDirty = true;

  Set<String> _visibleNodes = {};
  int get lodLevel => _controller.lodLevel;

  late Offset _offset;
  late double _zoom;
  LinkPaintModel? _tmpLinkData;
  Rect? _highlightArea;

  List<NodeDiffCheckData> _nodesDiffCheckData = [];

  List<NodeDiffCheckData> _getNodeDiffData() {
    return _controller.nodesAsList
        .map(
          (node) => NodeDiffCheckData(
            id: node.id,
            offset: node.offset,
            state: node.state,
          ),
        )
        .toList();
  }

  LinkPaintModel? _getTmpLinkData() {
    if (_controller.tempLink == null) return null;

    final link = _controller.tempLink!;

    return LinkPaintModel(
      id: "", // Temporary link doesn't need an ID
      outPortOffset: link.from,
      inPortOffset: link.to,
      linkStyle: link.style,
    );
  }

  void _loadGridShader() => gridShader.setFloatUniforms((uniforms) {
        final gridStyle = _controller.style.gridStyle;

        // uniform vec2 uGridSpacing
        uniforms.setVector(
          vec.Vector2(gridStyle.gridSpacingX, gridStyle.gridSpacingY),
        );

        // uniform float uLineWidth
        uniforms.setFloat(gridStyle.lineWidth);

        // uniform vec4 uLineColor
        uniforms.setColor(gridStyle.lineColor, premultiply: true);

        // uniform float uIntersectionRadius
        uniforms.setFloat(gridStyle.intersectionRadius);

        // uniform vec4 uIntersectionColor
        uniforms.setColor(gridStyle.intersectionColor, premultiply: true);
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
      final nodeData = _nodesDiffCheckData[index];

      // This node still exists → remove it from the "removed" set
      removedNodes.remove(nodeData.id);

      // Check if this child's metadata is stale
      if (childParentData.id != nodeData.id ||
          childParentData.offset != nodeData.offset ||
          childParentData.state.isCollapsed != nodeData.state.isCollapsed ||
          _childrenById[nodeData.id] != child) {
        childParentData.id = nodeData.id;
        childParentData.offset = nodeData.offset;
        childParentData.state = nodeData.state;
        childParentData.rect = Rect.zero;

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

    final currentIdx = lastChildIdx();

    if (currentIdx >= _nodesDiffCheckData.length) {
      throw Exception(
        'NodeEditorRenderBox: Found $currentIdx children, but only ${_nodesDiffCheckData.length} nodes in the controller.',
      );
    }

    final parentData = child.parentData as _ParentData;

    final diffCheckData = _nodesDiffCheckData[currentIdx];

    parentData.id = diffCheckData.id;
    parentData.offset = diffCheckData.offset;
    parentData.state = diffCheckData.state;

    final decoration =
        _controller.nodes[diffCheckData.id]?.builtStyle.decoration;

    if (decoration?.borderRadius is BorderRadius) {
      final borderRadius = decoration!.borderRadius as BorderRadius;
      parentData.borderRadius = borderRadius.topLeft.x;
    } else if (decoration?.borderRadius is Radius) {
      final radius = decoration!.borderRadius as Radius;
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
    size = constraints.biggest;

    // If the child has not been laid out yet, we need to layout it.
    // Otherwise, we only need to layout it if it's within the viewport.

    for (final nodeId in _childrenNotLaidOut) {
      final child = _childrenById[nodeId];

      if (child == null) continue;

      final childParentData = child.parentData as _ParentData;

      child.layout(
        BoxConstraints.loose(constraints.biggest),
        parentUsesSize: true,
      );

      final renderBoxRect = Rect.fromLTWH(
        childParentData.offset.dx,
        childParentData.offset.dy,
        child.size.width,
        child.size.height,
      );

      childParentData.rect = renderBoxRect;

      _controller.nodesSpatialHashGrid
          .update((id: nodeId, rect: renderBoxRect));
    }

    _childrenNotLaidOut.clear();

    // Here we should be updating the visibleNodes set with the nodes that are within the viewport.
    // This action is delayed until the paint method to ensure all layout operations are done.
  }

  Rect _calculateViewport() {
    return Rect.fromLTWH(
      -size.width / 2 / _zoom - _offset.dx,
      -size.height / 2 / _zoom - _offset.dy,
      size.width / _zoom,
      size.height / _zoom,
    );
  }

  /// We need to manually mark the transform matrix when the viewport resizes
  Size _lastViewportSize = Size.zero;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_lastViewportSize != size) {
      _lastViewportSize = size;
      _transformMatrixDirty = true;
    }

    final viewport = _prepareCanvas(context.canvas, size);

    // Performing the visibility update here ensures all layout operations are done.

    _visibleNodes = _controller.nodesSpatialHashGrid
        .queryArea(
          // Inflate the viewport to include nodes that are close to the edges
          viewport.inflate(300),
        )
        .union(_childrenNotPainted);

    _paintGrid(context.canvas, viewport);

    _paintLinks(context.canvas, viewport);

    _paintChildren(context);

    _paintTemporaryLink(context.canvas);

    _paintHighlightArea(context.canvas, viewport);

    if (kDebugMode) {
      paintDebugViewport(context.canvas, viewport);
      paintDebugOffset(context.canvas, size);
    }

    _controller.nodesDataDirty = false;
    _controller.linksDataDirty = false;
    _transformMatrixDirty = false;

    _childrenNotPainted.clear();
  }

  Matrix4 _getTransformMatrix() {
    if (_transformMatrix != null && !_transformMatrixDirty) {
      return _transformMatrix!;
    }

    _transformMatrix = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(_zoom, _zoom, 1.0)
      ..translate(_offset.dx, _offset.dy);

    return _transformMatrix!;
  }

  Rect _prepareCanvas(Canvas canvas, Size size) {
    canvas.transform(_getTransformMatrix().storage);

    final viewport = _calculateViewport();

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

  bool _portsPositionsDirty = true;

  final List<(Path, Paint)> _gradientLinks = [];
  final Map<FlLinkStyle, (Path, Paint)> _solidColorsLinksBatches = {};

  final List<(String, Path)> _linksHitTestData = [];

  void _paintLinks(Canvas canvas, Rect viewport) {
    // Here we collect data also for ports and children to avoid multiple loops

    if (_controller.linksDataDirty ||
        _controller.nodesDataDirty ||
        _transformMatrixDirty ||
        _portsPositionsDirty) {
      final Set<LinkPaintModel> linkData = {};

      // We cannot just reset the paths because the link styles are stateful that change hash code
      _gradientLinks.clear();
      _solidColorsLinksBatches.clear();
      _linksHitTestData.clear();

      for (final link in _controller.linksById.values) {
        final outNode = _controller.nodes[link.fromTo.from]!;
        final inNode = _controller.nodes[link.fromTo.fromPort]!;
        final outPort = outNode.ports[link.fromTo.to]!;
        final inPort = inNode.ports[link.fromTo.toPort]!;

        final Rect pathBounds = Rect.fromPoints(
          outNode.offset + outPort.offset,
          inNode.offset + inPort.offset,
        );

        if (!viewport.overlaps(pathBounds)) continue;

        // NOTE: The port offset is relative to the node
        linkData.add(
          LinkPaintModel(
            id: link.id,
            outPortOffset: outNode.offset + outPort.offset,
            inPortOffset: inNode.offset + inPort.offset,
            linkStyle: outPort.style.linkStyleBuilder(link.state),
          ),
        );
      }

      // We don't draw the temporary link here because it should be on top of the nodes

      for (final data in linkData) {
        if (data.linkStyle.gradient != null) {
          late Path path;

          switch (data.linkStyle.curveType) {
            case FlLinkCurveType.straight:
              path = PathUtils.computeStraightLinkPath(data);
              break;
            case FlLinkCurveType.bezier:
              path = PathUtils.computeBezierLinkPath(data);
              break;
            case FlLinkCurveType.ninetyDegree:
              path = PathUtils.computeNinetyDegreesLinkPath(data);
              break;
          }

          _linksHitTestData.add((data.id, path));

          final shader = data.linkStyle.gradient!.createShader(
            Rect.fromPoints(data.outPortOffset, data.inPortOffset),
          );

          final Paint paint = Paint()
            ..shader = shader
            ..style = PaintingStyle.stroke
            ..strokeWidth = data.linkStyle.lineWidth;

          _gradientLinks.add((path, paint));
        } else {
          final style = data.linkStyle;
          _solidColorsLinksBatches.putIfAbsent(style, () {
            return (
              Path(),
              Paint()
                ..color = style.color!
                ..style = PaintingStyle.stroke
                ..strokeWidth = style.lineWidth
            );
          });

          late Path path;

          switch (style.curveType) {
            case FlLinkCurveType.straight:
              path = PathUtils.computeStraightLinkPath(data);
              break;
            case FlLinkCurveType.bezier:
              path = PathUtils.computeBezierLinkPath(data);
              break;
            case FlLinkCurveType.ninetyDegree:
              path = PathUtils.computeNinetyDegreesLinkPath(data);
              break;
          }

          _linksHitTestData.add((data.id, path));

          _solidColorsLinksBatches[style]!.$1.addPath(path, Offset.zero);
        }
      }
    }

    for (final (path, paint) in _gradientLinks) {
      canvas.drawPath(path, paint);
    }

    for (final entry in _solidColorsLinksBatches.entries) {
      final (path, paint) = entry.value;
      canvas.drawPath(path, paint);
    }
  }

  final List<RenderBox> selectedChildren = [];
  final Path selectedShadowPath = Path();
  final Map<FlPortStyle, (Path, Paint)> batchSelectedPortByStyle = {};

  final List<RenderBox> unselectedChildren = [];
  final Path unselectedShadowPath = Path();
  final Map<FlPortStyle, (Path, Paint)> batchUnselectedPortByStyle = {};

  final List<((String, String), Rect)> portsHitTestData = [];

  void _paintChildren(PaintingContext context) {
    if (_controller.nodesDataDirty ||
        _controller.linksDataDirty ||
        _transformMatrixDirty ||
        _portsPositionsDirty) {
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

      for (final nodeId in _visibleNodes) {
        final child = _childrenById[nodeId];

        final childParentData = child!.parentData as _ParentData;

        if (childParentData.state.isSelected) {
          selectedChildren.add(child);

          selectedShadowPath.addRRect(
            RRect.fromRectAndRadius(
              childParentData.rect.inflate(4),
              Radius.circular(childParentData.borderRadius),
            ),
          );

          if (lodLevel <= 2) continue;

          for (final port in _controller.nodes[nodeId]!.ports.values) {
            portData.add(
              PortPaintModel(
                locator: (nodeId, port.prototype.idName),
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.style,
              ),
            );
          }
        } else {
          unselectedChildren.add(child);

          unselectedShadowPath.addRRect(
            RRect.fromRectAndRadius(
              childParentData.rect.inflate(4),
              Radius.circular(childParentData.borderRadius),
            ),
          );

          if (lodLevel <= 2) continue;

          for (final port in _controller.nodes[nodeId]!.ports.values) {
            portData.add(
              PortPaintModel(
                locator: (nodeId, port.prototype.idName),
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.style,
              ),
            );
          }
        }
      }

      for (final data in portData) {
        final style = data.style;

        final batchPortByStyle = data.isSelected
            ? batchSelectedPortByStyle
            : batchUnselectedPortByStyle;

        batchPortByStyle.putIfAbsent(style, () {
          return (
            Path(),
            Paint()
              ..color = style.color
              ..style = PaintingStyle.fill,
          );
        });

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

      if (!_portsPositionsDirty) {
        _portsPositionsDirty = true;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          markNeedsPaint();
        });
      } else {
        _portsPositionsDirty = false;
      }
    }

    // First we paint the unselected nodes, so they appear below the selected ones.

    if (lodLevel == 4) {
      context.canvas.drawShadow(
        unselectedShadowPath,
        const ui.Color(0xC8000000),
        4,
        true,
      );
    }

    for (final unselectedChild in unselectedChildren) {
      final childParentData = unselectedChild.parentData! as _ParentData;
      context.paintChild(unselectedChild, childParentData.offset);
    }

    if (lodLevel >= 3) {
      for (final entry in batchUnselectedPortByStyle.entries) {
        final (path, paint) = entry.value;
        context.canvas.drawPath(path, paint);
      }
    }

    // Then we paint the selected nodes, so they appear above the unselected ones.

    if (lodLevel == 4) {
      context.canvas.drawShadow(
        selectedShadowPath,
        const ui.Color(0xC8000000),
        4,
        true,
      );
    }

    for (final selectedChild in selectedChildren) {
      final childParentData = selectedChild.parentData! as _ParentData;
      context.paintChild(selectedChild, childParentData.offset);
    }

    if (lodLevel >= 3) {
      for (final entry in batchSelectedPortByStyle.entries) {
        final (path, paint) = entry.value;
        context.canvas.drawPath(path, paint);
      }
    }
  }

  void _paintTemporaryLink(Canvas canvas) {
    if (_tmpLinkData == null) return;

    late Path path;

    switch (_tmpLinkData!.linkStyle.curveType) {
      case FlLinkCurveType.straight:
        path = PathUtils.computeStraightLinkPath(_tmpLinkData!);
        break;
      case FlLinkCurveType.bezier:
        path = PathUtils.computeBezierLinkPath(_tmpLinkData!);
        break;
      case FlLinkCurveType.ninetyDegree:
        path = PathUtils.computeNinetyDegreesLinkPath(_tmpLinkData!);
        break;
    }

    final Paint paint = Paint();

    if (_tmpLinkData!.linkStyle.gradient != null) {
      final shader = _tmpLinkData!.linkStyle.gradient!.createShader(
        Rect.fromPoints(
          _tmpLinkData!.outPortOffset,
          _tmpLinkData!.inPortOffset,
        ),
      );

      paint
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = _tmpLinkData!.linkStyle.lineWidth;
    } else {
      paint
        ..color = _tmpLinkData!.linkStyle.color!
        ..style = PaintingStyle.stroke
        ..strokeWidth = _tmpLinkData!.linkStyle.lineWidth;
    }

    canvas.drawPath(path, paint);
  }

  void _paintHighlightArea(Canvas canvas, Rect viewport) {
    if (_highlightArea == null) return;

    final style = _controller.style.highlightAreaStyle;

    final Paint selectionPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    canvas.drawRect(_highlightArea!, selectionPaint);

    final Paint borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(_highlightArea!, borderPaint);
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
  /// Hit testing methods
  //////////////////////////////////////////////////////////////////

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final Offset centeredPosition =
        position - Offset(size.width / 2, size.height / 2);
    final Offset scaledPosition = centeredPosition.scale(1 / _zoom, 1 / _zoom);
    final Offset transformedPosition = scaledPosition - _offset;

    for (final nodeId in _controller.nodesSpatialHashGrid.queryCoords(
      transformedPosition,
    )) {
      final child = _childrenById[nodeId]!;
      final childParentData = child.parentData as _ParentData;

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: transformedPosition,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child.hitTest(result, position: transformed);
        },
      );

      if (isHit) {
        return true;
      }
    }

    return false;
  }

  bool isPointNearPath(Path path, Offset point, double tolerance) {
    for (final metric in path.computeMetrics()) {
      for (double t = 0; t < metric.length; t += 1.0) {
        final pos = metric.getTangentForOffset(t)?.position;
        if (pos != null && (point - pos).distance <= tolerance) {
          return true;
        }
      }
    }

    return false;
  }

  // The code for managing hover state doesn't really belong in the controller
  // as it doesn't trigger events and can't be set externally.

  String? lastHoveredNodeId;
  String? lastHoveredLinkId;
  (String, String)? lastHoveredPortLocator;

  bool hitTestLinks(
    Offset transformedPosition,
    Rect checkRect,
    PointerEvent event,
  ) {
    if (event is! PointerDownEvent && event is! PointerHoverEvent) {
      return false;
    }

    final hitLinkId = _findHitLink(transformedPosition, checkRect);
    if (hitLinkId == null) {
      if (event is PointerHoverEvent) {
        _clearLinkHover();
      }
      return false;
    }

    final nodeIds =
        _controller.nodesSpatialHashGrid.queryCoords(transformedPosition);

    if (nodeIds.isNotEmpty) {
      for (final nodeId in nodeIds) {
        final child = _childrenById[nodeId]!;
        final childParentData = child.parentData as _ParentData;

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

          return false;
        }
      }
    }

    _handleLinkHit(hitLinkId, event);

    return true;
  }

  bool hitTestPorts(
    Offset transformedPosition,
    Rect checkRect,
    PointerEvent event,
  ) {
    if (event is! PointerHoverEvent) return false;

    final hitPortLocator = _findHitPort(transformedPosition, checkRect);
    final isHit = hitPortLocator != null;

    if (isHit) {
      _handlePortHover(hitPortLocator);
      // Clear link hover when port is hovered (ports have higher priority)
      _clearLinkHover();
    } else {
      _clearPortHover();
    }

    return isHit;
  }

  String? _findHitLink(Offset transformedPosition, Rect checkRect) {
    const tolerance = 4.0;

    for (final (id, path) in _linksHitTestData) {
      if (checkRect.overlaps(path.getBounds())) {
        if (isPointNearPath(path, transformedPosition, tolerance)) {
          return id;
        }
      }
    }
    return null;
  }

  (String, String)? _findHitPort(Offset transformedPosition, Rect checkRect) {
    const tolerance = 4.0;

    for (final (locator, rect) in portsHitTestData) {
      if (checkRect.overlaps(rect.inflate(tolerance))) {
        return locator;
      }
    }
    return null;
  }

  void _handleLinkHit(String linkId, PointerEvent event) {
    if (event is PointerDownEvent) {
      _controller.selectLinkById(
        linkId,
        holdSelection: HardwareKeyboard.instance.isControlPressed,
      );
    } else if (event is PointerHoverEvent) {
      _setLinkHover(linkId);
    }
  }

  void _handlePortHover((String, String) portLocator) {
    if (lastHoveredPortLocator != portLocator) {
      _clearPortHover();
      _setPortHover(portLocator);
    }
  }

  void _setLinkHover(String linkId) {
    if (lastHoveredLinkId != linkId) {
      _clearLinkHover();

      _controller.linksById[linkId]!.state.isHovered = true;
      _controller.linksDataDirty = true;
      lastHoveredLinkId = linkId;

      markNeedsPaint();
    }
  }

  void _clearLinkHover() {
    if (lastHoveredLinkId != null &&
        _controller.linksById.containsKey(lastHoveredLinkId!)) {
      _controller.linksById[lastHoveredLinkId!]!.state.isHovered = false;
      _controller.linksDataDirty = true;
      lastHoveredLinkId = null;

      markNeedsPaint();
    }
  }

  void _setPortHover((String, String) portLocator) {
    _controller.nodes[portLocator.$1]!.ports[portLocator.$2]!.state.isHovered =
        true;
    _controller.nodesDataDirty = true;
    lastHoveredPortLocator = portLocator;

    markNeedsPaint();
  }

  void _clearPortHover() {
    if (lastHoveredPortLocator != null) {
      _controller.nodes[lastHoveredPortLocator!.$1]!
          .ports[lastHoveredPortLocator!.$2]!.state.isHovered = false;
      _controller.nodesDataDirty = true;
      lastHoveredPortLocator = null;

      markNeedsPaint();
    }
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    super.handleEvent(event, entry);

    final Offset centeredPosition =
        event.localPosition - Offset(size.width / 2, size.height / 2);
    final Offset scaledPosition = centeredPosition.scale(1 / _zoom, 1 / _zoom);
    final Offset transformedPosition = scaledPosition - _offset;

    if (event is PointerDownEvent && event.buttons == kMiddleMouseButton) {
      return;
    }

    final Rect checkRect = Rect.fromCircle(
      center: transformedPosition,
      radius: 6.0,
    );

    // Test ports first (higher priority), then links
    if (!hitTestPorts(transformedPosition, checkRect, event)) {
      hitTestLinks(transformedPosition, checkRect, event);
    }
  }

  //////////////////////////////////////////////////////////////////
  /// Misc methods
  //////////////////////////////////////////////////////////////////

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => false;
}
