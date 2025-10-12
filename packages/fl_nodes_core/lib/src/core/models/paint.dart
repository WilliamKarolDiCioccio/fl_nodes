import 'dart:ui';

import 'package:fl_nodes_core/src/core/models/data.dart';

import '../../styles/styles.dart';

class LinkPaintModel {
  final String id;
  final Offset outPortOffset;
  final Offset inPortOffset;
  final FlLinkStyle linkStyle;

  LinkPaintModel({
    required this.id,
    required this.outPortOffset,
    required this.inPortOffset,
    required this.linkStyle,
  });
}

class PortPaintModel {
  final PortLocator locator;
  final bool isSelected;
  final Offset offset;
  final FlPortStyle style;

  PortPaintModel({
    required this.locator,
    required this.isSelected,
    required this.offset,
    required this.style,
  });
}
