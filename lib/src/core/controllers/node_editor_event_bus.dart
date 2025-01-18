import 'dart:async';

import 'package:fl_nodes/src/core/controllers/node_editor_events.dart';

/// A class that acts as an event bus for the Node Editor.
///
/// This class is responsible for handling and dispatching events
/// related to the node editor. It allows different parts of the
/// application to communicate with each other by sending and
/// receiving events.
///
/// Events can object instances should extend the [NodeEditorEvent] class.
class NodeEditorEventBus {
  final _streamController = StreamController<NodeEditorEvent>.broadcast();

  void emit(NodeEditorEvent event) {
    if (event.isHandled) return;
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }

  Stream<NodeEditorEvent> get events => _streamController.stream;
}
