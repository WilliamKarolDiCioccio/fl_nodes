import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ImprovedListener extends StatefulWidget {
  final Widget child;
  final PointerDownEventListener? onPointerPressed;
  final PointerMoveEventListener? onPointerMoved;
  final PointerUpEventListener? onPointerReleased;
  final PointerCancelEventListener? onPointerCanceled;
  final PointerSignalEventListener? onPointerSignalReceived;
  final PointerPanZoomStartEventListener? onPointerPanZoomStart;
  final PointerPanZoomUpdateEventListener? onPointerPanZoomUpdate;
  final PointerPanZoomEndEventListener? onPointerPanZoomEnd;
  final VoidCallback? onDoubleClick;
  final Duration doubleClickThreshold;
  final HitTestBehavior behavior;

  const ImprovedListener({
    super.key,
    required this.child,
    this.onPointerPressed,
    this.onPointerMoved,
    this.onPointerReleased,
    this.onPointerCanceled,
    this.onPointerSignalReceived,
    this.onPointerPanZoomStart,
    this.onPointerPanZoomUpdate,
    this.onPointerPanZoomEnd,
    this.onDoubleClick,
    this.doubleClickThreshold = const Duration(milliseconds: 300),
    this.behavior = HitTestBehavior.deferToChild,
  });

  @override
  State<ImprovedListener> createState() => _ImprovedListenerState();
}

class _ImprovedListenerState extends State<ImprovedListener> {
  DateTime? _lastClickTime;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: widget.behavior,
      onPointerDown: (PointerDownEvent event) {
        final now = DateTime.now();
        if (_lastClickTime != null &&
            now.difference(_lastClickTime!) < widget.doubleClickThreshold) {
          if (widget.onDoubleClick != null) {
            widget.onDoubleClick!();
          }
          _lastClickTime = null; // Reset after double click
        } else {
          _lastClickTime = now;
        }

        if (widget.onPointerPressed != null) {
          widget.onPointerPressed!(event);
        }
      },
      onPointerMove: widget.onPointerMoved,
      onPointerUp: widget.onPointerReleased,
      onPointerCancel: widget.onPointerCanceled,
      onPointerSignal: widget.onPointerSignalReceived,
      onPointerPanZoomStart: widget.onPointerPanZoomStart,
      onPointerPanZoomUpdate: widget.onPointerPanZoomUpdate,
      onPointerPanZoomEnd: widget.onPointerPanZoomEnd,
      child: widget.child,
    );
  }
}
