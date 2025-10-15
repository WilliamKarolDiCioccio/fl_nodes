import 'package:flutter/material.dart';

import 'package:fl_nodes_core/src/core/utils/rendering/paths.dart';
import 'package:fl_nodes_core/src/painters/custom_painter.dart';
import 'package:fl_nodes_core/src/styles/styles.dart';

class LinksCustomPainter extends FlCustomPainter {
  final List<(Path, Paint)> _unbatchableLinks = [];
  final Map<FlLinkStyle, (Path, Paint)> _solidColorLinkBatches = {};

  final Map<String, (Rect, Path)> linksHitTestData = {};

  // Map to cache text painters for link labels
  final Map<String, TextPainter> _labelTextPainters = {};

  LinksCustomPainter(super.controller);

  @override
  void paint(Canvas canvas, Rect viewport,
      {bool transformChanged = false, bool portsChanged = false}) {
    // Here we collect data also for ports and children to avoid multiple loops

    if (controller.linksDataDirty ||
        controller.nodesDataDirty ||
        transformChanged ||
        portsChanged) {
      final Set<LinkPaintModel> linkData = {};

      // We cannot just reset the paths because the link styles are stateful that change hash code
      _unbatchableLinks.clear();
      _solidColorLinkBatches.clear();
      linksHitTestData.clear();
      _labelTextPainters.clear();

      for (final link in controller.links.values) {
        final outNode = controller.getNodeById(link.ports.from.nodeId)!;
        final inNode = controller.getNodeById(link.ports.to.nodeId)!;
        final outPort = outNode.ports[link.ports.from.portId]!;
        final inPort = inNode.ports[link.ports.to.portId]!;

        final Rect pathBounds = Rect.fromPoints(
          outNode.offset + outPort.offset,
          inNode.offset + inPort.offset,
        );

        if (!viewport.overlaps(pathBounds)) continue;

        linkData.add(
          LinkPaintModel(
            id: link.id,
            outPortOffset: outNode.offset + outPort.offset,
            inPortOffset: inNode.offset + inPort.offset,
            linkStyle: outPort.style.linkStyleBuilder(link.state),
          ),
        );
      }

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

          linksHitTestData[data.id] = (path.getBounds(), path);

          _cacheTextPainter(data.id);

          final shader = data.linkStyle.gradient!.createShader(
            Rect.fromPoints(data.outPortOffset, data.inPortOffset),
          );

          final Paint paint = Paint()
            ..shader = shader
            ..style = PaintingStyle.stroke
            ..strokeWidth = data.linkStyle.lineWidth;

          _unbatchableLinks.add((path, paint));
        } else {
          final style = data.linkStyle;
          _solidColorLinkBatches.putIfAbsent(style, () {
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

          linksHitTestData[data.id] = (path.getBounds(), path);

          _cacheTextPainter(data.id);

          _solidColorLinkBatches[style]!.$1.addPath(path, Offset.zero);
        }
      }
    }

    canvas.saveLayer(viewport, Paint());

    for (final (path, paint) in _unbatchableLinks) {
      canvas.drawPath(path, paint);
    }

    for (final entry in _solidColorLinkBatches.entries) {
      final (path, paint) = entry.value;
      canvas.drawPath(path, paint);
    }

    _drawLinkLabels(canvas);

    canvas.restore();
  }

  void _cacheTextPainter(String linkId) {
    final link = controller.links[linkId];

    if (link == null) return;

    final outNode = controller.getNodeById(link.ports.from.nodeId);
    final outPort = outNode?.ports[link.ports.from.portId];

    final String labelText = outPort?.prototype.linkPrototype
            .label(controller.editorKey.currentContext!) ??
        '';

    if (labelText.isEmpty) return;

    final textSpan = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    _labelTextPainters[linkId] = textPainter;
  }

  void _drawLinkLabels(Canvas canvas) {
    for (final entry in linksHitTestData.entries) {
      final id = entry.key;
      final pathData = entry.value.$1;

      // Defensive: skip invalid link bounds
      if (pathData.isEmpty) continue;

      final textPainter = _labelTextPainters[id];
      if (textPainter == null) continue;

      final controllerLink = controller.links[id];
      if (controllerLink == null) continue;

      final fromNode = controller.getNodeById(controllerLink.ports.from.nodeId);
      final toNode = controller.getNodeById(controllerLink.ports.to.nodeId);
      if (fromNode == null || toNode == null) continue;

      final fromNodeBounds = fromNode.cachedRenderboxRect;
      final toNodeBounds = toNode.cachedRenderboxRect;

      // Compute center safely
      final center = pathData.center;

      // Margin around nodes & label
      const margin = 8.0;

      // Define the rect that the label would occupy (with margin)
      final textRect = Rect.fromCenter(
        center: center,
        width: textPainter.width + margin,
        height: textPainter.height + margin,
      );

      // Detect overlap with either node
      final overlapsNode = fromNodeBounds.inflate(margin).overlaps(textRect) ||
          toNodeBounds.inflate(margin).overlaps(textRect);

      if (overlapsNode) {
        // Optionally skip or adjust position (depending on desired behavior)
        continue;
      }

      // Offset to center text at path center
      final offset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      // Slight padding for the clear rect
      const padding = 4.0;
      final labelRect = Rect.fromLTWH(
        offset.dx - padding,
        offset.dy - padding,
        textPainter.width + padding * 2,
        textPainter.height + padding * 2,
      );

      // Clear underlying link segment for better readability
      final clearPaint = Paint()..blendMode = BlendMode.clear;

      canvas.drawRect(labelRect, clearPaint);
      textPainter.paint(canvas, offset);
    }
  }

  // Helper method to get the bounding rect center position for a link path
  Offset? getLinkLabelCenter(String linkId) {
    final pathData = linksHitTestData[linkId]!.$1;
    return pathData.center;
  }
}
