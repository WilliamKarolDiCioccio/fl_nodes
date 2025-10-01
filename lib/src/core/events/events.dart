import 'package:fl_nodes/src/core/controller/core.dart';
import 'package:fl_nodes/src/core/controller/project.dart';
import 'package:fl_nodes/src/core/models/data.dart';
import 'package:fl_nodes/src/styles/styles.dart';
import 'package:flutter/material.dart';

///
/// It includes an [id] to identify the event, a [isHandled] flag to indicate if the event has been handled,
/// and an [isUndoable] flag to indicate if the event can be undone.
@immutable
abstract base class NodeEditorEvent {
  final String id;
  final bool isHandled;
  final bool isUndoable;

  const NodeEditorEvent({
    required this.id,
    this.isHandled = false,
    this.isUndoable = false,
  });

  Map<String, dynamic> toJson(Map<String, DataHandler> dataHandlers) => {
        'id': id,
        'isHandled': isHandled,
        'isUndoable': isUndoable,
      };
}

////////////////////////////////////////////////////////////////////////
/// Viewport events.
////////////////////////////////////////////////////////////////////////

/// Event produced when the viewport offset changes.
final class FlViewportOffsetEvent extends NodeEditorEvent {
  final Offset offset;
  final bool animate;

  const FlViewportOffsetEvent(
    this.offset, {
    this.animate = true,
    required super.id,
    super.isHandled,
  });
}

/// Event produced when the viewport zoom level changes.
final class FlViewportZoomEvent extends NodeEditorEvent {
  final double zoom;
  final bool animate;

  const FlViewportZoomEvent(
    this.zoom, {
    this.animate = true,
    required super.id,
    super.isHandled,
  });
}

////////////////////////////////////////////////////////////////////////
/// Selection events.
////////////////////////////////////////////////////////////////////////

enum FlSelectionEventType {
  select,
  holdSelect,
  deselect,
}

/// Event produced when nodes are selected or deselected.
final class FlNodeSelectionEvent extends NodeEditorEvent {
  final FlSelectionEventType type;
  final Set<String> nodeIds;

  const FlNodeSelectionEvent(
    this.nodeIds, {
    required this.type,
    required super.id,
    super.isHandled,
  });
}

/// Event produced when the user starts dragging a group of selected nodes.
final class FlDragSelectionStartEvent extends NodeEditorEvent {
  final Set<String> nodeIds;
  final Offset position;

  const FlDragSelectionStartEvent(
    this.nodeIds,
    this.position, {
    required super.id,
    super.isHandled,
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

/// Event produced to update the position of a group of selected nodes while dragging.
final class FlDragSelectionEvent extends NodeEditorEvent {
  final Set<String> nodeIds;
  final Offset delta;

  const FlDragSelectionEvent(
    this.nodeIds,
    this.delta, {
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);

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

/// Event produced when the user stops dragging a group of selected nodes.
final class FlDragSelectionEndEvent extends NodeEditorEvent {
  final Offset position;
  final Set<String> nodeIds;

  const FlDragSelectionEndEvent(
    this.position,
    this.nodeIds, {
    required super.id,
    super.isHandled,
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

/// Event produced when the user selects or deselects a group of links (one or more).
final class FlLinkSelectionEvent extends NodeEditorEvent {
  final FlSelectionEventType type;
  final Set<String> linkIds;

  const FlLinkSelectionEvent(
    this.linkIds, {
    required this.type,
    required super.id,
    super.isHandled,
  });
}

/// Event produced when the user copies a selection to the clipboard (Ctrl+C).
final class FlCopySelectionEvent extends NodeEditorEvent {
  final String clipboardContent;

  const FlCopySelectionEvent(
    this.clipboardContent, {
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);
}

/// Event produced when the user pastes a selection from the clipboard (Ctrl+V).
final class FlPasteSelectionEvent extends NodeEditorEvent {
  final Offset position;
  final String clipboardContent;

  const FlPasteSelectionEvent(
    this.position,
    this.clipboardContent, {
    required super.id,
    super.isHandled,
  });
}

/// Event produced when the user cuts a selection to the clipboard (Ctrl+X).
final class FlCutSelectionEvent extends NodeEditorEvent {
  final String clipboardContent;

  const FlCutSelectionEvent(
    this.clipboardContent, {
    required super.id,
    super.isHandled,
  });
}

////////////////////////////////////////////////////////////////////////
/// Hover events.
////////////////////////////////////////////////////////////////////////

enum FlHoverEventType {
  enter,
  exit,
}

/// Event produced when the user enters or exits the bounds of a node.
final class FlNodeHoverEvent extends NodeEditorEvent {
  final FlHoverEventType type;
  final String nodeId;

  const FlNodeHoverEvent(
    this.nodeId, {
    required this.type,
    required super.id,
    super.isHandled,
  });
}

// NOTE: We don't have hover events for links and ports because they are not widgets and therefore
// they do not require state management and are managed directly in the render object. Moreover,
// hover events in general cannot be produced from the controller.

////////////////////////////////////////////////////////////////////////
/// Nodes, groups and links management events.
////////////////////////////////////////////////////////////////////////

/// Event produced when the user creates a new node.
final class FlAddNodeEvent extends NodeEditorEvent {
  final FlNodeDataModel node;

  const FlAddNodeEvent(
    this.node, {
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'node': node.toJson(dataHandlers),
      };

  factory FlAddNodeEvent.fromJson(
    Map<String, dynamic> json, {
    required FlNodeEditorController controller,
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

/// Event produced when the user removes a node.
final class FlRemoveNodeEvent extends NodeEditorEvent {
  final FlNodeDataModel node;

  const FlRemoveNodeEvent(this.node, {required super.id, super.isHandled})
      : super(isUndoable: true);

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'node': node.toJson(dataHandlers),
      };

  factory FlRemoveNodeEvent.fromJson(
    Map<String, dynamic> json, {
    required FlNodeEditorController controller,
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

/// Event produced when the creates a new link between two nodes.
final class FlAddLinkEvent extends NodeEditorEvent {
  final FlLinkDataModel link;

  const FlAddLinkEvent(
    this.link, {
    required super.id,
    super.isHandled,
  }) : super(isUndoable: true);

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'link': link.toJson(),
      };

  factory FlAddLinkEvent.fromJson(Map<String, dynamic> json) {
    return FlAddLinkEvent(
      FlLinkDataModel.fromJson(json['link'] as Map<String, dynamic>),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

/// Event produced when the user removes a link between two nodes.
final class FlRemoveLinkEvent extends NodeEditorEvent {
  final FlLinkDataModel link;

  const FlRemoveLinkEvent(this.link, {required super.id, super.isHandled})
      : super(isUndoable: true);

  @override
  Map<String, dynamic> toJson(dataHandlers) => {
        ...super.toJson(dataHandlers),
        'link': link.toJson(),
      };

  factory FlRemoveLinkEvent.fromJson(Map<String, dynamic> json) {
    return FlRemoveLinkEvent(
      FlLinkDataModel.fromJson(json['link'] as Map<String, dynamic>),
      id: json['id'] as String,
      isHandled: json['isHandled'] as bool,
    );
  }
}

/// Event produced when the user collapses or expands a group of nodes (can be used for any widget changes that require layout updates).
final class FlCollapseNodeEvent extends NodeEditorEvent {
  final bool collpased;
  final Set<String> nodeIds;

  const FlCollapseNodeEvent(
    this.collpased,
    this.nodeIds, {
    required super.id,
    super.isHandled,
  });
}

enum FlFieldEventType {
  change,
  submit,
  cancel,
}

/// Event produced when the user changes a field value in a node.
final class FlNodeFieldEvent extends NodeEditorEvent {
  final String nodeId;
  final dynamic value;
  final FlFieldEventType eventType;

  const FlNodeFieldEvent(
    this.nodeId,
    this.value,
    this.eventType, {
    required super.id,
    super.isHandled,
  });
}

////////////////////////////////////////////////////////////////////////
/// Project management events.
////////////////////////////////////////////////////////////////////////

/// Event produced when the user saves the current project (Ctrl+S).
final class FlSaveProjectEvent extends NodeEditorEvent {
  const FlSaveProjectEvent({required super.id});
}

/// Event produced when the user loads a project (Ctrl+O).
final class FlLoadProjectEvent extends NodeEditorEvent {
  const FlLoadProjectEvent({required super.id});
}

/// Event produced when the user creates a new project (Ctrl+Shift+N).
final class FlNewProjectEvent extends NodeEditorEvent {
  const FlNewProjectEvent({required super.id});
}

////////////////////////////////////////////////////////////////////////
/// Temporary drawing events.
////////////////////////////////////////////////////////////////////////

/// Event produced to update the path of the link being drawn when the user drags from a port to create a new link.
final class FlDrawTempLinkEvent extends NodeEditorEvent {
  final Offset from;
  final Offset to;

  const FlDrawTempLinkEvent(
    this.from,
    this.to, {
    required super.id,
    super.isHandled,
  });
}

/// Event produced when an area is highlighted in the editor viewport (leads to selection).
final class FlAreaHighlightEvent extends NodeEditorEvent {
  final Rect? area;

  const FlAreaHighlightEvent(this.area, {required super.id, super.isHandled});
}

/// Event produced when the user changes the configuration of the node editor.
final class FlConfigurationChangeEvent extends NodeEditorEvent {
  final FlNodeEditorConfig config;

  const FlConfigurationChangeEvent(this.config, {required super.id});
}

/// Event produced when the user changes the style of the node editor.
final class FlStyleChangeEvent extends NodeEditorEvent {
  final FlNodeEditorStyle style;

  const FlStyleChangeEvent(this.style, {required super.id});
}

/// Event produced when the user changes the locale of the node editor.
final class FlLocaleChangeEvent extends NodeEditorEvent {
  final Locale locale;

  const FlLocaleChangeEvent(this.locale, {required super.id});
}
