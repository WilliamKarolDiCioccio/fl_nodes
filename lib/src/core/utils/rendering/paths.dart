import 'package:flutter/material.dart';

double distanceToBezier(
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
      final pointOnCurve = metric.getTangentForOffset(t * pathLength)!.position;
      final distance = (point - pointOnCurve).distance;
      minDistance = distance < minDistance ? distance : minDistance;
    }
  }

  return minDistance;
}

double distanceToStraightLine(
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
  final t = (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) /
      lineLengthSquared;
  final clampedT = t.clamp(0.0, 1.0); // Clamp to line segment

  final closestPoint = outPortOffset + lineVector * clampedT;
  return (point - closestPoint).distance;
}

double distanceToNinetyDegrees(
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
