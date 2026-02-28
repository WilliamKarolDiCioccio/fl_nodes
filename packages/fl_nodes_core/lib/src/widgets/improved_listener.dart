import 'package:flutter/foundation.dart';
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
    required this.child,
    super.key,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<PointerDownEventListener?>.has(
        'onPointerPressed',
        onPointerPressed,
      ),
    );
    properties.add(
      ObjectFlagProperty<PointerMoveEventListener?>.has(
        'onPointerMoved',
        onPointerMoved,
      ),
    );
    properties.add(
      ObjectFlagProperty<PointerUpEventListener?>.has(
        'onPointerReleased',
        onPointerReleased,
      ),
    );
    properties.add(
      ObjectFlagProperty<PointerCancelEventListener?>.has(
        'onPointerCanceled',
        onPointerCanceled,
      ),
    );
    properties.add(
      ObjectFlagProperty<PointerSignalEventListener?>.has(
        'onPointerSignalReceived',
        onPointerSignalReceived,
      ),
    );
    properties.add(
      ObjectFlagProperty<PointerPanZoomStartEventListener?>.has(
        'onPointerPanZoomStart',
        onPointerPanZoomStart,
      ),
    );
    properties.add(
      ObjectFlagProperty<PointerPanZoomUpdateEventListener?>.has(
        'onPointerPanZoomUpdate',
        onPointerPanZoomUpdate,
      ),
    );
    properties.add(
      ObjectFlagProperty<PointerPanZoomEndEventListener?>.has(
        'onPointerPanZoomEnd',
        onPointerPanZoomEnd,
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback?>.has('onDoubleClick', onDoubleClick),
    );
    properties.add(
      DiagnosticsProperty<Duration>(
        'doubleClickThreshold',
        doubleClickThreshold,
      ),
    );
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior));
  }
}

class _ImprovedListenerState extends State<ImprovedListener> {
  DateTime? _lastClickTime;

  @override
  Widget build(BuildContext context) => Listener(
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
