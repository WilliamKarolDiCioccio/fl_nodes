import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../fl_nodes.dart';

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

/// The content of the node context menu.
///
/// The context menu is the menu that appears when the user right-clicks (content depends on the entity being clicked).
typedef NodeContextMenuBuilder = List<ContextMenuEntry> Function(
  BuildContext context,
  FlNodeEditorController controller,
  FlNodeDataModel node,
);

/// The style of the node.
///
/// The node is the widget that contains the header, the fields and the ports.
///
/// WARNING: Only use this builder if you want to fully customize the look of the node.
typedef NodeBuilder = Widget Function(
  BuildContext context,
  FlNodeDataModel node,
);
