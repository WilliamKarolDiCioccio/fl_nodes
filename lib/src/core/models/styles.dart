import 'package:flutter/material.dart';

class FlGridStyle {
  final double gridSpacingX;
  final double gridSpacingY;
  final double lineWidth;
  final Color lineColor;
  final Color intersectionColor;
  final double intersectionRadius;
  final bool showGrid;

  const FlGridStyle({
    this.gridSpacingX = 64.0,
    this.gridSpacingY = 64.0,
    this.lineWidth = 1.0,
    this.lineColor = Colors.transparent,
    this.intersectionColor = const Color(0xFF333333),
    this.intersectionRadius = 1,
    this.showGrid = true,
  });

  FlGridStyle copyWith({
    double? gridSpacingX,
    double? gridSpacingY,
    double? lineWidth,
    Color? lineColor,
    Color? intersectionColor,
    double? intersectionRadius,
    bool? showGrid,
  }) {
    return FlGridStyle(
      gridSpacingX: gridSpacingX ?? this.gridSpacingX,
      gridSpacingY: gridSpacingY ?? this.gridSpacingY,
      lineWidth: lineWidth ?? this.lineWidth,
      lineColor: lineColor ?? this.lineColor,
      intersectionColor: intersectionColor ?? this.intersectionColor,
      intersectionRadius: intersectionRadius ?? this.intersectionRadius,
      showGrid: showGrid ?? this.showGrid,
    );
  }
}

enum FlLinkCurveType {
  straight,
  bezier,
  ninetyDegree,
}

enum FlLinkStyle {
  solid,
  dashed,
  dotted,
}

class FlNodeEditorStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final FlLinkCurveType linkCurveType;
  final FlLinkStyle linkStyle;
  final FlGridStyle gridStyle;

  const FlNodeEditorStyle({
    this.decoration = const BoxDecoration(
      color: Colors.transparent,
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.linkCurveType = FlLinkCurveType.bezier,
    this.linkStyle = FlLinkStyle.solid,
    required this.gridStyle,
  });

  FlNodeEditorStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    FlLinkCurveType? linkCurveType,
    FlLinkStyle? linkStyle,
    FlGridStyle? gridStyle,
  }) {
    return FlNodeEditorStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      linkCurveType: linkCurveType ?? this.linkCurveType,
      linkStyle: linkStyle ?? this.linkStyle,
      gridStyle: gridStyle ?? this.gridStyle,
    );
  }
}

class FlSearchStyle {
  final BoxDecoration decoration;
  final TextStyle textStyle;
  final IconThemeData iconTheme;
  final Icon searchIcon;
  final Icon previousResultIcon;
  final Icon nextResultIcon;

  const FlSearchStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xFF212121),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.textStyle = const TextStyle(
      color: Colors.white,
    ),
    this.iconTheme = const IconThemeData(
      color: Colors.white,
    ),
    this.searchIcon = const Icon(Icons.search),
    this.previousResultIcon = const Icon(Icons.arrow_upward),
    this.nextResultIcon = const Icon(Icons.arrow_downward),
  });

  FlSearchStyle copyWith({
    BoxDecoration? decoration,
    TextStyle? textStyle,
    IconThemeData? iconTheme,
    Icon? searchIcon,
    Icon? previousResultIcon,
    Icon? nextResultIcon,
  }) {
    return FlSearchStyle(
      decoration: decoration ?? this.decoration,
      textStyle: textStyle ?? this.textStyle,
      iconTheme: iconTheme ?? this.iconTheme,
      searchIcon: searchIcon ?? this.searchIcon,
      previousResultIcon: previousResultIcon ?? this.previousResultIcon,
      nextResultIcon: nextResultIcon ?? this.nextResultIcon,
    );
  }
}

class FlHierarchyStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final BoxDecoration nodeDecoration;
  final BoxDecoration selectedNodeDecoration;
  final TextStyle textStyle;

  const FlHierarchyStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xFF212121),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.nodeDecoration = const BoxDecoration(
      color: Color(0xFF333333),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.selectedNodeDecoration = const BoxDecoration(
      color: Color(0xFF424242),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.textStyle = const TextStyle(
      color: Colors.white,
    ),
  });

  FlHierarchyStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    BoxDecoration? nodeDecoration,
    BoxDecoration? selectedNodeDecoration,
    TextStyle? textStyle,
  }) {
    return FlHierarchyStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      nodeDecoration: nodeDecoration ?? this.nodeDecoration,
      selectedNodeDecoration:
          selectedNodeDecoration ?? this.selectedNodeDecoration,
      textStyle: textStyle ?? this.textStyle,
    );
  }
}
