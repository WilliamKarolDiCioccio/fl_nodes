import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/models/entities.dart';

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
    this.gridSpacingX = 64.0,
    this.gridSpacingY = 64.0,
    this.lineWidth = 1.0,
    this.lineColor = const Color.fromARGB(64, 100, 100, 100),
    this.intersectionColor = const Color.fromARGB(128, 150, 150, 150),
    this.intersectionRadius = 2,
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

class FlSelectionAreaStyle {
  final Color color;
  final double borderWidth;
  final Color borderColor;
  final FlLineDrawMode borderDrawMode;

  const FlSelectionAreaStyle({
    this.color = const Color.fromARGB(25, 33, 150, 243),
    this.borderWidth = 1.0,
    this.borderColor = const Color.fromARGB(255, 33, 150, 243),
    this.borderDrawMode = FlLineDrawMode.solid,
  });

  FlSelectionAreaStyle copyWith({
    Color? color,
    double? borderWidth,
    Color? borderColor,
    FlLineDrawMode? borderDrawMode,
  }) {
    return FlSelectionAreaStyle(
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
    required this.color,
    required this.lineWidth,
    required this.drawMode,
    required this.curveType,
  }) : gradient = null;

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

typedef FlLinkStyleBuilder = FlLinkStyle Function(LinkState style);

FlLinkStyle defaultLinkStyle(LinkState state) {
  return const FlLinkStyle(
    color: Colors.blue,
    lineWidth: 2.0,
    drawMode: FlLineDrawMode.solid,
    curveType: FlLinkCurveType.bezier,
  );
}

enum FlPortShape {
  circle,
  triangle,
}

class FlPortStyle {
  final FlPortShape shape;
  final Color color;
  final double radius;
  final FlLinkStyleBuilder linkStyleBuilder;

  const FlPortStyle({
    this.shape = FlPortShape.circle,
    this.color = Colors.blue,
    this.radius = 4,
    this.linkStyleBuilder = defaultLinkStyle,
  });

  FlPortStyle copyWith({
    FlPortShape? shape,
    Color? color,
    FlLinkStyleBuilder? linkStyleBuilder,
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

typedef FlPortStyleBuilder = FlPortStyle Function(PortState style);

FlPortStyle defaultPortStyle(PortState state) {
  return FlPortStyle(
    shape: FlPortShape.circle,
    color: state.isHovered ? Colors.red : Colors.blue,
    radius: 4,
    linkStyleBuilder: defaultLinkStyle,
  );
}

class FlFieldStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;

  const FlFieldStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xFF424242),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

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

typedef FlNodeHeaderStyleBuilder = FlNodeHeaderStyle Function(NodeState style);

FlNodeHeaderStyle defaultNodeHeaderStyle(NodeState state) {
  return FlNodeHeaderStyle(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(7),
        topRight: Radius.circular(7),
      ),
    ),
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    icon: state.isCollapsed ? Icons.expand_more : Icons.expand_less,
  );
}

class FlNodeStyle {
  final BoxDecoration decoration;

  const FlNodeStyle({
    required this.decoration,
  });

  FlNodeStyle copyWith({
    BoxDecoration? decoration,
  }) {
    return FlNodeStyle(
      decoration: decoration ?? this.decoration,
    );
  }
}

typedef FlNodeStyleBuilder = FlNodeStyle Function(NodeState style);

FlNodeStyle defaultNodeStyle(NodeState state) {
  return FlNodeStyle(
    decoration: state.isSelected
        ? const BoxDecoration(
            color: Color(0xC7616161),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          )
        : const BoxDecoration(
            color: Color(0xC8424242),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
  );
}

class FlNodeEditorStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final FlGridStyle gridStyle;
  final FlSelectionAreaStyle selectionAreaStyle;

  const FlNodeEditorStyle({
    this.decoration = const BoxDecoration(
      color: Colors.black12,
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.gridStyle = const FlGridStyle(),
    this.selectionAreaStyle = const FlSelectionAreaStyle(),
  });

  FlNodeEditorStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    FlGridStyle? gridStyle,
    FlSelectionAreaStyle? selectionAreaStyle,
  }) {
    return FlNodeEditorStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      gridStyle: gridStyle ?? this.gridStyle,
      selectionAreaStyle: selectionAreaStyle ?? this.selectionAreaStyle,
    );
  }
}
