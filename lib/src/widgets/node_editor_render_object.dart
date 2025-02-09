import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:fl_nodes/src/core/controllers/node_editor/config.dart';
import 'package:fl_nodes/src/utils/grid_drawing.dart';
import 'package:fl_nodes/src/widgets/node.dart';

import '../core/controllers/node_editor/core.dart';
import '../core/models/entities.dart';
import '../core/models/styles.dart';

class NodeDrawData {
  Offset offset;
  NodeState state;

  NodeDrawData({
    required this.offset,
    required this.state,
  });
}

class LinkDrawData {
  final PortType portsType;
  final Offset outPortOffset;
  final Offset inPortOffset;

  LinkDrawData({
    required this.portsType,
    required this.outPortOffset,
    required this.inPortOffset,
  });
}

/// This extends the [ContainerBoxParentData] class from the Flutter framework
/// for the data to be passed down to children for layout and painting.
class _ParentData extends ContainerBoxParentData<RenderBox> {
  Offset nodeOffset = Offset.zero;
  NodeState state = NodeState();
}

class NodeEditorRenderObjectWidget extends MultiChildRenderObjectWidget {
  final FlNodeEditorController controller;
  final NodeEditorConfig behavior;
  final FlNodeEditorStyle style;

  NodeEditorRenderObjectWidget({
    super.key,
    required this.controller,
    required this.style,
  })  : behavior = controller.behavior,
        super(
          children: controller.nodesAsList
              .map(
                (node) => NodeWidget(
                  controller: controller,
                  node: node,
                  style: style.nodeStyle,
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
      tempLink: _getTempLinkData(),
      selectionArea: controller.selectionArea,
      nodesData: _getNodesData(),
      linksData: _getLinksData(),
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
      ..tempLinkDrawData = _getTempLinkData()
      ..selectionArea = controller.selectionArea
      ..shouldUpdateNodes(_getNodesData())
      ..linksData = _getLinksData();
  }

  List<NodeDrawData> _getNodesData() {
    return controller.nodesAsList
        .map(
          (node) => NodeDrawData(
            offset: node.offset,
            state: node.state,
          ),
        )
        .toList();
  }

  List<LinkDrawData> _getLinksData() {
    return controller.renderLinksAsList.map((link) {
      final nodes = controller.nodes;

      final outNode = nodes[link.fromTo.$1]!;
      final inNode = nodes[link.fromTo.$3]!;
      final outPort = outNode.ports[link.fromTo.$2]!;
      final inPort = inNode.ports[link.fromTo.$4]!;

      // NOTE: The port offset is relative to the node
      return LinkDrawData(
        portsType: outPort.prototype.type,
        outPortOffset: outNode.offset + outPort.offset,
        inPortOffset: inNode.offset + inPort.offset,
      );
    }).toList();
  }

  LinkDrawData? _getTempLinkData() {
    final tempLink = controller.renderTempLink;
    if (tempLink == null) return null;

    // NOTE: The port offset its fake, it's just the position of the mouse
    return LinkDrawData(
      portsType: controller.renderTempLink!.type,
      outPortOffset: controller.renderTempLink!.from,
      inPortOffset: controller.renderTempLink!.to,
    );
  }
}

class NodeEditorRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  NodeEditorRenderBox({
    required FlNodeEditorStyle style,
    required NodeEditorConfig behavior,
    required Offset offset,
    required double zoom,
    required LinkDrawData? tempLink,
    required Rect selectionArea,
    required List<NodeDrawData> nodesData,
    required List<LinkDrawData> linksData,
  })  : _style = style,
        _behavior = behavior,
        _offset = offset,
        _zoom = zoom,
        _tempLinkDrawData = tempLink,
        _selectionArea = selectionArea,
        _linksData = linksData {
    shouldUpdateNodes(nodesData);
  }

  NodeEditorConfig _behavior;
  NodeEditorConfig get behavior => _behavior;
  set behavior(NodeEditorConfig value) {
    if (_behavior == value) return;
    _behavior = value;
    markNeedsPaint();
  }

  FlNodeEditorStyle _style;
  FlNodeEditorStyle get style => _style;
  set style(FlNodeEditorStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  FlNodeStyle get nodeStyle => style.nodeStyle;
  FlPortStyle get portStyle => style.nodeStyle.portStyle;

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

  LinkDrawData? _tempLinkDrawData;
  LinkDrawData? get tempLinkDrawData => _tempLinkDrawData;
  set tempLinkDrawData(LinkDrawData? value) {
    if (_tempLinkDrawData == value) return;
    _tempLinkDrawData = value;
    markNeedsPaint();
  }

  List<LinkDrawData> _linksData;
  List<LinkDrawData> get linksData => _linksData;
  set linksData(List<LinkDrawData> value) {
    if (_linksData == value) return;
    _linksData = value;
    markNeedsPaint();
  }

  List<NodeDrawData> _nodesData = [];

  void shouldUpdateNodes(List<NodeDrawData> nodesData) {
    if (!_didNodesUpdate(nodesData)) {
      _updateNodes(nodesData);
      markNeedsLayout();
    }
  }

  void _updateNodes(List<NodeDrawData> nodesData) {
    _nodesData = nodesData;

    RenderBox? child = firstChild;
    int index = 0;

    while (child != null && index < nodesData.length) {
      final childParentData = child.parentData! as _ParentData;
      childParentData.offset = nodesData[index].offset;
      childParentData.state = NodeState(
        isSelected: nodesData[index].state.isSelected,
        isCollapsed: nodesData[index].state.isCollapsed,
      );
      child = childParentData.nextSibling;
      index++;
    }
  }

  bool _didNodesUpdate(List<NodeDrawData> nodesData) {
    if (childCount != nodesData.length) {
      return false;
    }

    RenderBox? child = firstChild;
    int index = 0;

    while (child != null && index < nodesData.length) {
      final childParentData = child.parentData! as _ParentData;

      if (childParentData.offset != nodesData[index].offset ||
          childParentData.state != nodesData[index].state) {
        return false;
      }
      child = childParentData.nextSibling;
      index++;
    }

    return true;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeDrawData) {
      child.parentData = _ParentData();
    }
  }

  @override
  void insert(RenderBox child, {RenderBox? after}) {
    setupParentData(child);
    super.insert(child, after: after);
    final index = indexOf(child);
    if (index >= 0 && index < _nodesData.length) {
      (child.parentData as _ParentData).offset = _nodesData[index].offset;
      (child.parentData as _ParentData).state = _nodesData[index].state;
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
      final childParentData = child.parentData! as _ParentData;

      child.layout(
        BoxConstraints.loose(constraints.biggest),
        parentUsesSize: true,
      );

      childParentData.offset = childParentData.offset;

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

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as _ParentData;

      if (!Rect.fromLTWH(
        childParentData.offset.dx,
        childParentData.offset.dy,
        child.size.width,
        child.size.height,
      ).overlaps(viewport)) {
        child = childParentData.nextSibling;
        continue;
      }

      // Drawing the shadow directly on the canvas is faster than using the shadow property
      final Paint shadowPaint = Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawRect(
        Rect.fromLTWH(
          childParentData.offset.dx,
          childParentData.offset.dy + 4,
          child.size.width,
          child.size.height,
        ),
        shadowPaint,
      );

      context.paintChild(child, childParentData.offset);

      child = childParentData.nextSibling;
    }

    // We paint this after the nodes so that the temporary link is always on top
    _paintTemporaryLink(canvas);

    // Same as above, we paint this after the nodes so that the selection area is always on top
    _paintSelectionArea(canvas, viewport);

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
    return Rect.fromLTWH(
      -size.width / 2 / zoom - _offset.dx,
      -size.height / 2 / zoom - _offset.dy,
      size.width / zoom,
      size.height / zoom,
    );
  }

  double _calculateStart(double viewportEdge, double gridSpacing) {
    return (viewportEdge / gridSpacing).floor() * gridSpacing;
  }

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

  void _paintLinks(Canvas canvas) {
    void paintLinksAsBeziers(Canvas canvas) {
      for (final linkDrawData in linksData) {
        _paintBezierLink(
          canvas,
          linkDrawData,
        );
      }
    }

    void paintLinksAsStraights(Canvas canvas) {
      for (final linkDrawData in linksData) {
        _paintStraightLink(
          canvas,
          linkDrawData,
        );
      }
    }

    void paintLinksAsNinetyDegrees(Canvas canvas) {
      for (final linkDrawData in linksData) {
        _paintNinetyDegreesLink(
          canvas,
          linkDrawData,
        );
      }
    }

    switch (style.nodeStyle.linkStyle.curveType) {
      case FlLinkCurveType.straight:
        paintLinksAsStraights(canvas);
        break;
      case FlLinkCurveType.bezier:
        paintLinksAsBeziers(canvas);
        break;
      case FlLinkCurveType.ninetyDegree:
        paintLinksAsNinetyDegrees(canvas);
        break;
    }
  }

  void _paintBezierLink(Canvas canvas, LinkDrawData drawData) {
    final path = Path()
      ..moveTo(
        drawData.outPortOffset.dx,
        drawData.outPortOffset.dy,
      );

    const double defaultOffset = 400.0;

    //  How far the bezier follows the horizontal direction before curving based on the distance between ports
    final dx = (drawData.inPortOffset.dx - drawData.outPortOffset.dx).abs();
    final controlOffset = dx < defaultOffset * 2 ? dx / 2 : defaultOffset;

    // First control point: a few pixels to the right of the output port.
    final cp1 = Offset(
      drawData.outPortOffset.dx + controlOffset,
      drawData.outPortOffset.dy,
    );

    // Second control point: a few pixels to the left of the input port.
    final cp2 = Offset(
      drawData.inPortOffset.dx - controlOffset,
      drawData.inPortOffset.dy,
    );

    path.cubicTo(
      cp1.dx,
      cp1.dy,
      cp2.dx,
      cp2.dy,
      drawData.inPortOffset.dx,
      drawData.inPortOffset.dy,
    );

    final gradient = LinearGradient(
      colors: [
        portStyle.color[drawData.portsType]![PortDirection.output]!,
        portStyle.color[drawData.portsType]![PortDirection.input]!,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final shader = gradient.createShader(
      Rect.fromPoints(drawData.outPortOffset, drawData.inPortOffset),
    );

    final Paint paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.nodeStyle.linkStyle.lineWidth;

    canvas.drawPath(path, paint);
  }

  void _paintStraightLink(
    Canvas canvas,
    LinkDrawData drawData,
  ) {
    final gradient = LinearGradient(
      colors: [
        portStyle.color[drawData.portsType]![PortDirection.output]!,
        portStyle.color[drawData.portsType]![PortDirection.input]!,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final shader = gradient.createShader(
      Rect.fromPoints(drawData.outPortOffset, drawData.inPortOffset),
    );

    final Paint gradientPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.nodeStyle.linkStyle.lineWidth;

    canvas.drawLine(
      drawData.outPortOffset,
      drawData.inPortOffset,
      gradientPaint,
    );
  }

  void _paintNinetyDegreesLink(
    Canvas canvas,
    LinkDrawData drawData,
  ) {
    final gradient = LinearGradient(
      colors: [
        portStyle.color[drawData.portsType]![PortDirection.output]!,
        portStyle.color[drawData.portsType]![PortDirection.input]!,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final shader = gradient.createShader(
      Rect.fromPoints(drawData.outPortOffset, drawData.inPortOffset),
    );

    final Paint gradientPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.nodeStyle.linkStyle.lineWidth;

    final midX = (drawData.outPortOffset.dx + drawData.inPortOffset.dx) / 2;

    final path = Path()
      ..moveTo(drawData.outPortOffset.dx, drawData.outPortOffset.dy)
      ..lineTo(midX, drawData.outPortOffset.dy)
      ..lineTo(midX, drawData.inPortOffset.dy)
      ..lineTo(drawData.inPortOffset.dx, drawData.inPortOffset.dy);

    canvas.drawPath(path, gradientPaint);
  }

  void _paintTemporaryLink(Canvas canvas) {
    if (_tempLinkDrawData == null) return;

    switch (style.nodeStyle.linkStyle.curveType) {
      case FlLinkCurveType.straight:
        _paintStraightLink(canvas, tempLinkDrawData!);
        break;
      case FlLinkCurveType.bezier:
        _paintBezierLink(canvas, tempLinkDrawData!);
        break;
      case FlLinkCurveType.ninetyDegree:
        _paintNinetyDegreesLink(canvas, tempLinkDrawData!);
        break;
    }
  }

  void _paintSelectionArea(Canvas canvas, Rect viewport) {
    if (selectionArea.isEmpty) return;

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
      final childParentData = child.parentData! as _ParentData;

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
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
