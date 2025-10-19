import 'dart:ui';

import 'package:fl_nodes_core/src/core/models/data.dart';

import '../../styles/styles.dart';

class LinkPaintModel {
  final String linkId;
  final Offset outPortOffset;
  final Offset inPortOffset;
  final FlPortGeometricOrientation outPortGeometricOrientation;
  final FlPortGeometricOrientation inPortGeometricOrientation;
  final FlLinkStyle linkStyle;
  final String? labelText;
  final Rect? fromNodeBounds;
  final Rect? toNodeBounds;

  LinkPaintModel({
    required this.linkId,
    required this.outPortOffset,
    required this.inPortOffset,
    required this.outPortGeometricOrientation,
    required this.inPortGeometricOrientation,
    required this.linkStyle,
    this.labelText,
    this.fromNodeBounds,
    this.toNodeBounds,
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
