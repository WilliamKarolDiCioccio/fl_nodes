import 'dart:ui';

import 'package:fl_nodes_core/src/painters/custom_painter.dart';

final class SelectionAreaCustomPainter extends FlCustomPainter {
  Rect? highlightArea;

  SelectionAreaCustomPainter(super.controller);

  @override
  void paint(Canvas canvas, Rect viewport) {
    if (highlightArea == null) return;

    final style = controller.style.highlightAreaStyle;

    final Paint highlightPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    canvas.drawRect(highlightArea!, highlightPaint);

    final Paint borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(highlightArea!, borderPaint);
  }
}
