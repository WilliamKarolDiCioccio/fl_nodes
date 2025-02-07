import 'package:flutter/material.dart';

import 'entities.dart';

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

enum FlLinkCurveType {
  straight,
  bezier,
  ninetyDegree,
}

enum FlLinkDrawMode {
  solid,
  dashed,
  dotted,
}

class FlLinkStyle {
  final double lineWidth;
  final FlLinkDrawMode drawMode;
  final FlLinkCurveType curveType;

  const FlLinkStyle({
    this.lineWidth = 3.0,
    this.drawMode = FlLinkDrawMode.solid,
    this.curveType = FlLinkCurveType.bezier,
  });

  FlLinkStyle copyWith({
    double? lineWidth,
    FlLinkDrawMode? drawMode,
    FlLinkCurveType? curveType,
  }) {
    return FlLinkStyle(
      lineWidth: lineWidth ?? this.lineWidth,
      drawMode: drawMode ?? this.drawMode,
      curveType: curveType ?? this.curveType,
    );
  }
}

class FlPortStyle {
  final Map<PortType, Map<PortDirection, Color>> color;

  const FlPortStyle({
    this.color = const {
      PortType.data: {
        PortDirection.input: Color(0xFF6C63FF), // Soft Purple
        PortDirection.output: Color(0xFFFF6584), // Coral Pink
      },
      PortType.control: {
        PortDirection.input: Color(0xFF4CAF50), // Green
        PortDirection.output: Color(0xFF2196F3), // Blue
      },
    },
  });
}

class FlFieldStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;

  const FlFieldStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xFF37474F), // Dark Blue Grey
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  });
}

class FlNodeStyle {
  final BoxDecoration decoration;
  final BoxDecoration selectedDecoration;
  final FlLinkStyle linkStyle;
  final FlPortStyle portStyle;
  final FlFieldStyle fieldStyle;

  const FlNodeStyle({
    this.decoration = const BoxDecoration(
      color: Color(0xC8424242), // Dark Grey
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    this.selectedDecoration = const BoxDecoration(
      color: Color(0xC7616161), // Medium Grey
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    this.linkStyle = const FlLinkStyle(),
    this.portStyle = const FlPortStyle(),
    this.fieldStyle = const FlFieldStyle(),
  });

  FlNodeStyle copyWith({
    BoxDecoration? decoration,
    BoxDecoration? selectedDecoration,
    FlLinkStyle? linkStyle,
    FlPortStyle? portStyle,
    FlFieldStyle? fieldStyle,
  }) {
    return FlNodeStyle(
      decoration: decoration ?? this.decoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      linkStyle: linkStyle ?? this.linkStyle,
      portStyle: portStyle ?? this.portStyle,
      fieldStyle: fieldStyle ?? this.fieldStyle,
    );
  }
}

class FlNodeEditorStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final FlGridStyle gridStyle;
  final FlNodeStyle nodeStyle;

  const FlNodeEditorStyle({
    this.decoration = const BoxDecoration(
      color: Colors.black12, // Slightly dark background
    ),
    this.padding = const EdgeInsets.all(8.0),
    this.gridStyle = const FlGridStyle(),
    this.nodeStyle = const FlNodeStyle(),
  });

  FlNodeEditorStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    FlGridStyle? gridStyle,
    FlNodeStyle? nodeStyle,
  }) {
    return FlNodeEditorStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      gridStyle: gridStyle ?? this.gridStyle,
      nodeStyle: nodeStyle ?? this.nodeStyle,
    );
  }
}
