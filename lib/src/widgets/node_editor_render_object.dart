import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/controller/core.dart';
import '../core/models/entities.dart';
import '../core/models/styles.dart';
import 'builders.dart';
import 'default_node_widget.dart';

class NodeDiffCheckData {
  String id;
  Offset offset;
  NodeState state;

  NodeDiffCheckData({
    required this.id,
    required this.offset,
    required this.state,
  });
}

class LinkData {
  final String id;
  final Offset outPortOffset;
  final Offset inPortOffset;
  final FlLinkStyle linkStyle;

  LinkData({
    required this.id,
    required this.outPortOffset,
    required this.inPortOffset,
    required this.linkStyle,
  });
}

class PortData {
  final (String, String) locator;
  final bool isSelected;
  final Offset offset;
  final FlPortStyle style;

  PortData({
    required this.locator,
    required this.isSelected,
    required this.offset,
    required this.style,
  });
}

/// This extends the [ContainerBoxParentData] class from the Flutter framework
/// for the data to be passed down to children for layout and painting.
class _ParentData extends ContainerBoxParentData<RenderBox> {
  String id = '';
  Offset nodeOffset = Offset.zero;
  NodeState state = NodeState();

  // // // This is used to prevent unnecessary layout and painting of children
  // // bool hasBeenLaidOut = false;

  // This is used to avoid unnecessary recomputations of the renderbox rect
  Rect rect = Rect.zero;
}

class NodeEditorRenderObjectWidget extends MultiChildRenderObjectWidget {
  final FlNodeEditorController controller;
  final FlNodeEditorStyle style;
  final FragmentShader gridShader;
  final FlNodeHeaderBuilder? headerBuilder;
  final FlNodeFieldBuilder? fieldBuilder;
  final FlNodePortBuilder? portBuilder;
  final FlNodeContextMenuBuilder? contextMenuBuilder;
  final FlNodeBuilder? nodeBuilder;

  NodeEditorRenderObjectWidget({
    super.key,
    required this.controller,
    required this.style,
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
      style: style,
      gridShader: gridShader,
      offset: controller.viewportOffset,
      zoom: controller.viewportZoom,
      lodLevel: controller.lodLevel,
      tmpLinkDrawData: _getTmpLinkData(),
      selectionArea: controller.selectionArea,
      nodesData: _getNodeDrawData(),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    NodeEditorRenderBox renderObject,
  ) {
    renderObject
      ..style = style
      ..offset = controller.viewportOffset
      ..zoom = controller.viewportZoom
      ..lodLevel = controller.lodLevel
      ..tmpLinkDrawData = _getTmpLinkData()
      ..selectionArea = controller.selectionArea
      ..updateNodes(_getNodeDrawData());
  }

  List<NodeDiffCheckData> _getNodeDrawData() {
    return controller.nodesAsList
        .map(
          (node) => NodeDiffCheckData(
            id: node.id,
            offset: node.offset,
            state: node.state,
          ),
        )
        .toList();
  }

  LinkData? _getTmpLinkData() {
    if (controller.tempLink == null) return null;

    final link = controller.tempLink!;

    return LinkData(
      id: "", // Temporary link doesn't need an ID
      outPortOffset: link.from,
      inPortOffset: link.to,
      linkStyle: link.style,
    );
  }
}

class NodeEditorRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  NodeEditorRenderBox({
    required FlNodeEditorController controller,
    required FlNodeEditorStyle style,
    required FragmentShader gridShader,
    required Offset offset,
    required double zoom,
    required int lodLevel,
    required LinkData? tmpLinkDrawData,
    required Rect selectionArea,
    required List<NodeDiffCheckData> nodesData,
  })  : _controller = controller,
        _style = style,
        _gridShader = gridShader,
        _offset = offset,
        _zoom = zoom,
        _lodLevel = lodLevel,
        _tmpLinkData = tmpLinkDrawData,
        _selectionArea = selectionArea {
    _loadGridShader();
    updateNodes(nodesData);
  }

  final FlNodeEditorController _controller;
  final Map<String, RenderBox> _childrenById = {};

  // We keep track of the layout operation manually beacuse the hasSize getter
  // calls the size method which implementation causes assertions to be thrown.
  // See: https://api.flutter.dev/flutter/rendering/RenderBox/size.html
  final Map<String, RenderBox> _childrenNotLaidOut = {};

  FlNodeEditorStyle _style;
  FlNodeEditorStyle get style => _style;
  set style(FlNodeEditorStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  bool gridShaderStyleLoaded = false;
  FragmentShader _gridShader;
  FragmentShader get gridShader => _gridShader;
  set gridShader(FragmentShader value) {
    if (_gridShader == value) return;
    _gridShader = value;
    markNeedsPaint();
  }

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) return;
    _offset = value;
    _transformMatrixDirty = true;
    markNeedsPaint();
  }

  double _zoom;
  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom == value) return;
    _zoom = value;
    _transformMatrixDirty = true;
    markNeedsPaint();
  }

  int _lodLevel;
  int get lodLevel => _lodLevel;
  set lodLevel(int value) {
    if (_lodLevel == value) return;
    _lodLevel = value;
    markNeedsPaint();
  }

  Matrix4? _transformMatrix;
  bool _transformMatrixDirty = true;

  LinkData? _tmpLinkData;
  LinkData? get tmpLinkDrawData => _tmpLinkData;
  set tmpLinkDrawData(LinkData? value) {
    if (_tmpLinkData == value) return;
    _tmpLinkData = value;
    markNeedsPaint();
  }

  Rect _selectionArea;
  Rect get selectionArea => _selectionArea;
  set selectionArea(Rect value) {
    if (_selectionArea == value) return;
    _selectionArea = value;
    markNeedsPaint();
  }

  List<NodeDiffCheckData> _nodesDiffCheckData = [];
  List<NodeDiffCheckData> get nodesData => _nodesDiffCheckData;
  set nodesData(List<NodeDiffCheckData> value) {
    if (_nodesDiffCheckData == value) return;
    _nodesDiffCheckData = value;
    markNeedsLayout();
  }

  void _loadGridShader() {
    final gridStyle = style.gridStyle;

    gridShader.setFloat(0, gridStyle.gridSpacingX);
    gridShader.setFloat(1, gridStyle.gridSpacingY);

    final lineColor = gridStyle.lineColor;

    gridShader.setFloat(2, gridStyle.lineWidth);
    gridShader.setFloat(3, lineColor.r * lineColor.a);
    gridShader.setFloat(4, lineColor.g * lineColor.a);
    gridShader.setFloat(5, lineColor.b * lineColor.a);
    gridShader.setFloat(6, lineColor.a);

    final intersectionColor = gridStyle.intersectionColor;

    gridShader.setFloat(7, gridStyle.intersectionRadius);
    gridShader.setFloat(8, intersectionColor.r * intersectionColor.a);
    gridShader.setFloat(9, intersectionColor.g * intersectionColor.a);
    gridShader.setFloat(10, intersectionColor.b * intersectionColor.a);
    gridShader.setFloat(11, intersectionColor.a);
  }

  Set<String> visibleNodes = {};

  void updateNodes(List<NodeDiffCheckData> nodesData) {
    if (!_controller.nodesDataDirty) {
      markNeedsPaint();
      return;
    }

    _nodesDiffCheckData = nodesData;

    _childrenById.clear();

    RenderBox? child = firstChild;
    int index = 0;
    bool needsLayout = false;

    final nodesAsList = _controller.nodesAsList;

    while (child != null && index < nodesData.length) {
      final childParentData = child.parentData! as _ParentData;
      final nodeData = nodesData[index];

      if (childParentData.id != nodesAsList[index].id ||
          childParentData.offset != nodeData.offset ||
          childParentData.state.isCollapsed != nodeData.state.isCollapsed) {
        childParentData.id = nodesAsList[index].id;
        childParentData.offset = nodeData.offset;
        childParentData.state = nodeData.state;
        childParentData.rect = Rect.zero;

        _childrenNotLaidOut[childParentData.id] = child;

        needsLayout = true;
      }

      _childrenById[childParentData.id] = child;

      child = childParentData.nextSibling;
      index++;
    }

    if (needsLayout) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeDiffCheckData) {
      child.parentData = _ParentData();
    }
  }

  @override
  void insert(RenderBox child, {RenderBox? after}) {
    setupParentData(child);
    super.insert(child, after: after);

    final index = indexOf(child);
    final parentData = child.parentData as _ParentData;

    if (index >= 0 && index < _nodesDiffCheckData.length) {
      parentData.id = _nodesDiffCheckData[index].id;
      parentData.offset = _nodesDiffCheckData[index].offset;
      parentData.state = _nodesDiffCheckData[index].state;

      _childrenById[parentData.id] = child;
      _childrenNotLaidOut[parentData.id] = child;
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

    // If the child has not been laid out yet, we need to layout it.
    // Otherwise, we only need to layout it if it's within the viewport.

    final Set<String> nodesToLayout = Set<String>.from(
      _childrenNotLaidOut.keys,
    ).union(visibleNodes);

    for (final nodeId in nodesToLayout) {
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

      _controller.spatialHashGrid.update((id: nodeId, rect: renderBoxRect));
    }

    _childrenNotLaidOut.clear();

    // Here we should be updating the visibleNodes set with the nodes that are within the viewport.
    // This action is delayed until the paint method to ensure all layout operations are done.
  }

  Rect _calculateViewport() {
    return Rect.fromLTWH(
      -size.width / 2 / zoom - _offset.dx,
      -size.height / 2 / zoom - _offset.dy,
      size.width / zoom,
      size.height / zoom,
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

    visibleNodes = _controller.spatialHashGrid.queryArea(
      // Inflate the viewport to include nodes that are close to the edges
      viewport.inflate(300),
    );

    _paintGrid(context.canvas, viewport);

    _paintLinks(context.canvas, viewport);

    _paintChildren(context);

    _paintTemporaryLink(context.canvas);

    _paintSelectionArea(context.canvas, viewport);

    if (kDebugMode) {
      paintDebugViewport(context.canvas, viewport);
      paintDebugOffset(context.canvas, size);
    }

    _controller.nodesDataDirty = false;
    _controller.linksDataDirty = false;
    _transformMatrixDirty = false;
  }

  Matrix4 _getTransformMatrix() {
    if (_transformMatrix != null && !_transformMatrixDirty) {
      return _transformMatrix!;
    }

    _transformMatrix = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(zoom, zoom, 1.0)
      ..translate(offset.dx, offset.dy);

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
    if (!style.gridStyle.showGrid) return;

    gridShader.setFloat(12, viewport.left);
    gridShader.setFloat(13, viewport.top);
    gridShader.setFloat(14, viewport.right);
    gridShader.setFloat(15, viewport.bottom);

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
      final Set<LinkData> linkData = {};

      // We cannot just reset the paths because the link styles are stateful that change hash code
      _gradientLinks.clear();
      _solidColorsLinksBatches.clear();
      _linksHitTestData.clear();

      for (final link in _controller.linksById.values) {
        final outNode = _controller.nodes[link.fromTo.from]!;
        final inNode = _controller.nodes[link.fromTo.to]!;
        final outPort = outNode.ports[link.fromTo.fromPort]!;
        final inPort = inNode.ports[link.fromTo.toPort]!;

        final Rect pathBounds = Rect.fromPoints(
          outNode.offset + outPort.offset,
          inNode.offset + inPort.offset,
        );

        if (!viewport.overlaps(pathBounds)) continue;

        // NOTE: The port offset is relative to the node
        linkData.add(
          LinkData(
            id: link.id,
            outPortOffset: outNode.offset + outPort.offset,
            inPortOffset: inNode.offset + inPort.offset,
            linkStyle: outPort.prototype
                .styleBuilder(outPort.state)
                .linkStyleBuilder(link.state),
          ),
        );
      }

      // We don't draw the temporary link here because it should be on top of the nodes

      for (final data in linkData) {
        if (data.linkStyle.gradient != null) {
          late Path path;

          switch (data.linkStyle.curveType) {
            case FlLinkCurveType.straight:
              path = _computeStraightLinkPath(data);
              break;
            case FlLinkCurveType.bezier:
              path = _computeBezierLinkPath(data);
              break;
            case FlLinkCurveType.ninetyDegree:
              path = _computeNinetyDegreesLinkPath(data);
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
              path = _computeStraightLinkPath(data);
              break;
            case FlLinkCurveType.bezier:
              path = _computeBezierLinkPath(data);
              break;
            case FlLinkCurveType.ninetyDegree:
              path = _computeNinetyDegreesLinkPath(data);
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

      final Set<PortData> portData = {};

      for (final nodeId in visibleNodes) {
        final child = _childrenById[nodeId];

        final childParentData = child!.parentData as _ParentData;

        if (childParentData.state.isSelected) {
          selectedChildren.add(child);

          selectedShadowPath.addRRect(
            RRect.fromRectAndRadius(
              childParentData.rect.inflate(4),
              const Radius.circular(4),
            ),
          );

          for (final port in _controller.nodes[nodeId]!.ports.values) {
            portData.add(
              PortData(
                locator: (nodeId, port.prototype.idName),
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.prototype.styleBuilder(port.state),
              ),
            );
          }
        } else {
          unselectedChildren.add(child);

          unselectedShadowPath.addRRect(
            RRect.fromRectAndRadius(
              childParentData.rect.inflate(4),
              const Radius.circular(4),
            ),
          );

          for (final port in _controller.nodes[nodeId]!.ports.values) {
            portData.add(
              PortData(
                locator: (nodeId, port.prototype.idName),
                isSelected: childParentData.state.isSelected,
                offset: childParentData.offset + port.offset,
                style: port.prototype.styleBuilder(port.state),
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
            path = _batchPaintCirclePort(data);
            break;
          case FlPortShape.triangle:
            path = _batchPaintTrianglePort(data);
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
        path = _computeStraightLinkPath(_tmpLinkData!);
        break;
      case FlLinkCurveType.bezier:
        path = _computeBezierLinkPath(_tmpLinkData!);
        break;
      case FlLinkCurveType.ninetyDegree:
        path = _computeNinetyDegreesLinkPath(_tmpLinkData!);
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

  Path _computeBezierLinkPath(LinkData data) {
    final Path path = Path()
      ..moveTo(data.outPortOffset.dx, data.outPortOffset.dy);

    const double defaultOffset = 400.0;

    //  How far the bezier follows the horizontal direction before curving based on the distance between ports
    final dx = (data.inPortOffset.dx - data.outPortOffset.dx).abs();
    final controlOffset = dx < defaultOffset * 2 ? dx / 2 : defaultOffset;

    // First control point: a few pixels to the right of the output port.
    final cp1 = Offset(
      data.outPortOffset.dx + controlOffset,
      data.outPortOffset.dy,
    );

    // Second control point: a few pixels to the left of the input port.
    final cp2 = Offset(
      data.inPortOffset.dx - controlOffset,
      data.inPortOffset.dy,
    );

    path.cubicTo(
      cp1.dx,
      cp1.dy,
      cp2.dx,
      cp2.dy,
      data.inPortOffset.dx,
      data.inPortOffset.dy,
    );

    return path;
  }

  Path _computeStraightLinkPath(LinkData data) {
    return Path()
      ..moveTo(data.outPortOffset.dx, data.outPortOffset.dy)
      ..lineTo(data.inPortOffset.dx, data.inPortOffset.dy);
  }

  Path _computeNinetyDegreesLinkPath(LinkData data) {
    final midX = (data.outPortOffset.dx + data.inPortOffset.dx) / 2;

    return Path()
      ..moveTo(data.outPortOffset.dx, data.outPortOffset.dy)
      ..lineTo(midX, data.outPortOffset.dy)
      ..lineTo(midX, data.inPortOffset.dy)
      ..lineTo(data.inPortOffset.dx, data.inPortOffset.dy);
  }

  Path _batchPaintCirclePort(PortData data) {
    return Path()
      ..addOval(
        Rect.fromCircle(
          center: data.offset,
          radius: data.style.radius,
        ),
      );
  }

  Path _batchPaintTrianglePort(PortData data) {
    return Path()
      ..moveTo(
        data.offset.dx - data.style.radius,
        data.offset.dy - data.style.radius,
      ) // Top-left
      ..lineTo(
        data.offset.dx + data.style.radius,
        data.offset.dy,
      ) // Middle-right (apex)
      ..lineTo(
        data.offset.dx - data.style.radius,
        data.offset.dy + data.style.radius,
      ) // Bottom-left
      ..close();
  }

  void _paintSelectionArea(Canvas canvas, Rect viewport) {
    if (selectionArea.isEmpty) return;

    final style = _controller.style.selectionAreaStyle;

    final Paint selectionPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    canvas.drawRect(selectionArea, selectionPaint);

    final Paint borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(selectionArea, borderPaint);
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
    final Offset scaledPosition = centeredPosition.scale(1 / zoom, 1 / zoom);
    final Offset transformedPosition = scaledPosition - _offset;

    for (final nodeId in _controller.spatialHashGrid.queryCoords(
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

  String? lastHoveredLinkId;
  (String, String)? lastHoveredPortLocator;

  bool hitTestLinks(
    Offset transformedPosition,
    Rect checkRect,
    PointerEvent event,
  ) {
    if (event is! PointerDownEvent && event is! PointerHoverEvent) return false;

    final hitLinkId = _findHitLink(transformedPosition, checkRect);
    final isHit = hitLinkId != null;

    if (isHit) {
      _handleLinkHit(hitLinkId, event);
    } else if (event is PointerHoverEvent) {
      _clearLinkHover();
    }

    return isHit;
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
    if (lastHoveredLinkId != null) {
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
    final Offset scaledPosition = centeredPosition.scale(1 / zoom, 1 / zoom);
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
