import 'package:flutter/material.dart';

import 'package:fl_nodes_core/src/core/models/data.dart';

import '../../models/paint.dart';

/// Utility class for working with paths in the node editor.
final class PathUtils {
  static double distanceToBezier({
    required Offset point,
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outOrientation,
    required FlPortGeometricOrientation inOrientation,
  }) {
    final curve = computeBezierLinkPath(
      outPortOffset: outPortOffset,
      inPortOffset: inPortOffset,
      outPortGeometricOrientation: outOrientation,
      inPortGeometricOrientation: inOrientation,
    );

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

  static double distanceToStraightLine({
    required Offset point,
    required Offset outPortOffset,
    required Offset inPortOffset,
  }) {
    final lineVector = inPortOffset - outPortOffset;
    final pointVector = point - outPortOffset;
    final lineLengthSquared =
        lineVector.dx * lineVector.dx + lineVector.dy * lineVector.dy;

    // Line is a single point
    if (lineLengthSquared == 0) return (point - outPortOffset).distance;

    // Project pointVector onto lineVector to find the projection's scale
    final t =
        (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) /
            lineLengthSquared;
    final clampedT = t.clamp(0.0, 1.0); // Clamp to line segment

    final closestPoint = outPortOffset + lineVector * clampedT;
    return (point - closestPoint).distance;
  }

  static double distanceToNinetyDegrees({
    required Offset point,
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outOrientation,
    required FlPortGeometricOrientation inOrientation,
  }) {
    final path = computeNinetyDegreesLinkPath(
      outPortOffset: outPortOffset,
      inPortOffset: inPortOffset,
      outPortGeometricOrientation: outOrientation,
      inPortGeometricOrientation: inOrientation,
    );

    final metrics = path.computeMetrics();
    double minDistance = double.infinity;

    for (final metric in metrics) {
      final pathLength = metric.length;
      const int segments = 50; // Fewer segments needed for straight lines
      for (int i = 0; i <= segments; i++) {
        final t = i / segments;
        final pointOnPath =
            metric.getTangentForOffset(t * pathLength)!.position;
        final distance = (point - pointOnPath).distance;

        minDistance = distance < minDistance ? distance : minDistance;
      }
    }

    return minDistance;
  }

  // Helper to get offset direction vector from orientation
  static Offset _getOrientationVector(FlPortGeometricOrientation orientation) {
    return switch (orientation) {
      FlPortGeometricOrientation.right => const Offset(1, 0),
      FlPortGeometricOrientation.left => const Offset(-1, 0),
      FlPortGeometricOrientation.top => const Offset(0, -1),
      FlPortGeometricOrientation.bottom => const Offset(0, 1),
    };
  }

  static Path computeBezierLinkPath({
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outPortGeometricOrientation,
    required FlPortGeometricOrientation inPortGeometricOrientation,
  }) {
    final Path path = Path()..moveTo(outPortOffset.dx, outPortOffset.dy);

    const double defaultOffset = 400.0;
    const double minOffset = 50.0;

    final outDir = _getOrientationVector(outPortGeometricOrientation);
    final inDir = _getOrientationVector(inPortGeometricOrientation);

    // Calculate distance between ports
    final distance = (inPortOffset - outPortOffset).distance;

    // Adaptive control offset based on distance and orientation
    final baseControlOffset = distance < defaultOffset * 2
        ? (distance / 2).clamp(minOffset, defaultOffset)
        : defaultOffset;

    // Scale control offset based on whether we're going "against" the natural flow
    double outControlScale = 1.0;
    double inControlScale = 1.0;

    final facingEachOther =
        (outDir.dx * inDir.dx + outDir.dy * inDir.dy) < -0.5;

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
  }) {
    return Path()
      ..moveTo(outPortOffset.dx, outPortOffset.dy)
      ..lineTo(inPortOffset.dx, inPortOffset.dy);
  }

  static Path computeNinetyDegreesLinkPath({
    required Offset outPortOffset,
    required Offset inPortOffset,
    required FlPortGeometricOrientation outPortGeometricOrientation,
    required FlPortGeometricOrientation inPortGeometricOrientation,
  }) {
    bool isHorizontal(FlPortGeometricOrientation orientation) {
      return orientation == FlPortGeometricOrientation.left ||
          orientation == FlPortGeometricOrientation.right;
    }

    final path = Path()..moveTo(outPortOffset.dx, outPortOffset.dy);

    const double minSegmentLength = 30.0;

    final outDir = _getOrientationVector(outPortGeometricOrientation);
    final inDir = _getOrientationVector(inPortGeometricOrientation);

    final outIsHorizontal = isHorizontal(outPortGeometricOrientation);
    final inIsHorizontal = isHorizontal(inPortGeometricOrientation);

    final dx = inPortOffset.dx - outPortOffset.dx;
    final dy = inPortOffset.dy - outPortOffset.dy;

    // Same orientation axis
    if (outIsHorizontal == inIsHorizontal) {
      // Both horizontal
      if (outIsHorizontal) {
        final midY = (outPortOffset.dy + inPortOffset.dy) / 2;

        // Extend from output in its direction
        final firstCornerX = outPortOffset.dx + outDir.dx * minSegmentLength;

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
        final midX = (outPortOffset.dx + inPortOffset.dx) / 2;

        // Extend from output in its direction
        final firstCornerY = outPortOffset.dy + outDir.dy * minSegmentLength;

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
        final goingRight = outDir.dx > 0;
        final goingDown = inDir.dy > 0;

        // Determine turning point
        final canTurnAtOut = (goingRight && dx > 0) || (!goingRight && dx < 0);
        final canTurnAtIn = (goingDown && dy > 0) || (!goingDown && dy < 0);

        if (canTurnAtOut && canTurnAtIn) {
          // Extend out horizontally then turn to reach input (L-shape)
          final turnX = inPortOffset.dx;

          path
            ..lineTo(turnX, outPortOffset.dy)
            ..lineTo(turnX, inPortOffset.dy);
        } else if (canTurnAtOut) {
          // Turn at output's preferred distance
          final turnX = outPortOffset.dx + outDir.dx * minSegmentLength;

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
          final turnY = inPortOffset.dy;

          path
            ..lineTo(
              outPortOffset.dx + outDir.dx * minSegmentLength,
              outPortOffset.dy,
            )
            ..lineTo(outPortOffset.dx + outDir.dx * minSegmentLength, turnY)
            ..lineTo(inPortOffset.dx, turnY);
        } else {
          // Extend from both ports in their preferred directions first then connect in the middle (Z-shape)
          final extendX = outPortOffset.dx + outDir.dx * minSegmentLength;
          final extendY = inPortOffset.dy + inDir.dy * minSegmentLength;
          final midY = (outPortOffset.dy + extendY) / 2;

          path
            ..lineTo(extendX, outPortOffset.dy)
            ..lineTo(extendX, midY)
            ..lineTo(inPortOffset.dx, midY)
            ..lineTo(inPortOffset.dx, inPortOffset.dy);
        }
      }
      // In is vertical, out is horizontal
      else {
        final goingDown = outDir.dy > 0;
        final goingRight = inDir.dx > 0;

        // Determine turning point
        final canTurnAtOut = (goingDown && dy > 0) || (!goingDown && dy < 0);
        final canTurnAtIn = (goingRight && dx > 0) || (!goingRight && dx < 0);

        if (canTurnAtOut && canTurnAtIn) {
          // Extend out vertically then turn to reach input (L-shape)
          final turnY = inPortOffset.dy;

          path
            ..lineTo(outPortOffset.dx, turnY)
            ..lineTo(inPortOffset.dx, turnY);
        } else if (canTurnAtOut) {
          // Turn at output's preferred distance
          final turnY = outPortOffset.dy + outDir.dy * minSegmentLength;

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
          final turnX = inPortOffset.dx;

          path
            ..lineTo(
              outPortOffset.dx,
              outPortOffset.dy + outDir.dy * minSegmentLength,
            )
            ..lineTo(turnX, outPortOffset.dy + outDir.dy * minSegmentLength)
            ..lineTo(turnX, inPortOffset.dy);
        } else {
          // Extend from both ports in their preferred directions first then connect in the middle (Z-shape)
          final extendY = outPortOffset.dy + outDir.dy * minSegmentLength;
          final extendX = inPortOffset.dx + inDir.dx * minSegmentLength;
          final midX = (outPortOffset.dx + extendX) / 2;

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

  /// Checks if a point is near a path within the given tolerance
  static bool isPointNearPath(Path path, Offset point, double tolerance) {
    for (final metric in path.computeMetrics()) {
      for (double t = 0; t < metric.length; t += 1.0) {
        final pos = metric.getTangentForOffset(t)?.position;

        if (pos != null && (point - pos).distance <= tolerance) return true;
      }
    }

    return false;
  }
}
