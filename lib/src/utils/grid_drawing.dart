import 'package:flutter/material.dart';

import '../core/models/styles.dart';

void drawGrid(
  FlGridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
) {
  _drawGridLines(style, canvas, viewport, startX, startY);
  _drawIntersections(style, canvas, viewport, startX, startY);
}

void _drawGridLines(
  FlGridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
) {
  if (style.gridSpacingX <= 0 && style.gridSpacingY <= 0) {
    return;
  }

  final linePaint = Paint()
    ..color = style.lineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = style.lineWidth;

  _drawVerticalLines(style, canvas, viewport, startX, linePaint);
  _drawHorizontalLines(style, canvas, viewport, startY, linePaint);
}

void _drawVerticalLines(
  FlGridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  Paint linePaint,
) {
  for (double x = startX; x <= viewport.right; x += style.gridSpacingX) {
    canvas.drawLine(
      Offset(x, viewport.top),
      Offset(x, viewport.bottom),
      linePaint,
    );
  }
}

void _drawHorizontalLines(
  FlGridStyle style,
  Canvas canvas,
  Rect viewport,
  double startY,
  Paint linePaint,
) {
  for (double y = startY; y <= viewport.bottom; y += style.gridSpacingY) {
    canvas.drawLine(
      Offset(viewport.left, y),
      Offset(viewport.right, y),
      linePaint,
    );
  }
}

void _drawIntersections(
  FlGridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
) {
  if (style.intersectionRadius <= 0) {
    return;
  }

  final intersectionPaint = Paint()
    ..color = style.intersectionColor
    ..style = PaintingStyle.fill;

  _drawCircles(
    style,
    canvas,
    viewport,
    startX,
    startY,
    intersectionPaint,
  );
}

void _drawCircles(
  FlGridStyle style,
  Canvas canvas,
  Rect viewport,
  double startX,
  double startY,
  Paint paint,
) {
  final intersectionRadius = style.intersectionRadius;

  for (double x = startX; x <= viewport.right; x += style.gridSpacingX) {
    for (double y = startY; y <= viewport.bottom; y += style.gridSpacingY) {
      canvas.drawCircle(
        Offset(x, y),
        intersectionRadius,
        paint,
      );
    }
  }
}
