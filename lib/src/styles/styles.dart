import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/models/data.dart';

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
      : gridSpacingX = 64.0,
        gridSpacingY = 64.0,
        lineWidth = 1.0,
        lineColor = const Color.fromARGB(64, 100, 100, 100),
        intersectionColor = const Color.fromARGB(128, 150, 150, 150),
        intersectionRadius = 2,
        showGrid = true;

  const factory FlGridStyle.dense() = FlGridStyle._constDense;

  const FlGridStyle._constDense()
      : gridSpacingX = 32.0,
        gridSpacingY = 32.0,
        lineWidth = 0.5,
        lineColor = const Color.fromARGB(64, 120, 120, 120),
        intersectionColor = const Color.fromARGB(128, 180, 180, 180),
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
      : color = const Color.fromARGB(25, 33, 150, 243),
        borderWidth = 1.0,
        borderColor = const Color.fromARGB(255, 33, 150, 243),
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
      : color = Colors.blue,
        lineWidth = 2.0,
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
        color = Colors.blue,
        radius = 4,
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
          color: Color(0xFF424242),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

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
      : padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration = const BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(7),
            topRight: Radius.circular(7),
          ),
        ),
        textStyle = const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
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
          color: Color(0xC8424242),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );

  const factory FlNodeStyle.selected() = FlNodeStyle._constSelected;

  const FlNodeStyle._constSelected()
      : decoration = const BoxDecoration(
          color: Color(0xC7616161),
          borderRadius: BorderRadius.all(Radius.circular(8)),
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
      : const FlNodeStyle.basic();
}

class FlNodeEditorStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final FlGridStyle gridStyle;
  final FlHighlightAreaStyle highlightAreaStyle;

  const FlNodeEditorStyle({
    this.decoration = const BoxDecoration(
      color: Colors.black12,
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.gridStyle = const FlGridStyle.basic(),
    this.highlightAreaStyle = const FlHighlightAreaStyle.basic(),
  });

  FlNodeEditorStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    FlGridStyle? gridStyle,
    FlHighlightAreaStyle? highlightAreaStyle,
  }) {
    return FlNodeEditorStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      gridStyle: gridStyle ?? this.gridStyle,
      highlightAreaStyle: highlightAreaStyle ?? this.highlightAreaStyle,
    );
  }
}
