import 'package:flutter/material.dart';

/// Events are used to communicate between the [FlNodeEditorController] and the Widgets composing the Node Editor.
/// Events can (where applicable) carry data to be used by the Widgets to update their state.
/// Events can be used to trigger animations, or to update the state of the Widgets.
/// Events can be handled by the Widgets to prevent the event from bubbling up to the parent Widgets.
/// Event can be discarded using the [isHandled] flag to group Widgets rebuilds.
/// There is no one to one match between controller emthods and events, the latter only exist
/// if there is data to be passed or rebuilds to be triggered.

/// Event base class for the [FlNodeEditorController] events bus.
class NodeEditorEvent {
  final bool isHandled;

  NodeEditorEvent({this.isHandled = false});
}

final class ViewportOffsetEvent extends NodeEditorEvent {
  final Offset offset;
  final bool animate;

  ViewportOffsetEvent(this.offset, {this.animate = true, super.isHandled});
}

final class ViewportZoomEvent extends NodeEditorEvent {
  final double zoom;
  final bool animate;

  ViewportZoomEvent(this.zoom, {this.animate = true, super.isHandled});
}

final class SelectionAreaEvent extends NodeEditorEvent {
  final Rect area;

  SelectionAreaEvent(this.area, {super.isHandled});
}

final class DragSelectionEvent extends NodeEditorEvent {
  final Set<String> ids;
  final Offset delta;

  DragSelectionEvent(this.ids, this.delta, {super.isHandled});
}

final class SelectionEvent extends NodeEditorEvent {
  final Set<String> ids;

  SelectionEvent(this.ids, {super.isHandled});
}

final class AddNodeEvent extends NodeEditorEvent {
  final String id;

  AddNodeEvent(this.id, {super.isHandled});
}

final class RemoveNodesEvent extends NodeEditorEvent {
  final Set<String> ids;

  RemoveNodesEvent(this.ids, {super.isHandled});
}

final class AddLinkEvent extends NodeEditorEvent {
  final String id;

  AddLinkEvent(this.id, {super.isHandled});
}

final class DrawTempLinkEvent extends NodeEditorEvent {
  final Offset from;
  final Offset to;

  DrawTempLinkEvent(this.from, this.to, {super.isHandled});
}

final class RemoveLinksEvent extends NodeEditorEvent {
  final String id;

  RemoveLinksEvent(this.id, {super.isHandled});
}

final class CollapseNodeEvent extends NodeEditorEvent {
  final Set<String> ids;

  CollapseNodeEvent(this.ids, {super.isHandled});
}

final class ExpandNodeEvent extends NodeEditorEvent {
  final Set<String> ids;

  ExpandNodeEvent(this.ids, {super.isHandled});
}

class PasteSelectionEvent extends NodeEditorEvent {
  final Set<String> ids;
  final Offset position;

  PasteSelectionEvent(this.ids, this.position, {super.isHandled});
}

final class CutSelectionEvent extends NodeEditorEvent {
  final Set<String> ids;

  CutSelectionEvent(this.ids, {super.isHandled});
}
