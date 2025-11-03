import 'package:fl_nodes_core/src/core/controller/core.dart';
import 'package:fl_nodes_core/src/core/models/data.dart';
import 'package:fl_nodes_core/src/styles/styles.dart';
import 'package:flutter/material.dart';

/// This file contains all the builders that can be used to fully customize the look of the package.

/// The style of the node header.
///
/// The header is the top part of the node that contains the title and the collapse button.
typedef NodeHeaderBuilder = Widget Function(
  BuildContext context,
  FlNodeDataModel node,
  FlNodeStyle style,
  VoidCallback onToggleCollapse,
);

/// The style of the node fields.
///
/// The fields are the widgets that display and allow to edit the data of the node.
typedef NodeFieldBuilder = Widget Function(
  BuildContext context,
  FlFieldDataModel field,
  FlNodeStyle style,
);

/// The style of the node ports.
///
/// The ports are the origin and destination points of the links.
typedef NodePortBuilder = Widget Function(
  BuildContext context,
  FlPortDataModel port,
  FlNodeStyle style,
);

/// The style of the node.
///
/// The node is the widget that contains the header, the fields and the ports.
///
/// WARNING: Only use this builder if you want to fully customize the look of the node.
typedef NodeBuilder = Widget Function(
  FlNodeDataModel node,
  FlNodesController controller,
);

typedef ShowPortContextMenu = void Function(
  BuildContext context,
  Offset position,
  FlNodesController controller,
  PortLocator locator,
);

typedef ShowNodeCreationtMenu = void Function(
  BuildContext context,
  Offset lastFocalPoint,
  FlNodesController controller,
  PortLocator? locator,
  void Function() onTmpLinkCancel,
);

typedef ShowNodeContextMenu = void Function(
  BuildContext context,
  Offset position,
  FlNodesController controller,
  FlNodeDataModel node,
);

typedef ShowCanvasContextMenu = void Function(
  BuildContext context,
  Offset position,
  FlNodesController controller,
  PortLocator? locator,
);
typedef ShowLinkContextMenu = void Function(
  BuildContext context,
  String linkId,
  Offset position,
  FlNodesController controller,
);
