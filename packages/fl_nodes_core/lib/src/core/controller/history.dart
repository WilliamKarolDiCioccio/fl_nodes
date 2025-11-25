import '../../constants.dart';
import '../containers/stack.dart';
import '../events/events.dart';
import '../models/data.dart';
import 'core.dart';

/// A class that manages the undo and redo history of the node editor.
///
/// The undo and redo stacks are capped at [kMaxEventUndoHistory] and
/// [kMaxEventRedoHistory] respectively.
///
/// The history is updated whenever an undoable event is triggered.
class FlNodesHistoryHelper {
  final FlNodesController controller;

  bool _isTraversingHistory = false;
  final _undoStack = Stack<NodeEditorEvent>(kMaxEventUndoHistory);
  final _redoStack = Stack<NodeEditorEvent>(kMaxEventRedoHistory);

  FlNodesHistoryHelper(this.controller) {
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
  /// If the event is a [FlDragSelectionEvent] and the previous event is also a
  /// [FlDragSelectionEvent] with the same node IDs, the previous event is popped
  /// and a new [FlDragSelectionEvent] is pushed after adding the deltas.
  void _handleUndoableEvents(NodeEditorEvent event) {
    if (!event.isUndoable || _isTraversingHistory) return;

    if (event is FlNodeFieldEvent ||
        event is FlNodeCustomDataEvent ||
        event is FlLinkLabelEvent) {
      // TODO: Implement undo/redo for these events later.
      return;
    }

    if (_undoStack.length >= kMaxEventUndoHistory) _undoStack.evict();
    if (_redoStack.length >= kMaxEventRedoHistory) _redoStack.evict();

    final previousEvent = _undoStack.peek();
    final nextEvent = _redoStack.peek();

    if (event.id != previousEvent?.id && event.id != nextEvent?.id) {
      _redoStack.clear();
    } else {
      return;
    }

    if (event is FlDragSelectionEvent &&
        previousEvent is FlDragSelectionEvent) {
      if (event.nodeIds.length == previousEvent.nodeIds.length &&
          event.nodeIds.every(previousEvent.nodeIds.contains)) {
        _undoStack.pop();
        _undoStack.push(
          FlDragSelectionEvent(
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
      if (event is FlDragSelectionEvent) {
        controller.selectNodesById(event.nodeIds, isHandled: true);
        controller.dragSelection(
          -event.delta,
          eventId: event.id,
          isWorldDelta: true,
          resetUnboundOffset: true,
        );
        controller.clearSelection();
      } else if (event is FlAddNodeEvent) {
        controller.removeNodeById(event.node.id, eventId: event.id);
      } else if (event is FlRemoveNodeEvent) {
        controller.addNodeFromExisting(event.node, eventId: event.id);
      } else if (event is FlAddLinkEvent) {
        controller.removeLinkById(event.link.id, eventId: event.id);
      } else if (event is FlRemoveLinkEvent) {
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
      if (event is FlDragSelectionEvent) {
        controller.selectNodesById(event.nodeIds, isHandled: true);
        controller.dragSelection(
          event.delta,
          eventId: event.id,
          isWorldDelta: true,
          resetUnboundOffset: true,
        );
        controller.clearSelection();
      } else if (event is FlAddNodeEvent) {
        controller.addNodeFromExisting(
          event.node.copyWith(
            state: FlNodeState(isSelected: true),
          ),
          eventId: event.id,
        );
      } else if (event is FlRemoveNodeEvent) {
        controller.removeNodeById(event.node.id, eventId: event.id);
      } else if (event is FlAddLinkEvent) {
        controller.addLinkFromExisting(
          event.link.copyWith(
            state: FlLinkState(isSelected: true),
          ),
          eventId: event.id,
        );
      } else if (event is FlRemoveLinkEvent) {
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
