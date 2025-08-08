import 'package:fl_nodes/src/core/models/entities.dart';

import '../../constants.dart';
import '../models/events.dart';
import '../utils/stack.dart';
import 'core.dart';

/// A class that manages the undo and redo history of the node editor.
///
/// The undo and redo stacks are capped at [kMaxEventUndoHistory] and
/// [kMaxEventRedoHistory] respectively.
///
/// The history is updated whenever an undoable event is triggered.
class FlNodeEditorHistory {
  final FlNodeEditorController controller;

  bool _isTraversingHistory = false;
  final _undoStack = Stack<NodeEditorEvent>(kMaxEventUndoHistory);
  final _redoStack = Stack<NodeEditorEvent>(kMaxEventRedoHistory);

  FlNodeEditorHistory(this.controller) {
    controller.eventBus.events.listen(_handleUndoableEvents);
  }

  /// Clears the undo and redo stacks.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Handles undoable events.
  ///
  /// If the event is not undoable, it is ignored.
  ///
  /// If the event is undoable and is not the same as the previous event,
  /// the redo stack is cleared as the user has made a new change.
  /// If the event is a [DragSelectionEvent] and the previous event is also a
  /// [DragSelectionEvent] with the same node IDs, the previous event is popped
  /// and a new [DragSelectionEvent] is pushed after adding the deltas.
  void _handleUndoableEvents(NodeEditorEvent event) {
    if (!event.isUndoable || _isTraversingHistory) return;

    if (_undoStack.length >= kMaxEventUndoHistory) _undoStack.evict();
    if (_redoStack.length >= kMaxEventRedoHistory) _redoStack.evict();

    final previousEvent = _undoStack.peek();
    final nextEvent = _redoStack.peek();

    if (event.id != previousEvent?.id && event.id != nextEvent?.id) {
      _redoStack.clear();
    } else {
      return;
    }

    if (event is DragSelectionEvent && previousEvent is DragSelectionEvent) {
      if (event.nodeIds.length == previousEvent.nodeIds.length &&
          event.nodeIds.every(previousEvent.nodeIds.contains)) {
        _undoStack.pop();
        _undoStack.push(
          DragSelectionEvent(
            id: event.id,
            event.nodeIds,
            event.delta + previousEvent.delta,
          ),
        );
        return;
      }
    }

    _undoStack.push(event);
  }

  /// Undoes the last event in the undo stack.
  void undo() {
    if (_undoStack.isEmpty) return;

    _isTraversingHistory = true;
    final event = _undoStack.pop()!;
    _redoStack.push(event);

    try {
      if (event is DragSelectionEvent) {
        controller.selectNodesById(event.nodeIds, isHandled: true);
        controller.dragSelection(
          -event.delta,
          eventId: event.id,
          isWorldDelta: true,
          resetUnboundOffset: true,
        );
        controller.clearSelection();
      } else if (event is AddNodeEvent) {
        controller.removeNodeById(event.node.id, eventId: event.id);
      } else if (event is RemoveNodeEvent) {
        controller.addNodeFromExisting(event.node, eventId: event.id);
      } else if (event is AddLinkEvent) {
        controller.removeLinkById(event.link.id, eventId: event.id);
      } else if (event is RemoveLinkEvent) {
        controller.addLinkFromExisting(event.link, eventId: event.id);
      }
    } finally {
      _isTraversingHistory = false;
    }
  }

  /// Redoes the last event in the redo stack.
  void redo() {
    if (_redoStack.isEmpty) return;

    _isTraversingHistory = true;
    final event = _redoStack.pop()!;
    _undoStack.push(event);

    try {
      if (event is DragSelectionEvent) {
        controller.selectNodesById(event.nodeIds, isHandled: true);
        controller.dragSelection(
          event.delta,
          eventId: event.id,
          isWorldDelta: true,
          resetUnboundOffset: true,
        );
        controller.clearSelection();
      } else if (event is AddNodeEvent) {
        controller.addNodeFromExisting(
          event.node.copyWith(
            state: NodeState(isSelected: true),
          ),
          eventId: event.id,
        );
      } else if (event is RemoveNodeEvent) {
        controller.removeNodeById(event.node.id, eventId: event.id);
      } else if (event is AddLinkEvent) {
        controller.addLinkFromExisting(
          event.link.copyWith(
            state: LinkState(isSelected: true),
          ),
          eventId: event.id,
        );
      } else if (event is RemoveLinkEvent) {
        controller.removeLinkById(
          event.link.id,
          eventId: event.id,
        );
      }
    } finally {
      _isTraversingHistory = false;
    }
  }
}
