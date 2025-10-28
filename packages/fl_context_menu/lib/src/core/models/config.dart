import 'package:flutter/widgets.dart';

class FlMenuConfig {
  final RouteSettings? routeSettings;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;
  final bool allowSnapshotting;
  final bool requestFocus;
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;

  const FlMenuConfig({
    this.routeSettings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = false,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.allowSnapshotting = true,
    this.requestFocus = true,
    this.minWidth = 100,
    this.minHeight = 0,
    this.maxWidth = 200,
    this.maxHeight = 600,
  });
}
