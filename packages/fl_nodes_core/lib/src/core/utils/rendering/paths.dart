import 'package:flutter/material.dart';

import '../../models/paint.dart';

/// Utility class for working with paths in the node editor.
final class PathUtils {
  static double distanceToBezier(
    Offset point,
    Offset outPortOffset,
    Offset inPortOffset,
  ) {
    final midX = (outPortOffset.dx + inPortOffset.dx) / 2;

    // Define the cubic Bezier curve
    final curve = Path()
      ..moveTo(outPortOffset.dx, outPortOffset.dy)
      ..cubicTo(
        midX,
        outPortOffset.dy,
        midX,
        inPortOffset.dy,
        inPortOffset.dx,
        inPortOffset.dy,
      );

    // Approximate the curve with PathMetric
    final metrics = curve.computeMetrics();
    double minDistance = double.infinity;

    for (final metric in metrics) {
      final pathLength = metric.length;
      const int segments = 100;
      for (int i = 0; i <= segments; i++) {
        final t = i / segments;
        final pointOnCurve =
            metric.getTangentForOffset(t * pathLength)!.position;
        final distance = (point - pointOnCurve).distance;
        minDistance = distance < minDistance ? distance : minDistance;
      }
    }

    return minDistance;
  }

  static double distanceToStraightLine(
    Offset point,
    Offset outPortOffset,
    Offset inPortOffset,
  ) {
    final lineVector = inPortOffset - outPortOffset;
    final pointVector = point - outPortOffset;

    final lineLengthSquared =
        lineVector.dx * lineVector.dx + lineVector.dy * lineVector.dy;

    if (lineLengthSquared == 0) {
      // Line is a single point
      return (point - outPortOffset).distance;
    }

    // Project pointVector onto lineVector to find the projection's scale
    final t =
        (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) /
            lineLengthSquared;
    final clampedT = t.clamp(0.0, 1.0); // Clamp to line segment

    final closestPoint = outPortOffset + lineVector * clampedT;
    return (point - closestPoint).distance;
  }

  static double distanceToNinetyDegrees(
    Offset point,
    Offset outPortOffset,
    Offset inPortOffset,
  ) {
    final midX = (outPortOffset.dx + inPortOffset.dx) / 2;

    // Segment 1: Horizontal line from outPortOffset to (midX, outPortOffset.dy)
    final distanceToFirstSegment = distanceToStraightLine(
      point,
      outPortOffset,
      Offset(midX, outPortOffset.dy),
    );

    // Segment 2: Vertical line from (midX, outPortOffset.dy) to (midX, inPortOffset.dy)
    final distanceToSecondSegment = distanceToStraightLine(
      point,
      Offset(midX, outPortOffset.dy),
      Offset(midX, inPortOffset.dy),
    );

    // Segment 3: Horizontal line from (midX, inPortOffset.dy) to inPortOffset
    final distanceToThirdSegment = distanceToStraightLine(
      point,
      Offset(midX, inPortOffset.dy),
      inPortOffset,
    );

    return [
      distanceToFirstSegment,
      distanceToSecondSegment,
      distanceToThirdSegment,
    ].reduce((a, b) => a < b ? a : b); // Return the smallest distance
  }

  static Path computeBezierLinkPath(LinkPaintModel data) {
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

  static Path computeStraightLinkPath(LinkPaintModel data) {
    return Path()
      ..moveTo(data.outPortOffset.dx, data.outPortOffset.dy)
      ..lineTo(data.inPortOffset.dx, data.inPortOffset.dy);
  }

  static Path computeNinetyDegreesLinkPath(LinkPaintModel data) {
    final midX = (data.outPortOffset.dx + data.inPortOffset.dx) / 2;

    return Path()
      ..moveTo(data.outPortOffset.dx, data.outPortOffset.dy)
      ..lineTo(midX, data.outPortOffset.dy)
      ..lineTo(midX, data.inPortOffset.dy)
      ..lineTo(data.inPortOffset.dx, data.inPortOffset.dy);
  }

  static Path computeCirclePortPath(PortPaintModel data) {
    return Path()
      ..addOval(
        Rect.fromCircle(
          center: data.offset,
          radius: data.style.radius,
        ),
      );
  }

  static Path computeTrianglePortPath(PortPaintModel data) {
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
}
