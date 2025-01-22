import 'package:flutter/material.dart';

import '../models/entities.dart';

/// Events are used to communicate between the [FlNodeEditorController] and the Widgets composing the Node Editor.
/// Events can (where applicable) carry data to be used by the Widgets to update their state.
/// Events can be used to trigger animations, or to update the state of the Widgets.
/// Events can be handled by the Widgets to prevent the event from bubbling up to the parent Widgets.
/// Event can be discarded using the [isHandled] flag to group Widgets rebuilds.
/// There is no one to one match between controller emthods and events, the latter only exist
/// if there is data to be passed or rebuilds to be triggered.

/// Event base class for the [FlNodeEditorController] events bus.
abstract class NodeEditorEvent {
  final String id;
  final bool isHandled;
  final bool isUndoable;

  NodeEditorEvent({
    required this.id,
    this.isHandled = false,
    this.isUndoable = false,
  });
}

final class ViewportOffsetEvent extends NodeEditorEvent {
  final Offset offset;
  final bool animate;

  ViewportOffsetEvent(
    this.offset, {
    this.animate = true,
    required super.id,
    super.isHandled,
  });
}

final class ViewportZoomEvent extends NodeEditorEvent {
  final double zoom;
  final bool animate;

  ViewportZoomEvent(
    this.zoom, {
    this.animate = true,
    required super.id,
    super.isHandled,
  });
}

final class SelectionAreaEvent extends NodeEditorEvent {
  final Rect area;

  SelectionAreaEvent(this.area, {required super.id, super.isHandled});
}

final class DragSelectionEvent extends NodeEditorEvent {
  final Set<String> nodeIds;
  final Offset delta;

  DragSelectionEvent(
    this.nodeIds,
    this.delta, {
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);
}

final class SelectionEvent extends NodeEditorEvent {
  final Set<String> nodeIds;

  SelectionEvent(this.nodeIds, {required super.id, super.isHandled});
}

final class AddNodeEvent extends NodeEditorEvent {
  final NodeInstance node;

  AddNodeEvent(
    this.node, {
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);
}

final class RemoveNodeEvent extends NodeEditorEvent {
  final NodeInstance node;

  RemoveNodeEvent(this.node, {required super.id, super.isHandled})
      : super(isUndoable: true);
}

final class AddLinkEvent extends NodeEditorEvent {
  final Link link;

  AddLinkEvent(
    this.link, {
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);
}

final class RemoveLinkEvent extends NodeEditorEvent {
  final Link link;

  RemoveLinkEvent(this.link, {required super.id, super.isHandled})
      : super(isUndoable: true);
}

final class DrawTempLinkEvent extends NodeEditorEvent {
  final Offset from;
  final Offset to;

  DrawTempLinkEvent(
    this.from,
    this.to, {
    required super.id,
    super.isHandled,
  });
}

final class CollapseNodeEvent extends NodeEditorEvent {
  final Set<String> nodeIds;

  CollapseNodeEvent(this.nodeIds, {required super.id, super.isHandled});
}

final class ExpandNodeEvent extends NodeEditorEvent {
  final Set<String> nodeIds;

  ExpandNodeEvent(this.nodeIds, {required super.id, super.isHandled});
}

final class PasteSelectionEvent extends NodeEditorEvent {
  final Offset position;
  final String clipboardContent;

  PasteSelectionEvent(
    this.position,
    this.clipboardContent, {
    required super.id,
    super.isHandled,
  });
}

final class CutSelectionEvent extends NodeEditorEvent {
  final String clipboardContent;

  CutSelectionEvent(
    this.clipboardContent, {
    required super.id,
    super.isHandled,
  });
}

enum FieldEventType {
  change,
  submit,
  cancel,
}

final class NodeFieldEvent extends NodeEditorEvent {
  final String nodeId;
  final dynamic value;
  final FieldEventType eventType;

  NodeFieldEvent(
    this.nodeId,
    this.value,
    this.eventType, {
    required super.id,
    super.isHandled,
  });
}

class SaveProjectEvent extends NodeEditorEvent {
  SaveProjectEvent({required super.id});
}

class LoadProjectEvent extends NodeEditorEvent {
  LoadProjectEvent({required super.id});
}

class NewProjectEvent extends NodeEditorEvent {
  NewProjectEvent({required super.id});
}
