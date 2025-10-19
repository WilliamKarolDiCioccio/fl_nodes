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
  void paint(
    Canvas canvas,
    Rect viewport, {
    bool transformChanged = false,
    bool portsChanged = false,
  }) {
    final shouldDrawLabels = controller.lodLevel >= 3;

    if (controller.linksDataDirty ||
        controller.nodesDataDirty ||
        transformChanged ||
        portsChanged) {
      final List<LinkPaintModel> linkDrawData = [];

      _unbatchableLinks.clear();
      _solidColorLinkBatches.clear();
      linksHitTestData.clear();

      if (controller.linksDataDirty) {
        _labelTextPainters.clear();
      }

      for (final link in controller.links.values) {
        final outNode = controller.getNodeById(link.ports.from.nodeId);
        final inNode = controller.getNodeById(link.ports.to.nodeId);
        if (outNode == null || inNode == null) continue;

        final outPort = outNode.ports[link.ports.from.portId];
        final inPort = inNode.ports[link.ports.to.portId];
        if (outPort == null || inPort == null) continue;

        final outPortOffset = outNode.offset + outPort.offset;
        final inPortOffset = inNode.offset + inPort.offset;
        final outPortGeometricOrientation =
            outPort.prototype.geometricOrientation;
        final inPortGeometricOrientation =
            inPort.prototype.geometricOrientation;

        final Rect pathBounds = Rect.fromPoints(outPortOffset, inPortOffset);

        if (!viewport.overlaps(pathBounds)) continue;

        final linkStyle = outPort.style.linkStyleBuilder(link.state);

        String? labelText;
        Rect? fromNodeBounds;
        Rect? toNodeBounds;

        if (shouldDrawLabels) {
          labelText = outPort.prototype.linkPrototype
              .label(controller.editorKey.currentContext!);

          if (labelText.isNotEmpty) {
            fromNodeBounds = outNode.cachedRenderboxRect;
            toNodeBounds = inNode.cachedRenderboxRect;
          }
        }

        linkDrawData.add(LinkPaintModel(
          linkId: link.id,
          outPortOffset: outPortOffset,
          inPortOffset: inPortOffset,
          outPortGeometricOrientation: outPortGeometricOrientation,
          inPortGeometricOrientation: inPortGeometricOrientation,
          linkStyle: linkStyle,
          labelText: labelText,
          fromNodeBounds: fromNodeBounds,
          toNodeBounds: toNodeBounds,
        ));
      }

      for (final data in linkDrawData) {
        final path = _computeLinkPath(data.linkStyle.curveType, data);

        linksHitTestData[data.linkId] = (path.getBounds(), path);

        if (data.linkStyle.gradient != null) {
          final shader = data.linkStyle.gradient!.createShader(
            Rect.fromPoints(data.outPortOffset, data.inPortOffset),
          );

          final Paint paint = Paint()
            ..shader = shader
            ..style = PaintingStyle.stroke
            ..strokeWidth = data.linkStyle.lineWidth;

          _unbatchableLinks.add((path, paint));

          if (shouldDrawLabels &&
              data.labelText != null &&
              data.labelText!.isNotEmpty) {
            _cacheTextPainter(data.linkId, data.labelText!);
          }
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

          _solidColorLinkBatches[style]!.$1.addPath(path, Offset.zero);

          if (shouldDrawLabels &&
              data.labelText != null &&
              data.labelText!.isNotEmpty) {
            _cacheTextPainter(data.linkId, data.labelText!);
          }
        }
      }
    }

    canvas.saveLayer(viewport, Paint());

    for (final entry in _solidColorLinkBatches.entries) {
      final (path, paint) = entry.value;
      canvas.drawPath(path, paint);
    }

    for (final (path, paint) in _unbatchableLinks) {
      canvas.drawPath(path, paint);
    }

    if (shouldDrawLabels) {
      _drawLinkLabels(canvas);
    }

    canvas.restore();
  }

  Path _computeLinkPath(FlLinkCurveType curveType, LinkPaintModel data) {
    return switch (curveType) {
      FlLinkCurveType.straight => PathUtils.computeStraightLinkPath(
          outPortOffset: data.outPortOffset,
          inPortOffset: data.inPortOffset,
        ),
      FlLinkCurveType.bezier => PathUtils.computeBezierLinkPath(
          outPortOffset: data.outPortOffset,
          inPortOffset: data.inPortOffset,
          outPortGeometricOrientation: data.outPortGeometricOrientation,
          inPortGeometricOrientation: data.inPortGeometricOrientation,
        ),
      FlLinkCurveType.ninetyDegree => PathUtils.computeNinetyDegreesLinkPath(
          outPortOffset: data.outPortOffset,
          inPortOffset: data.inPortOffset,
          outPortGeometricOrientation: data.outPortGeometricOrientation,
          inPortGeometricOrientation: data.inPortGeometricOrientation,
        ),
    };
  }

  void _cacheTextPainter(String linkId, String labelText) {
    if (_labelTextPainters.containsKey(linkId)) return;

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
    const margin = 8.0;
    const padding = 4.0;
    final clearPaint = Paint()..blendMode = BlendMode.clear;

    for (final entry in linksHitTestData.entries) {
      final id = entry.key;
      final pathData = entry.value.$1;

      final textPainter = _labelTextPainters[id];
      if (textPainter == null) continue;

      final controllerLink = controller.links[id];
      if (controllerLink == null) continue;

      final fromNode = controller.getNodeById(controllerLink.ports.from.nodeId);
      final toNode = controller.getNodeById(controllerLink.ports.to.nodeId);
      if (fromNode == null || toNode == null) continue;

      final fromNodeBounds = fromNode.cachedRenderboxRect;
      final toNodeBounds = toNode.cachedRenderboxRect;
      final center = pathData.center;

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
        continue;
      }

      // Offset to center text at path center
      final offset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      final labelRect = Rect.fromLTWH(
        offset.dx - padding,
        offset.dy - padding,
        textPainter.width + padding * 2,
        textPainter.height + padding * 2,
      );

      // Clear underlying link segment for better readability
      canvas.drawRect(labelRect, clearPaint);

      textPainter.paint(canvas, offset);
    }
  }

  Offset? getLinkLabelCenter(String linkId) {
    final pathData = linksHitTestData[linkId]?.$1;
    return pathData?.center;
  }
}
