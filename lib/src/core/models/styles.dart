import 'package:flutter/material.dart';

class GridStyle {
  final double gridSpacingX;
  final double gridSpacingY;
  final double lineWidth;
  final Color lineColor;
  final Color intersectionColor;
  final double intersectionRadius;
  final bool showGrid;

  const GridStyle({
    this.gridSpacingX = 64.0,
    this.gridSpacingY = 64.0,
    this.lineWidth = 1.0,
    this.lineColor = Colors.transparent,
    this.intersectionColor = const Color(0xFF333333),
    this.intersectionRadius = 1,
    this.showGrid = true,
  });

  GridStyle copyWith({
    double? gridSpacingX,
    double? gridSpacingY,
    double? lineWidth,
    Color? lineColor,
    Color? intersectionColor,
    double? intersectionRadius,
    bool? showGrid,
  }) {
    return GridStyle(
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

enum LinkCurveType {
  straight,
  bezier,
  ninetyDegree,
}

enum LinkStyle {
  solid,
  dashed,
  dotted,
}

class NodeEditorStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final LinkCurveType linkCurveType;
  final LinkStyle linkStyle;
  final GridStyle gridStyle;

  const NodeEditorStyle({
    this.decoration = const BoxDecoration(
      color: Colors.transparent,
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.linkCurveType = LinkCurveType.bezier,
    this.linkStyle = LinkStyle.solid,
    required this.gridStyle,
  });

  NodeEditorStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    LinkCurveType? linkCurveType,
    LinkStyle? linkStyle,
    GridStyle? gridStyle,
  }) {
    return NodeEditorStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      linkCurveType: linkCurveType ?? this.linkCurveType,
      linkStyle: linkStyle ?? this.linkStyle,
      gridStyle: gridStyle ?? this.gridStyle,
    );
  }
}

class SearchStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final IconThemeData iconTheme;
  final Icon searchIcon;
  final Icon previousResultIcon;
  final Icon nextResultIcon;

  const SearchStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xFF212121),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.padding = const EdgeInsets.all(8.0),
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

  SearchStyle copyWith({
    BoxDecoration? decoration,
    TextStyle? textStyle,
    IconThemeData? iconTheme,
    Icon? searchIcon,
    Icon? previousResultIcon,
    Icon? nextResultIcon,
  }) {
    return SearchStyle(
      decoration: decoration ?? this.decoration,
      textStyle: textStyle ?? this.textStyle,
      iconTheme: iconTheme ?? this.iconTheme,
      searchIcon: searchIcon ?? this.searchIcon,
      previousResultIcon: previousResultIcon ?? this.previousResultIcon,
      nextResultIcon: nextResultIcon ?? this.nextResultIcon,
    );
  }
}

class HierarchyStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final BoxDecoration selectedDecoration;
  final TextStyle textStyle;

  const HierarchyStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xFF212121),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.selectedDecoration = const BoxDecoration(
      color: Colors.grey,
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
    ),
    this.textStyle = const TextStyle(
      color: Colors.white,
    ),
  });

  HierarchyStyle copyWith({
    BoxDecoration? decoration,
    BoxDecoration? selectedDecoration,
    TextStyle? textStyle,
  }) {
    return HierarchyStyle(
      decoration: decoration ?? this.decoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      textStyle: textStyle ?? this.textStyle,
    );
  }
}
