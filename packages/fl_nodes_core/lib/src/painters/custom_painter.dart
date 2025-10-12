import 'dart:ui';

import 'package:fl_nodes_core/fl_nodes_core.dart';

export 'package:fl_nodes_core/src/core/events/events.dart';
export 'package:fl_nodes_core/src/core/models/paint.dart';
export 'package:flutter/gestures.dart';

abstract class FlCustomPainter {
  final FlNodeEditorController controller;

  bool needsPaint = true;

  FlCustomPainter(this.controller);

  void paint(Canvas canvas, Rect viewport);
}
