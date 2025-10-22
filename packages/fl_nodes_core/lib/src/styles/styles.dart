import 'package:flutter/material.dart';

import '../core/models/data.dart';

enum FlLineDrawMode {
  solid,
  dashed,
  dotted,
}

class FlGridStyle {
  final double gridSpacingX;
  final double gridSpacingY;
  final double lineWidth;
  final Color lineColor;
  final Color intersectionColor;
  final double intersectionRadius;
  final bool showGrid;

  const FlGridStyle({
    required this.gridSpacingX,
    required this.gridSpacingY,
    required this.lineWidth,
    required this.lineColor,
    required this.intersectionColor,
    required this.intersectionRadius,
    required this.showGrid,
  });

  const factory FlGridStyle.basic() = FlGridStyle._constBasic;

  const FlGridStyle._constBasic()
      : gridSpacingX = 48.0,
        gridSpacingY = 48.0,
        lineWidth = 0.8,
        lineColor = const Color.fromARGB(80, 120, 144, 156),
        intersectionColor = const Color.fromARGB(120, 144, 164, 174),
        intersectionRadius = 1.5,
        showGrid = true;

  const factory FlGridStyle.dense() = FlGridStyle._constDense;

  const FlGridStyle._constDense()
      : gridSpacingX = 24.0,
        gridSpacingY = 24.0,
        lineWidth = 0.6,
        lineColor = const Color.fromARGB(60, 120, 144, 156),
        intersectionColor = const Color.fromARGB(100, 144, 164, 174),
        intersectionRadius = 1,
        showGrid = true;

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

class FlHighlightAreaStyle {
  final Color color;
  final double borderWidth;
  final Color borderColor;
  final FlLineDrawMode borderDrawMode;

  const FlHighlightAreaStyle({
    required this.color,
    required this.borderWidth,
    required this.borderColor,
    required this.borderDrawMode,
  });

  const factory FlHighlightAreaStyle.basic() = FlHighlightAreaStyle._constBasic;

  const FlHighlightAreaStyle._constBasic()
      : color = const Color.fromARGB(30, 41, 121, 255),
        borderWidth = 1.5,
        borderColor = const Color.fromARGB(180, 41, 121, 255),
        borderDrawMode = FlLineDrawMode.solid;

  FlHighlightAreaStyle copyWith({
    Color? color,
    double? borderWidth,
    Color? borderColor,
    FlLineDrawMode? borderDrawMode,
  }) {
    return FlHighlightAreaStyle(
      color: color ?? this.color,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      borderDrawMode: borderDrawMode ?? this.borderDrawMode,
    );
  }
}

enum FlLinkCurveType {
  straight,
  bezier,
  ninetyDegree,
}

class FlLinkStyle {
  final Color? color;
  final LinearGradient? gradient;
  final double lineWidth;
  final FlLineDrawMode drawMode;
  final FlLinkCurveType curveType;

  const FlLinkStyle({
    this.color,
    this.gradient,
    required this.lineWidth,
    required this.drawMode,
    required this.curveType,
  });

  const factory FlLinkStyle.basic() = FlLinkStyle._constBasic;

  const FlLinkStyle._constBasic()
      : color = const Color(0xFF42A5F5),
        lineWidth = 2.5,
        drawMode = FlLineDrawMode.solid,
        gradient = null,
        curveType = FlLinkCurveType.bezier;

  const FlLinkStyle.gradient({
    required this.gradient,
    required this.lineWidth,
    required this.drawMode,
    required this.curveType,
  }) : color = null;

  FlLinkStyle copyWith({
    Color? color,
    double? lineWidth,
    FlLineDrawMode? drawMode,
    FlLinkCurveType? curveType,
  }) {
    return FlLinkStyle(
      color: color ?? this.color,
      lineWidth: lineWidth ?? this.lineWidth,
      drawMode: drawMode ?? this.drawMode,
      curveType: curveType ?? this.curveType,
    );
  }

  FlLinkStyle copyWithGradient({
    required LinearGradient gradient,
    double? lineWidth,
    FlLineDrawMode? drawMode,
    FlLinkCurveType? curveType,
  }) {
    return FlLinkStyle.gradient(
      gradient: gradient,
      lineWidth: lineWidth ?? this.lineWidth,
      drawMode: drawMode ?? this.drawMode,
      curveType: curveType ?? this.curveType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FlLinkStyle) return false;
    if (gradient != null || other.gradient != null) return false;

    return color == other.color &&
        lineWidth == other.lineWidth &&
        drawMode == other.drawMode &&
        curveType == other.curveType;
  }

  @override
  int get hashCode =>
      color.hashCode ^
      lineWidth.hashCode ^
      drawMode.hashCode ^
      curveType.hashCode;
}

typedef LinkStyleBuilder = FlLinkStyle Function(FlLinkState style);

FlLinkStyle flDefaultLinkStyleBuilder(FlLinkState state) =>
    const FlLinkStyle.basic();

enum FlPortShape {
  circle,
  triangle,
}

class FlPortStyle {
  final FlPortShape shape;
  final Color color;
  final double radius;
  final LinkStyleBuilder linkStyleBuilder;

  const FlPortStyle({
    required this.shape,
    required this.color,
    required this.radius,
    required this.linkStyleBuilder,
  });

  const factory FlPortStyle.basic() = FlPortStyle._constBasic;

  const FlPortStyle._constBasic()
      : shape = FlPortShape.circle,
        color = const Color(0xFF42A5F5),
        radius = 5,
        linkStyleBuilder = flDefaultLinkStyleBuilder;

  FlPortStyle copyWith({
    FlPortShape? shape,
    Color? color,
    LinkStyleBuilder? linkStyleBuilder,
    double? radius,
  }) {
    return FlPortStyle(
      shape: shape ?? this.shape,
      color: color ?? this.color,
      radius: radius ?? this.radius,
      linkStyleBuilder: linkStyleBuilder ?? this.linkStyleBuilder,
    );
  }
}

typedef PortStyleBuilder = FlPortStyle Function(FlPortState style);

FlPortStyle flDefaultPortStyleBuilder(FlPortState state) =>
    const FlPortStyle.basic();

class FlFieldStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;

  const FlFieldStyle({
    required this.decoration,
    required this.padding,
  });

  const factory FlFieldStyle.basic() = FlFieldStyle._constBasic;

  const FlFieldStyle._constBasic()
      : decoration = const BoxDecoration(
          color: Color(0xFF37474F),
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.fromBorderSide(
            BorderSide(
              color: Color(0xFF546E7A),
              width: 1.0,
            ),
          ),
        ),
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  FlFieldStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
  }) {
    return FlFieldStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
    );
  }
}

class FlNodeHeaderStyle {
  final EdgeInsets padding;
  final BoxDecoration decoration;
  final TextStyle textStyle;
  final IconData? icon;

  const FlNodeHeaderStyle({
    required this.padding,
    required this.decoration,
    required this.textStyle,
    required this.icon,
  });

  const factory FlNodeHeaderStyle.basic() = FlNodeHeaderStyle._constBasic;

  const FlNodeHeaderStyle._constBasic()
      : padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration = const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        textStyle = const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        icon = Icons.expand_more;

  FlNodeHeaderStyle copyWith({
    EdgeInsets? padding,
    BoxDecoration? decoration,
    TextStyle? textStyle,
    IconData? icon,
  }) {
    return FlNodeHeaderStyle(
      padding: padding ?? this.padding,
      decoration: decoration ?? this.decoration,
      textStyle: textStyle ?? this.textStyle,
      icon: icon ?? this.icon,
    );
  }
}

typedef NodeHeaderStyleBuilder = FlNodeHeaderStyle Function(
  FlNodeState style,
);

FlNodeHeaderStyle flDefaultNodeHeaderStyleBuilder(FlNodeState state) =>
    const FlNodeHeaderStyle.basic();

class FlNodeStyle {
  final BoxDecoration decoration;

  const FlNodeStyle({
    required this.decoration,
  });

  const factory FlNodeStyle.basic() = FlNodeStyle._constBasic;

  const FlNodeStyle._constBasic()
      : decoration = const BoxDecoration(
          color: Color(0xE6263238),
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.fromBorderSide(
            BorderSide(
              color: Color(0xFF37474F),
              width: 1.5,
            ),
          ),
        );

  const factory FlNodeStyle.selected() = FlNodeStyle._constSelected;

  const FlNodeStyle._constSelected()
      : decoration = const BoxDecoration(
          color: Color(0xE6263238),
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.fromBorderSide(
            BorderSide(
              color: Color(0xFF42A5F5),
              width: 2.5,
            ),
          ),
        );

  const factory FlNodeStyle.hovered() = FlNodeStyle._constHovered;

  const FlNodeStyle._constHovered()
      : decoration = const BoxDecoration(
          color: Color(0xE6263238),
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.fromBorderSide(
            BorderSide(
              color: Color(0xFF64B5F6),
              width: 2.0,
            ),
          ),
        );

  FlNodeStyle copyWith({
    BoxDecoration? decoration,
  }) {
    return FlNodeStyle(
      decoration: decoration ?? this.decoration,
    );
  }
}

typedef NodeStyleBuilder = FlNodeStyle Function(FlNodeState style);

FlNodeStyle flDefaultNodeStyleBuilder(FlNodeState state) {
  return state.isSelected
      ? const FlNodeStyle.selected()
      : state.isHovered
          ? const FlNodeStyle.hovered()
          : const FlNodeStyle.basic();
}

class FlNodesStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final FlGridStyle gridStyle;
  final FlHighlightAreaStyle highlightAreaStyle;

  const FlNodesStyle({
    this.decoration = const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF1A1A1A),
          Color(0xFF0D1117),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    this.padding = const EdgeInsets.all(0.0),
    this.gridStyle = const FlGridStyle.basic(),
    this.highlightAreaStyle = const FlHighlightAreaStyle.basic(),
  });

  FlNodesStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    FlGridStyle? gridStyle,
    FlHighlightAreaStyle? highlightAreaStyle,
  }) {
    return FlNodesStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      gridStyle: gridStyle ?? this.gridStyle,
      highlightAreaStyle: highlightAreaStyle ?? this.highlightAreaStyle,
    );
  }
}
