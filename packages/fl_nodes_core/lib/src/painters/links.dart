import 'dart:ui';

import 'package:fl_nodes_core/src/core/utils/rendering/paths.dart';
import 'package:fl_nodes_core/src/painters/custom_painter.dart';
import 'package:fl_nodes_core/src/styles/styles.dart';

class LinksCustomPainter extends FlCustomPainter {
  final List<(Path, Paint)> _unbatchableLinks = [];
  final Map<FlLinkStyle, (Path, Paint)> _solidColorLinkBatches = {};

  final List<(String, Path)> linksHitTestData = [];

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

      for (final link in controller.links.values) {
        final outNode = controller.getNodeById(link.fromTo.from)!;
        final inNode = controller.getNodeById(link.fromTo.fromPort)!;
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

          linksHitTestData.add((data.id, path));

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

          linksHitTestData.add((data.id, path));

          _solidColorLinkBatches[style]!.$1.addPath(path, Offset.zero);
        }
      }
    }

    for (final (path, paint) in _unbatchableLinks) {
      canvas.drawPath(path, paint);
    }

    for (final entry in _solidColorLinkBatches.entries) {
      final (path, paint) = entry.value;
      canvas.drawPath(path, paint);
    }
  }
}
