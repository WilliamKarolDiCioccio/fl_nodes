import 'package:flutter/material.dart';

/// Events are used to communicate between the [FlNodeEditorController] and the Widgets composing the Node Editor.
/// Events can (where applicable) carry data to be used by the Widgets to update their state.
/// Events can be handled by the Widgets to prevent the event from bubbling up to the parent Widgets.
/// Events can be used to trigger animations, or to update the state of the Widgets.
/// There is no one to one match between controller emthods and events, the latter only exist if there is data to be passed to the Widgets.

/// Event base class for the [FlNodeEditorController] events bus.
class NodeEditorEvent {
  final bool isHandled;

  NodeEditorEvent({this.isHandled = false});
}

final class ViewportOffsetEvent extends NodeEditorEvent {
  final Offset offset;
  final bool animate;

  ViewportOffsetEvent(this.offset, {this.animate = true});
}

final class ViewportZoomEvent extends NodeEditorEvent {
  final double zoom;
  final bool animate;

  ViewportZoomEvent(
    this.zoom, {
    this.animate = true,
  });
}

final class SelectionAreaEvent extends NodeEditorEvent {
  final Rect area;

  SelectionAreaEvent(this.area);
}

final class DragSelectionEvent extends NodeEditorEvent {
  final Set<String> ids;
  final Offset delta;

  DragSelectionEvent(this.ids, this.delta);
}

final class SelectionEvent extends NodeEditorEvent {
  final Set<String> ids;

  SelectionEvent(this.ids);
}

final class AddNodeEvent extends NodeEditorEvent {
  final String id;

  AddNodeEvent(this.id);
}

final class RemoveNodesEvent extends NodeEditorEvent {
  final Set<String> ids;

  RemoveNodesEvent(this.ids);
}

final class AddLinkEvent extends NodeEditorEvent {
  final String id;

  AddLinkEvent(this.id);
}

final class DrawTempLinkEvent extends NodeEditorEvent {
  final Offset from;
  final Offset to;

  DrawTempLinkEvent(this.from, this.to);
}

final class RemoveLinksEvent extends NodeEditorEvent {
  final String id;

  RemoveLinksEvent(this.id);
}

final class CollapseNodeEvent extends NodeEditorEvent {
  final Set<String> ids;

  CollapseNodeEvent(this.ids);
}

final class ExpandNodeEvent extends NodeEditorEvent {
  final Set<String> ids;

  ExpandNodeEvent(this.ids);
}
