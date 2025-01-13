import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:tuple/tuple.dart';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/utils/grid_drawing.dart';
import 'package:fl_nodes/src/widgets/node.dart';

class NodeParentData extends ContainerBoxParentData<RenderBox> {
  Offset nodeOffset = Offset.zero;
}

class NodeEditorRenderWidget extends MultiChildRenderObjectWidget {
  final FlNodeEditorController controller;
  final NodeEditorBehavior behavior;
  final NodeEditorStyle style;

  NodeEditorRenderWidget({
    super.key,
    required this.controller,
    required this.style,
  })  : behavior = controller.behavior,
        super(
          children: controller.nodesAsList
              .map(
                (node) => NodeWidget(
                  node: node,
                  controller: controller,
                ),
              )
              .toList(),
        );

  @override
  NodeEditorRenderBox createRenderObject(BuildContext context) {
    return NodeEditorRenderBox(
      style: style,
      behavior: behavior,
      offset: controller.viewportOffset,
      zoom: controller.viewportZoom,
      tempLink: controller.renderTempLink,
      selectionArea: controller.selectionArea,
      nodePositions: controller.nodesAsList.map((node) => node.offset).toList(),
      linkPositions: _getLinkPositions(),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    NodeEditorRenderBox renderObject,
  ) {
    renderObject
      ..offset = controller.viewportOffset
      ..zoom = controller.viewportZoom
      ..tempLink = controller.renderTempLink
      ..selectionArea = controller.selectionArea
      ..updateNodePositions(
        controller.nodesAsList.map((n) => n.offset).toList(),
      )
      ..linkPositions = _getLinkPositions();
  }

  List<Tuple2<Offset, Offset>> _getLinkPositions() {
    return controller.renderLinksAsList.map((link) {
      final outNodeOffset = controller.nodes[link.fromTo.item1]!.offset;
      final inNodeOffset = controller.nodes[link.fromTo.item3]!.offset;

      final outPortRelativeOffset =
          controller.nodes[link.fromTo.item1]!.ports[link.fromTo.item2]!.offset;
      final inPortRelativeOffset =
          controller.nodes[link.fromTo.item3]!.ports[link.fromTo.item4]!.offset;

      return Tuple2(
        outNodeOffset + outPortRelativeOffset,
        inNodeOffset + inPortRelativeOffset,
      );
    }).toList();
  }
}

class NodeEditorRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeParentData> {
  NodeEditorRenderBox({
    required NodeEditorStyle style,
    required NodeEditorBehavior behavior,
    required Offset offset,
    required double zoom,
    required Tuple2<Offset, Offset>? tempLink,
    required Rect selectionArea,
    required List<Offset> nodePositions,
    required List<Tuple2<Offset, Offset>> linkPositions,
  })  : _style = style,
        _behavior = behavior,
        _offset = offset,
        _zoom = zoom,
        _tempLink = tempLink,
        _selectionArea = selectionArea,
        _linkPositions = linkPositions {
    _updateNodePositions(nodePositions);
  }

  NodeEditorBehavior _behavior;
  NodeEditorBehavior get behavior => _behavior;
  set behavior(NodeEditorBehavior value) {
    if (_behavior == value) return;
    _behavior = value;
    markNeedsPaint();
  }

  NodeEditorStyle _style;
  NodeEditorStyle get style => _style;
  set style(NodeEditorStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsPaint();
  }

  double _zoom;
  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom == value) return;
    _zoom = value;
    markNeedsPaint();
    markNeedsLayout();
  }

  Rect _selectionArea;
  Rect get selectionArea => _selectionArea;
  set selectionArea(Rect value) {
    if (_selectionArea == value) return;
    _selectionArea = value;
    markNeedsPaint();
  }

  Tuple2<Offset, Offset>? _tempLink;
  Tuple2<Offset, Offset>? get tempLink => _tempLink;
  set tempLink(Tuple2<Offset, Offset>? value) {
    if (_tempLink == value) return;
    _tempLink = value;
    markNeedsPaint();
  }

  List<Tuple2<Offset, Offset>> _linkPositions;
  List<Tuple2<Offset, Offset>> get linkPositions => _linkPositions;
  set linkPositions(List<Tuple2<Offset, Offset>> value) {
    if (_linkPositions == value) return;
    _linkPositions = value;
    markNeedsPaint();
  }

  List<Offset> _nodePositions = [];

  void updateNodePositions(List<Offset> newNodePositions) {
    if (_areNodePositionsEqual(newNodePositions)) return;
    _updateNodePositions(newNodePositions);
    markNeedsLayout();
  }

  void _updateNodePositions(List<Offset> positions) {
    _nodePositions = positions;

    RenderBox? child = firstChild;
    int index = 0;

    while (child != null && index < positions.length) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;
      childParentData.nodeOffset = positions[index];
      child = childParentData.nextSibling;
      index++;
    }
  }

  bool _areNodePositionsEqual(List<Offset> newPositions) {
    if (childCount != newPositions.length) {
      return false;
    }

    RenderBox? child = firstChild;
    int index = 0;

    while (child != null && index < newPositions.length) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;
      if (childParentData.nodeOffset != newPositions[index]) {
        return false;
      }
      child = childParentData.nextSibling;
      index++;
    }

    return true;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeParentData) {
      child.parentData = NodeParentData();
    }
  }

  @override
  void insert(RenderBox child, {RenderBox? after}) {
    setupParentData(child);
    super.insert(child, after: after);
    final index = indexOf(child);
    if (index >= 0 && index < _nodePositions.length) {
      (child.parentData as NodeParentData).nodeOffset = _nodePositions[index];
    }
  }

  int indexOf(RenderBox child) {
    int index = 0;
    RenderBox? current = firstChild;

    while (current != null) {
      if (current == child) return index;
      current = childAfter(current);
      index++;
    }

    return -1;
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    RenderBox? child = firstChild;
    while (child != null) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;

      child.layout(
        BoxConstraints.loose(constraints.biggest),
        parentUsesSize: true,
      );

      childParentData.offset = childParentData.nodeOffset;

      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    canvas.save();

    final (viewport, startX, startY) = _prepareCanvas(canvas, size);

    if (style.gridStyle.showGrid) {
      drawGrid(style.gridStyle, canvas, viewport, startX, startY);
    }

    _paintLinks(canvas);
    _paintTemporaryLink(canvas);

    RenderBox? child = firstChild;
    while (child != null) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;

      if (!Rect.fromLTWH(
        childParentData.nodeOffset.dx,
        childParentData.nodeOffset.dy,
        child.size.width,
        child.size.height,
      ).overlaps(viewport)) {
        child = childParentData.nextSibling;
        continue;
      }

      final Offset nodeOffset = childParentData.nodeOffset;
      context.paintChild(child, nodeOffset);

      child = childParentData.nextSibling;
    }

    if (!selectionArea.isEmpty) {
      _paintSelectionArea(canvas, viewport);
    }

    if (kDebugMode) {
      paintDebugViewport(canvas, viewport);
      paintDebugOffset(canvas, size);
    }

    context.canvas.restore();
  }

  (Rect, double, double) _prepareCanvas(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoom);
    canvas.translate(offset.dx, offset.dy);

    final viewport = _calculateViewport(canvas, size);
    final startX = _calculateStart(viewport.left, style.gridStyle.gridSpacingX);
    final startY = _calculateStart(viewport.top, style.gridStyle.gridSpacingY);

    canvas.clipRect(
      viewport,
      clipOp: ui.ClipOp.intersect,
      doAntiAlias: false,
    );

    return (viewport, startX, startY);
  }

  Rect _calculateViewport(Canvas canvas, Size size) {
    final viewport = Rect.fromLTWH(
      -size.width / 2 / zoom - _offset.dx,
      -size.height / 2 / zoom - _offset.dy,
      size.width / zoom,
      size.height / zoom,
    );

    return viewport;
  }

  @visibleForTesting
  void paintDebugViewport(Canvas canvas, Rect viewport) {
    final Paint debugPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    // Draw the viewport rect
    canvas.drawRect(viewport, debugPaint);
  }

  void _paintLinks(Canvas canvas) {
    void paintLinksAsBeziers(Canvas canvas) {
      for (final link in linkPositions) {
        final outPortOffset = link.item1;
        final inPortOffset = link.item2;
        _paintBezierLink(canvas, outPortOffset, inPortOffset);
      }
    }

    void paintLinksAsStraights(Canvas canvas) {
      for (final link in linkPositions) {
        final outPortOffset = link.item1;
        final inPortOffset = link.item2;
        _paintStraightLink(canvas, outPortOffset, inPortOffset);
      }
    }

    void paintLinksAsNinetyDegrees(Canvas canvas) {
      for (final link in linkPositions) {
        final outPortOffset = link.item1;
        final inPortOffset = link.item2;
        _paintNinetyDegreesLink(canvas, outPortOffset, inPortOffset);
      }
    }

    switch (style.linkCurveType) {
      case LinkCurveType.straight:
        paintLinksAsStraights(canvas);
        break;
      case LinkCurveType.bezier:
        paintLinksAsBeziers(canvas);
        break;
      case LinkCurveType.ninetyDegree:
        paintLinksAsNinetyDegrees(canvas);
        break;
    }
  }

  void _paintBezierLink(
    Canvas canvas,
    Offset inPortOffset,
    Offset outPortOffset,
  ) {
    final path = Path()..moveTo(outPortOffset.dx, outPortOffset.dy);
    final midX = (outPortOffset.dx + inPortOffset.dx) / 2;

    path.cubicTo(
      midX,
      outPortOffset.dy,
      midX,
      inPortOffset.dy,
      inPortOffset.dx,
      inPortOffset.dy,
    );

    final gradient = LinearGradient(
      colors: [Colors.green[300]!, Colors.purple[200]!],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final uRect = Rect.fromPoints(outPortOffset, inPortOffset);
    if (uRect.width * uRect.height == 0) return;

    final defaultShader = gradient.createShader(uRect);

    final Paint gradientPaint = Paint()
      ..shader = defaultShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(path, gradientPaint);
  }

  void _paintStraightLink(
    Canvas canvas,
    Offset outPortOffset,
    Offset inPortOffset,
  ) {
    final gradient = LinearGradient(
      colors: [Colors.green[300]!, Colors.purple[200]!],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final shader = gradient.createShader(
      Rect.fromPoints(outPortOffset, inPortOffset),
    );

    final Paint gradientPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(outPortOffset, inPortOffset, gradientPaint);
  }

  void _paintNinetyDegreesLink(
    Canvas canvas,
    Offset outPortOffset,
    Offset inPortOffset,
  ) {
    final gradient = LinearGradient(
      colors: [Colors.green[300]!, Colors.purple[200]!],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final shader = gradient.createShader(
      Rect.fromPoints(outPortOffset, inPortOffset),
    );

    final Paint gradientPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final midX = (outPortOffset.dx + inPortOffset.dx) / 2;

    final path = Path()
      ..moveTo(outPortOffset.dx, outPortOffset.dy)
      ..lineTo(midX, outPortOffset.dy)
      ..lineTo(midX, inPortOffset.dy)
      ..lineTo(inPortOffset.dx, inPortOffset.dy);

    canvas.drawPath(path, gradientPaint);
  }

  void _paintTemporaryLink(Canvas canvas) {
    if (tempLink == null) return;

    final outPortOffset = tempLink!.item1;
    final inPortOffset = tempLink!.item2;

    switch (style.linkCurveType) {
      case LinkCurveType.straight:
        _paintStraightLink(canvas, outPortOffset, inPortOffset);
        break;
      case LinkCurveType.bezier:
        _paintBezierLink(canvas, outPortOffset, inPortOffset);
        break;
      case LinkCurveType.ninetyDegree:
        _paintNinetyDegreesLink(canvas, outPortOffset, inPortOffset);
        break;
    }
  }

  void _paintSelectionArea(Canvas canvas, Rect viewport) {
    final Paint selectionPaint = Paint()
      ..color = Colors.blue.withAlpha(50)
      ..style = PaintingStyle.fill;

    canvas.drawRect(selectionArea, selectionPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRect(selectionArea, borderPaint);
  }

  @visibleForTesting
  void paintDebugOffset(Canvas canvas, Size size) {
    final Paint debugPaint = Paint()
      ..color = Colors.green.withAlpha(200)
      ..style = PaintingStyle.fill;

    // Draw the offset point
    canvas.drawCircle(Offset.zero, 5, debugPaint);
  }

  double _calculateStart(double viewportEdge, double gridSpacing) {
    return (viewportEdge / gridSpacing).floor() * gridSpacing;
  }

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final transformedPosition =
        (position - Offset(size.width / 2, size.height / 2))
                .scale(1 / zoom, 1 / zoom) -
            _offset;

    RenderBox? child = lastChild;
    while (child != null) {
      final NodeParentData childParentData =
          child.parentData! as NodeParentData;

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.nodeOffset,
        position: transformedPosition,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );

      if (isHit) {
        return true;
      }

      child = childParentData.previousSibling;
    }

    return false;
  }
}
