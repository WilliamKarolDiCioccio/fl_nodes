import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_nodes_core/src/core/models/data.dart';
import 'package:fl_nodes_core/src/core/models/paint.dart';

// `abstract final class` is basically a namespace for static methods, and cannot be instantiated or extended.
// ignore: avoid_classes_with_only_static_members
/// Utility class for working with paths in the node editor.
abstract final class PathUtils {
  static double distanceToBezier({
    required Offset point,
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outOrientation,
    required FlPortGeometricOrientation inOrientation,
  }) {
    final Path curve = computeBezierLinkPath(
      outPortOffset: outPortOffset,
      inPortOffset: inPortOffset,
      outPortGeometricOrientation: outOrientation,
      inPortGeometricOrientation: inOrientation,
    );

    final PathMetrics metrics = curve.computeMetrics();
    double minDistance = double.infinity;

    for (final metric in metrics) {
      final double pathLength = metric.length;
      const int segments = 100;

      for (int i = 0; i <= segments; i++) {
        final double t = i / segments;
        final Offset pointOnCurve = metric.getTangentForOffset(t * pathLength)!.position;
        final double distance = (point - pointOnCurve).distance;

        minDistance = distance < minDistance ? distance : minDistance;
      }
    }

    return minDistance;
  }

  static double distanceToStraightLine({
    required Offset point,
    required Offset outPortOffset,
    required Offset inPortOffset,
  }) {
    final Offset lineVector = inPortOffset - outPortOffset;
    final Offset pointVector = point - outPortOffset;
    final double lineLengthSquared = lineVector.dx * lineVector.dx + lineVector.dy * lineVector.dy;

    // Line is a single point
    if (lineLengthSquared == 0) return (point - outPortOffset).distance;

    // Project pointVector onto lineVector to find the projection's scale
    final double t =
        (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) / lineLengthSquared;
    final double clampedT = t.clamp(0.0, 1.0); // Clamp to line segment

    final Offset closestPoint = outPortOffset + lineVector * clampedT;
    return (point - closestPoint).distance;
  }

  static double distanceToNinetyDegrees({
    required Offset point,
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outOrientation,
    required FlPortGeometricOrientation inOrientation,
  }) {
    final Path path = computeNinetyDegreesLinkPath(
      outPortOffset: outPortOffset,
      inPortOffset: inPortOffset,
      outPortGeometricOrientation: outOrientation,
      inPortGeometricOrientation: inOrientation,
    );

    final PathMetrics metrics = path.computeMetrics();
    double minDistance = double.infinity;

    for (final metric in metrics) {
      final double pathLength = metric.length;
      const int segments = 50; // Fewer segments needed for straight lines
      for (int i = 0; i <= segments; i++) {
        final double t = i / segments;
        final Offset pointOnPath = metric.getTangentForOffset(t * pathLength)!.position;
        final double distance = (point - pointOnPath).distance;

        minDistance = distance < minDistance ? distance : minDistance;
      }
    }

    return minDistance;
  }

  // Helper to get offset direction vector from orientation
  static Offset _getOrientationVector(FlPortGeometricOrientation orientation) =>
      switch (orientation) {
        FlPortGeometricOrientation.right => const Offset(1, 0),
        FlPortGeometricOrientation.left => const Offset(-1, 0),
        FlPortGeometricOrientation.top => const Offset(0, -1),
        FlPortGeometricOrientation.bottom => const Offset(0, 1),
      };

  static Path computeBezierLinkPath({
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outPortGeometricOrientation,
    required FlPortGeometricOrientation inPortGeometricOrientation,
  }) {
    final Path path = Path()..moveTo(outPortOffset.dx, outPortOffset.dy);

    const double defaultOffset = 400.0;
    const double minOffset = 50.0;

    final Offset outDir = _getOrientationVector(outPortGeometricOrientation);
    final Offset inDir = _getOrientationVector(inPortGeometricOrientation);

    // Calculate distance between ports
    final double distance = (inPortOffset - outPortOffset).distance;

    // Adaptive control offset based on distance and orientation
    final double baseControlOffset = distance < defaultOffset * 2
        ? (distance / 2).clamp(minOffset, defaultOffset)
        : defaultOffset;

    // Scale control offset based on whether we're going "against" the natural flow
    double outControlScale = 1.0;
    double inControlScale = 1.0;

    final bool facingEachOther = (outDir.dx * inDir.dx + outDir.dy * inDir.dy) < -0.5;

    // More pronounced curves for ports not facing each other
    if (!facingEachOther) {
      outControlScale = 1.5;
      inControlScale = 1.5;
    }

    // First control point: extends from output port in its orientation direction
    final cp1 = Offset(
      outPortOffset.dx + outDir.dx * baseControlOffset * outControlScale,
      outPortOffset.dy + outDir.dy * baseControlOffset * outControlScale,
    );

    // Second control point: extends from input port in its orientation direction (reversed)
    final cp2 = Offset(
      inPortOffset.dx + inDir.dx * baseControlOffset * inControlScale,
      inPortOffset.dy + inDir.dy * baseControlOffset * inControlScale,
    );

    path.cubicTo(
      cp1.dx,
      cp1.dy,
      cp2.dx,
      cp2.dy,
      inPortOffset.dx,
      inPortOffset.dy,
    );

    return path;
  }

  static Path computeStraightLinkPath({
    required Offset outPortOffset,
    required Offset inPortOffset,
  }) =>
      Path()
        ..moveTo(outPortOffset.dx, outPortOffset.dy)
        ..lineTo(inPortOffset.dx, inPortOffset.dy);

  static Path computeNinetyDegreesLinkPath({
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outPortGeometricOrientation,
    required FlPortGeometricOrientation inPortGeometricOrientation,
  }) {
    bool isHorizontal(FlPortGeometricOrientation orientation) =>
        orientation == FlPortGeometricOrientation.left ||
        orientation == FlPortGeometricOrientation.right;

    final path = Path()..moveTo(outPortOffset.dx, outPortOffset.dy);

    const double minSegmentLength = 30.0;

    final Offset outDir = _getOrientationVector(outPortGeometricOrientation);
    final Offset inDir = _getOrientationVector(inPortGeometricOrientation);

    final bool outIsHorizontal = isHorizontal(outPortGeometricOrientation);
    final bool inIsHorizontal = isHorizontal(inPortGeometricOrientation);

    final double dx = inPortOffset.dx - outPortOffset.dx;
    final double dy = inPortOffset.dy - outPortOffset.dy;

    // Same orientation axis
    if (outIsHorizontal == inIsHorizontal) {
      // Both horizontal
      if (outIsHorizontal) {
        final double midY = (outPortOffset.dy + inPortOffset.dy) / 2;

        // Extend from output in its direction
        final double firstCornerX = outPortOffset.dx + outDir.dx * minSegmentLength;

        path
          ..lineTo(firstCornerX, outPortOffset.dy)
          ..lineTo(firstCornerX, midY)
          ..lineTo(inPortOffset.dx + inDir.dx * minSegmentLength, midY)
          ..lineTo(
            inPortOffset.dx + inDir.dx * minSegmentLength,
            inPortOffset.dy,
          )
          ..lineTo(inPortOffset.dx, inPortOffset.dy);
      }
      // Both vertical
      else {
        final double midX = (outPortOffset.dx + inPortOffset.dx) / 2;

        // Extend from output in its direction
        final double firstCornerY = outPortOffset.dy + outDir.dy * minSegmentLength;

        path
          ..lineTo(outPortOffset.dx, firstCornerY)
          ..lineTo(midX, firstCornerY)
          ..lineTo(midX, inPortOffset.dy + inDir.dy * minSegmentLength)
          ..lineTo(
            inPortOffset.dx,
            inPortOffset.dy + inDir.dy * minSegmentLength,
          )
          ..lineTo(inPortOffset.dx, inPortOffset.dy);
      }
    }
    // Different orientation axes
    else {
      // Out is horizontal, in is vertical
      if (outIsHorizontal) {
        // Check if we can make a simple two-segment path
        final bool goingRight = outDir.dx > 0;
        final bool goingDown = inDir.dy > 0;

        // Determine turning point
        final bool canTurnAtOut = (goingRight && dx > 0) || (!goingRight && dx < 0);
        final bool canTurnAtIn = (goingDown && dy > 0) || (!goingDown && dy < 0);

        if (canTurnAtOut && canTurnAtIn) {
          // Extend out horizontally then turn to reach input (L-shape)
          final double turnX = inPortOffset.dx;

          path
            ..lineTo(turnX, outPortOffset.dy)
            ..lineTo(turnX, inPortOffset.dy);
        } else if (canTurnAtOut) {
          // Turn at output's preferred distance
          final double turnX = outPortOffset.dx + outDir.dx * minSegmentLength;

          path
            ..lineTo(turnX, outPortOffset.dy)
            ..lineTo(turnX, inPortOffset.dy + inDir.dy * minSegmentLength)
            ..lineTo(
              inPortOffset.dx,
              inPortOffset.dy + inDir.dy * minSegmentLength,
            )
            ..lineTo(inPortOffset.dx, inPortOffset.dy);
        } else if (canTurnAtIn) {
          // Turn at input's preferred distance
          final double turnY = inPortOffset.dy;

          path
            ..lineTo(
              outPortOffset.dx + outDir.dx * minSegmentLength,
              outPortOffset.dy,
            )
            ..lineTo(outPortOffset.dx + outDir.dx * minSegmentLength, turnY)
            ..lineTo(inPortOffset.dx, turnY);
        } else {
          // Extend from both ports in their preferred directions first then connect in the middle (Z-shape)
          final double extendX = outPortOffset.dx + outDir.dx * minSegmentLength;
          final double extendY = inPortOffset.dy + inDir.dy * minSegmentLength;
          final double midY = (outPortOffset.dy + extendY) / 2;

          path
            ..lineTo(extendX, outPortOffset.dy)
            ..lineTo(extendX, midY)
            ..lineTo(inPortOffset.dx, midY)
            ..lineTo(inPortOffset.dx, inPortOffset.dy);
        }
      }
      // In is vertical, out is horizontal
      else {
        final bool goingDown = outDir.dy > 0;
        final bool goingRight = inDir.dx > 0;

        // Determine turning point
        final bool canTurnAtOut = (goingDown && dy > 0) || (!goingDown && dy < 0);
        final bool canTurnAtIn = (goingRight && dx > 0) || (!goingRight && dx < 0);

        if (canTurnAtOut && canTurnAtIn) {
          // Extend out vertically then turn to reach input (L-shape)
          final double turnY = inPortOffset.dy;

          path
            ..lineTo(outPortOffset.dx, turnY)
            ..lineTo(inPortOffset.dx, turnY);
        } else if (canTurnAtOut) {
          // Turn at output's preferred distance
          final double turnY = outPortOffset.dy + outDir.dy * minSegmentLength;

          path
            ..lineTo(outPortOffset.dx, turnY)
            ..lineTo(inPortOffset.dx + inDir.dx * minSegmentLength, turnY)
            ..lineTo(
              inPortOffset.dx + inDir.dx * minSegmentLength,
              inPortOffset.dy,
            )
            ..lineTo(inPortOffset.dx, inPortOffset.dy);
        } else if (canTurnAtIn) {
          // Turn at input's preferred distance
          final double turnX = inPortOffset.dx;

          path
            ..lineTo(
              outPortOffset.dx,
              outPortOffset.dy + outDir.dy * minSegmentLength,
            )
            ..lineTo(turnX, outPortOffset.dy + outDir.dy * minSegmentLength)
            ..lineTo(turnX, inPortOffset.dy);
        } else {
          // Extend from both ports in their preferred directions first then connect in the middle (Z-shape)
          final double extendY = outPortOffset.dy + outDir.dy * minSegmentLength;
          final double extendX = inPortOffset.dx + inDir.dx * minSegmentLength;
          final double midX = (outPortOffset.dx + extendX) / 2;

          path
            ..lineTo(outPortOffset.dx, extendY)
            ..lineTo(midX, extendY)
            ..lineTo(midX, inPortOffset.dy)
            ..lineTo(inPortOffset.dx, inPortOffset.dy);
        }
      }
    }

    return path;
  }

  static Path computeCirclePortPath(PortPaintModel data) => Path()
    ..addOval(
      Rect.fromCircle(
        center: data.offset,
        radius: data.style.radius,
      ),
    );

  static Path computeTrianglePortPath(PortPaintModel data) {
    final double r = data.style.radius;

    // Base triangle (pointing left for inputs and right for outputs)
    final points = data.isInput
        ? [
            Offset(r, -r), // top-right
            Offset(-r, 0), // apex (left)
            Offset(r, r), // bottom-right
          ]
        : [
            Offset(-r, -r), // top-left
            Offset(r, 0), // apex (right)
            Offset(-r, r), // bottom-left
          ];

    // Determine rotation angle from orientation
    final double angle = switch (data.orientation) {
      FlPortGeometricOrientation.top => -math.pi / 2,
      FlPortGeometricOrientation.bottom => math.pi / 2,
      FlPortGeometricOrientation.left => math.pi,
      FlPortGeometricOrientation.right => 0.0,
    };

    // Rotate + translate points
    Offset transform(Offset p) {
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);

      final double x = p.dx * cosA - p.dy * sinA;
      final double y = p.dx * sinA + p.dy * cosA;

      return Offset(data.offset.dx + x, data.offset.dy + y);
    }

    final List<Offset> transformed = points.map(transform).toList();

    return Path()
      ..moveTo(transformed[0].dx, transformed[0].dy)
      ..lineTo(transformed[1].dx, transformed[1].dy)
      ..lineTo(transformed[2].dx, transformed[2].dy)
      ..close();
  }

  /// Checks if a point is near a path within the given tolerance
  static bool isPointNearPath(Path path, Offset point, double tolerance) {
    for (final PathMetric metric in path.computeMetrics()) {
      for (double t = 0; t < metric.length; t += 1.0) {
        final Offset? pos = metric.getTangentForOffset(t)?.position;

        if (pos != null && (point - pos).distance <= tolerance) return true;
      }
    }

    return false;
  }
}
