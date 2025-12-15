import 'package:fl_nodes_core/src/core/controller/runner.dart';
import 'package:flutter/material.dart';

import '../../styles/styles.dart';
import '../controller/core.dart';
import '../models/data.dart';

/// Base event: small immutable payload common to all events.
@immutable
abstract base class NodeEditorEvent {
  final String id;
  final bool isHandled;
  final bool isUndoable;
  final bool isSideEffect;

  const NodeEditorEvent({
    required this.id,
    this.isHandled = false,
    this.isUndoable = false,
    this.isSideEffect = false,
  });

  Map<String, dynamic> toJson(Map<Type, DataHandler> dataHandlers) => {
        'id': id,
        'isHandled': isHandled,
        'isUndoable': isUndoable,
      };
}

/// ---------------------------------------------------------------------------
/// Categories (empty mixins to tag events for broad distinctions)
/// ---------------------------------------------------------------------------
mixin FlTreeEventCat {}
mixin FlPaintEventCat {}
mixin FlLayoutEventCat {}

/// ---------------------------------------------------------------------------
/// Classes (shared data for semantic categories)
/// ---------------------------------------------------------------------------

abstract base class FlViewportClassEvent extends NodeEditorEvent {
  const FlViewportClassEvent({required super.id, super.isHandled});
}

abstract base class FlSelectionClassEvent extends NodeEditorEvent {
  const FlSelectionClassEvent({
    required super.id,
    super.isUndoable,
    super.isHandled,
    super.isSideEffect,
  });
}

abstract base class FlVisualizationClassEvent extends NodeEditorEvent {
  const FlVisualizationClassEvent({required super.id, super.isHandled});
}

/// GraphEditEvent is intended for mutations to the graph: undo/redo & serialization.
abstract base class FlGraphEditClassEvent extends NodeEditorEvent {
  const FlGraphEditClassEvent({
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);
}

abstract base class FlClipboardClassEvent extends NodeEditorEvent {
  const FlClipboardClassEvent({
    required super.id,
    super.isUndoable,
    super.isHandled,
  });
}

abstract base class FlRunnerClassEvent extends NodeEditorEvent {
  const FlRunnerClassEvent({required super.id, super.isHandled}) : super();
}

abstract base class FlProjectClassEvent extends NodeEditorEvent {
  const FlProjectClassEvent({required super.id, super.isHandled}) : super();
}

abstract base class FlTempInteractionClassEvent extends NodeEditorEvent {
  const FlTempInteractionClassEvent({required super.id, super.isHandled})
      : super();
}

abstract base class FlConfigurationClassEvent extends NodeEditorEvent {
  const FlConfigurationClassEvent({required super.id, super.isHandled})
      : super();
}

/// ---------------------------------------------------------------------------
/// Concrete events — mapped to semantic category + rendering trait
/// (Adjust per your product needs; I mapped according to the earlier discussion)
/// ---------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////
// Viewport events (view state changes — paint-only)
////////////////////////////////////////////////////////////////////////

/// Event produced when the viewport offset changes.
/// -> Paint (no layout)
final class FlViewportOffsetEvent extends FlViewportClassEvent
    with FlPaintEventCat {
  final Offset offset;
  final bool animate;

  const FlViewportOffsetEvent(
    this.offset, {
    this.animate = true,
    required super.id,
    super.isHandled = false,
  });
}

/// Event produced when the viewport zoom level changes.
/// -> Paint (no layout)
final class FlViewportZoomEvent extends FlViewportClassEvent
    with FlPaintEventCat {
  final double zoom;
  final bool animate;

  const FlViewportZoomEvent(
    this.zoom, {
    this.animate = true,
    required super.id,
    super.isHandled = false,
  });
}

////////////////////////////////////////////////////////////////////////
// Selection events (mostly paint-only; dragging that moves nodes -> layout)
////////////////////////////////////////////////////////////////////////

enum FlSelectionEventType { select, holdSelect, deselect }

final class FlNodeSelectionEvent extends FlSelectionClassEvent
    with FlLayoutEventCat {
  final FlSelectionEventType type;
  final Set<String> nodeIds;

  const FlNodeSelectionEvent(
    this.nodeIds, {
    required this.type,
    required super.id,
    super.isHandled = false,
    super.isSideEffect = false,
  });
}

final class FlLinkSelectionEvent extends FlSelectionClassEvent
    with FlPaintEventCat {
  final FlSelectionEventType type;
  final Set<String> linkIds;

  const FlLinkSelectionEvent(
    this.linkIds, {
    required this.type,
    required super.id,
    super.isHandled = false,
    super.isSideEffect = false,
  });
}

/// Dragging selection updates positions -> layout (and undoable)
final class FlDragSelectionStartEvent extends FlGraphEditClassEvent
    with FlLayoutEventCat {
  final Set<String> nodeIds;
  final Offset position;

  const FlDragSelectionStartEvent(
    this.nodeIds,
    this.position, {
    required super.id,
    super.isHandled = false,
  });

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'nodeIds': nodeIds.toList(),
        'position': [position.dx, position.dy],
      };

  factory FlDragSelectionStartEvent.fromJson(Map<String, dynamic> json) {
    return FlDragSelectionStartEvent(
      (json['nodeIds'] as List).cast<String>().toSet(),
      Offset(json['position'][0], json['position'][1]),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

final class FlDragSelectionEvent extends FlGraphEditClassEvent
    with FlLayoutEventCat {
  final Set<String> nodeIds;
  final Offset delta;

  const FlDragSelectionEvent(
    this.nodeIds,
    this.delta, {
    required super.id,
    super.isHandled = false,
  });

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'nodeIds': nodeIds.toList(),
        'delta': [delta.dx, delta.dy],
      };

  factory FlDragSelectionEvent.fromJson(Map<String, dynamic> json) {
    return FlDragSelectionEvent(
      (json['nodeIds'] as List).cast<String>().toSet(),
      Offset(json['delta'][0], json['delta'][1]),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

final class FlDragSelectionEndEvent extends FlGraphEditClassEvent
    with FlLayoutEventCat {
  final Offset position;
  final Set<String> nodeIds;

  const FlDragSelectionEndEvent(
    this.position,
    this.nodeIds, {
    required super.id,
    super.isHandled = false,
  });

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'position': [position.dx, position.dy],
        'nodeIds': nodeIds.toList(),
      };

  factory FlDragSelectionEndEvent.fromJson(Map<String, dynamic> json) {
    return FlDragSelectionEndEvent(
      Offset(json['position'][0], json['position'][1]),
      (json['nodeIds'] as List).cast<String>().toSet(),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

////////////////////////////////////////////////////////////////////////
// Clipboard events
// (these are domain-level clipboard actions — treatment varies)
////////////////////////////////////////////////////////////////////////

final class FlCopySelectionEvent extends FlClipboardClassEvent {
  final String clipboardContent;

  const FlCopySelectionEvent(
    this.clipboardContent, {
    required super.id,
    super.isHandled = false,
  }) : super(isUndoable: true);
}

final class FlPasteSelectionEvent extends FlClipboardClassEvent
    with FlTreeEventCat, FlLayoutEventCat {
  final Offset position;
  final String clipboardContent;

  const FlPasteSelectionEvent(
    this.position,
    this.clipboardContent, {
    required super.id,
    super.isHandled = false,
  });
}

final class FlCutSelectionEvent extends FlClipboardClassEvent
    with FlTreeEventCat, FlLayoutEventCat {
  final String clipboardContent;

  const FlCutSelectionEvent(
    this.clipboardContent, {
    required super.id,
    super.isHandled = false,
  });
}

////////////////////////////////////////////////////////////////////////
// Hover events (no render side-effects beyond transient UI — NoRender)
////////////////////////////////////////////////////////////////////////

enum FlHoverEventType { enter, exit }

final class FlNodeHoverEvent extends FlVisualizationClassEvent
    with FlLayoutEventCat {
  final FlHoverEventType type;
  final String nodeId;

  const FlNodeHoverEvent(
    this.nodeId, {
    required this.type,
    required super.id,
    super.isHandled = false,
  });
}

////////////////////////////////////////////////////////////////////////
// Graph edit events (mutate graph — default to LayoutEvent; adjust if only paint)
////////////////////////////////////////////////////////////////////////

final class FlAddNodeEvent extends FlGraphEditClassEvent
    with FlTreeEventCat, FlLayoutEventCat {
  final FlNodeDataModel node;

  const FlAddNodeEvent(
    this.node, {
    required super.id,
    super.isHandled = false,
  });

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'node': node.toJson(dataHandlers),
      };

  factory FlAddNodeEvent.fromJson(
    Map<String, dynamic> json, {
    required FlNodesController controller,
  }) {
    return FlAddNodeEvent(
      FlNodeDataModel.fromJson(
        json['node'] as Map<String, dynamic>,
        nodePrototypes: controller.nodePrototypes,
        dataHandlers: controller.project.dataHandlers,
      ),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

final class FlRemoveNodeEvent extends FlGraphEditClassEvent
    with FlTreeEventCat, FlLayoutEventCat {
  final FlNodeDataModel node;

  const FlRemoveNodeEvent(
    this.node, {
    required super.id,
    super.isHandled = false,
  });

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'node': node.toJson(dataHandlers),
      };

  factory FlRemoveNodeEvent.fromJson(
    Map<String, dynamic> json, {
    required FlNodesController controller,
  }) {
    return FlRemoveNodeEvent(
      FlNodeDataModel.fromJson(
        json['node'] as Map<String, dynamic>,
        nodePrototypes: controller.nodePrototypes,
        dataHandlers: controller.project.dataHandlers,
      ),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

final class FlAddLinkEvent extends FlGraphEditClassEvent with FlPaintEventCat {
  final FlLinkDataModel link;

  const FlAddLinkEvent(
    this.link, {
    required super.id,
    super.isHandled = false,
  });

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'link': link.toJson(),
      };

  factory FlAddLinkEvent.fromJson(
    Map<String, dynamic> json,
    Map<Type, DataHandler> dataHandlers,
    FlLinkPrototype prototype,
  ) {
    return FlAddLinkEvent(
      FlLinkDataModel.fromJson(
        json['link'] as Map<String, dynamic>,
        dataHandlers,
        prototype,
      ),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

final class FlRemoveLinkEvent extends FlGraphEditClassEvent
    with FlPaintEventCat {
  final FlLinkDataModel link;

  const FlRemoveLinkEvent(
    this.link, {
    required super.id,
    super.isHandled = false,
  });

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'link': link.toJson(),
      };

  factory FlRemoveLinkEvent.fromJson(
    Map<String, dynamic> json,
    Map<Type, DataHandler> dataHandlers,
    FlLinkPrototype prototype,
  ) {
    return FlRemoveLinkEvent(
      FlLinkDataModel.fromJson(
        json['link'] as Map<String, dynamic>,
        dataHandlers,
        prototype,
      ),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

enum FlFieldEventType {
  change,
  submit,
  cancel,
}

final class FlNodeFieldEvent extends FlGraphEditClassEvent
    with FlLayoutEventCat {
  final String nodeId;
  final dynamic value;
  final FlFieldEventType eventType;

  const FlNodeFieldEvent(
    this.nodeId,
    this.value,
    this.eventType, {
    required super.id,
    super.isHandled = false,
  });
}

final class FlLinkLabelEvent extends FlGraphEditClassEvent
    with FlPaintEventCat {
  final String linkId;
  final String label;

  const FlLinkLabelEvent(
    this.linkId,
    this.label, {
    required super.id,
    super.isHandled = false,
  });
}

final class FlNodeCustomDataEvent extends FlGraphEditClassEvent {
  final String nodeId;
  final String key;
  final dynamic value;

  const FlNodeCustomDataEvent({
    required this.nodeId,
    required this.key,
    required this.value,
    required super.id,
    super.isHandled = false,
  });
}

final class FlNodeCustomDataPaintEvent extends FlGraphEditClassEvent
    with FlPaintEventCat {
  final String nodeId;
  final String key;
  final dynamic value;

  const FlNodeCustomDataPaintEvent({
    required this.nodeId,
    required this.key,
    required this.value,
    required super.id,
    super.isHandled = false,
  });
}

final class FlNodeCustomDataLayoutEvent extends FlGraphEditClassEvent
    with FlLayoutEventCat {
  final String nodeId;
  final String key;
  final dynamic value;

  const FlNodeCustomDataLayoutEvent({
    required this.nodeId,
    required this.key,
    required this.value,
    required super.id,
    super.isHandled = false,
  });
}

////////////////////////////////////////////////////////////////////////
// Visualization tweaks
////////////////////////////////////////////////////////////////////////

final class FlCollapseNodeEvent extends FlVisualizationClassEvent
    with FlLayoutEventCat {
  final bool collpased;
  final Set<String> nodeIds;

  const FlCollapseNodeEvent(
    this.collpased,
    this.nodeIds, {
    required super.id,
    super.isHandled = false,
  });
}

////////////////////////////////////////////////////////////////////////
/// Runner events
////////////////////////////////////////////////////////////////////////

final class FlGraphBuildStartEvent extends FlRunnerClassEvent {
  final DateTime startTime;

  const FlGraphBuildStartEvent({required super.id, required this.startTime});
}

final class FlGraphBuildCompleteEvent extends FlRunnerClassEvent {
  final Duration? timeTaken;

  const FlGraphBuildCompleteEvent({required super.id, this.timeTaken});
}

final class FlGraphBuildAbortedEvent extends FlRunnerClassEvent {
  final String reason;

  const FlGraphBuildAbortedEvent({required super.id, required this.reason});
}

final class FlGraphRunStartEvent extends FlRunnerClassEvent {
  final DateTime startTime;

  const FlGraphRunStartEvent({required super.id, required this.startTime});
}

final class FlGraphRunCompleteEvent extends FlRunnerClassEvent {
  final Duration? timeTaken;

  const FlGraphRunCompleteEvent({required super.id, this.timeTaken});
}

final class FlGraphRunAbortedEvent extends FlRunnerClassEvent {
  final String reason;

  const FlGraphRunAbortedEvent({required super.id, required this.reason});
}

final class FlNodeExecutionStateEvent extends FlRunnerClassEvent {
  final String nodeId;
  final FlNodeExecutionState state;

  const FlNodeExecutionStateEvent(
    this.nodeId,
    this.state, {
    required super.id,
  });
}

////////////////////////////////////////////////////////////////////////
// Project / Configuration / Styling events
////////////////////////////////////////////////////////////////////////

final class FlSaveProjectEvent extends FlProjectClassEvent {
  const FlSaveProjectEvent({required super.id});
}

final class FlLoadProjectEvent extends FlProjectClassEvent
    with FlTreeEventCat, FlLayoutEventCat {
  const FlLoadProjectEvent({required super.id});
}

final class FlNewProjectEvent extends FlProjectClassEvent
    with FlTreeEventCat, FlLayoutEventCat {
  const FlNewProjectEvent({required super.id});
}

final class FlConfigurationChangeEvent extends FlConfigurationClassEvent
    with FlTreeEventCat, FlLayoutEventCat {
  final FlNodesConfig config;

  const FlConfigurationChangeEvent(this.config, {required super.id});
}

final class FlStyleChangeEvent extends FlConfigurationClassEvent
    with FlLayoutEventCat {
  final FlNodesStyle style;

  const FlStyleChangeEvent(this.style, {required super.id});
}

final class FlLocaleChangeEvent extends FlConfigurationClassEvent
    with FlLayoutEventCat {
  final Locale locale;

  const FlLocaleChangeEvent(this.locale, {required super.id});
}

final class FlOverlayChangedEvent extends FlConfigurationClassEvent
    with FlPaintEventCat {
  final Set<String> idNames;

  const FlOverlayChangedEvent(this.idNames, {required super.id});
}

////////////////////////////////////////////////////////////////////////
// Temporary drawing / interaction events (paint-only or no-render)
////////////////////////////////////////////////////////////////////////

final class FlDrawTempLinkEvent extends FlTempInteractionClassEvent
    with FlPaintEventCat {
  final Offset startOffset;
  final Offset endOffset;

  const FlDrawTempLinkEvent(
    this.startOffset,
    this.endOffset, {
    required super.id,
    super.isHandled = false,
  });
}

final class FlAreaHighlightEvent extends FlTempInteractionClassEvent
    with FlPaintEventCat {
  final Rect? area;

  const FlAreaHighlightEvent(
    this.area, {
    required super.id,
    super.isHandled = false,
  });
}
