import 'dart:ui';

import 'package:fl_nodes_core/src/core/utils/rendering/paths.dart';
import 'package:fl_nodes_core/src/painters/custom_painter.dart';
import 'package:fl_nodes_core/src/styles/styles.dart';

class TmpLinkCustomPainter extends FlCustomPainter {
  LinkPaintModel? tmpLinkData;

  TmpLinkCustomPainter(super.controller);

  @override
  void paint(Canvas canvas, Rect viewport) {
    if (tmpLinkData == null) return;

    late Path path;

    switch (tmpLinkData!.linkStyle.curveType) {
      case FlLinkCurveType.straight:
        path = PathUtils.computeStraightLinkPath(
          outPortOffset: tmpLinkData!.outPortOffset,
          inPortOffset: tmpLinkData!.inPortOffset,
        );
        break;
      case FlLinkCurveType.bezier:
        path = PathUtils.computeBezierLinkPath(
          outPortOffset: tmpLinkData!.outPortOffset,
          inPortOffset: tmpLinkData!.inPortOffset,
          outPortGeometricOrientation: tmpLinkData!.outPortGeometricOrientation,
          inPortGeometricOrientation: tmpLinkData!.inPortGeometricOrientation,
        );
        break;
      case FlLinkCurveType.ninetyDegree:
        path = PathUtils.computeNinetyDegreesLinkPath(
          outPortOffset: tmpLinkData!.outPortOffset,
          inPortOffset: tmpLinkData!.inPortOffset,
          outPortGeometricOrientation: tmpLinkData!.outPortGeometricOrientation,
          inPortGeometricOrientation: tmpLinkData!.inPortGeometricOrientation,
        );
        break;
    }

    final Paint paint = Paint();

    if (tmpLinkData!.linkStyle.gradient != null) {
      final shader = tmpLinkData!.linkStyle.gradient!.createShader(
        Rect.fromPoints(
          tmpLinkData!.outPortOffset,
          tmpLinkData!.inPortOffset,
        ),
      );

      paint
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = tmpLinkData!.linkStyle.lineWidth;
    } else {
      paint
        ..color = tmpLinkData!.linkStyle.color!
        ..style = PaintingStyle.stroke
        ..strokeWidth = tmpLinkData!.linkStyle.lineWidth;
    }

    canvas.drawPath(path, paint);
  }
}
