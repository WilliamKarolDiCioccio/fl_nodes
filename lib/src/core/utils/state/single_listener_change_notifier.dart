import 'package:flutter/foundation.dart';

/// Tiny replacement for [ChangeNotifier] to optimize for the zero-or-one listener scenario
mixin SingleListenerChangeNotifier implements Listenable {
  VoidCallback? listener;

  void notifyListeners() =>
      listener?.call(); // just to be compatible with [ChangeNotifier]

  @override
  @visibleForOverriding
  void addListener(VoidCallback listener) {
    if (this.listener != null) {
      throw StateError(
        "Trying to add another listener, but this Listenable only supports one listener at a time",
      );
    }

    this.listener = listener;
  }

  @override
  @visibleForOverriding
  void removeListener(VoidCallback listener) {
    // just like most [Listenable]s, we ignore any listener that isn't ours (for usability purposes)
    if (listener == this.listener) this.listener = null;
  }

  void dispose() => listener = null;
}
