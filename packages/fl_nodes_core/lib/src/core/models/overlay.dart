import 'package:flutter/material.dart';

typedef OverlayBuilder = Widget Function(
  BuildContext context,
  FlOverlayData data,
);

class FlOverlayData {
  final OverlayBuilder builder;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;
  bool isVisible;
  double opacity;

  FlOverlayData({
    required this.builder,
    this.top,
    this.left,
    this.bottom,
    this.right,
    this.isVisible = true,
    this.opacity = 1.0,
  });
}
