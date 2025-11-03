import 'package:flutter/material.dart';

/// Style for individual context menu items.
class FlMenuItemStyle {
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final Color hoverColor;
  final Color disabledColor;

  const FlMenuItemStyle({
    required this.textStyle,
    required this.padding,
    required this.iconSize,
    required this.hoverColor,
    required this.disabledColor,
  });

  /// Basic item appearance.
  const factory FlMenuItemStyle.basic() = FlMenuItemStyle._constBasic;

  const FlMenuItemStyle._constBasic()
      : textStyle = const TextStyle(color: Colors.white, fontSize: 14),
        padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        iconSize = 16.0,
        hoverColor = const Color(0x33FFFFFF),
        disabledColor = const Color(0x66FFFFFF);
}

/// Style for a context menu divider.
class FlMenuDividerStyle {
  final Color color;
  final double thickness;
  final double indent;
  final double endIndent;

  const FlMenuDividerStyle({
    this.color = const Color(0xFF424242),
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  /// Basic divider appearance.
  const factory FlMenuDividerStyle.basic() = FlMenuDividerStyle._constBasic;

  const FlMenuDividerStyle._constBasic()
      : color = const Color(0xFF424242),
        thickness = 1.0,
        indent = 0.0,
        endIndent = 0.0;

  FlMenuDividerStyle copyWith({
    Color? color,
    double? thickness,
    double? indent,
    double? endIndent,
  }) {
    return FlMenuDividerStyle(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      indent: indent ?? this.indent,
      endIndent: endIndent ?? this.endIndent,
    );
  }
}

/// Style configuration for a search bar within the context menu.
class FlSearchBarStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final String hintText;
  final TextStyle hintStyle;

  const FlSearchBarStyle({
    required this.decoration,
    required this.padding,
    required this.textStyle,
    required this.hintText,
    required this.hintStyle,
  });

  /// Basic search bar appearance.
  const factory FlSearchBarStyle.basic() = FlSearchBarStyle._constBasic;

  const FlSearchBarStyle._constBasic()
      : decoration = const BoxDecoration(
          color: Color(0xFF2C2C2C),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        padding = const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        textStyle = const TextStyle(color: Colors.white, fontSize: 14),
        hintText = 'Search...',
        hintStyle = const TextStyle(color: Colors.white54, fontSize: 14);

  FlSearchBarStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    String? hintText,
    TextStyle? hintStyle,
  }) {
    return FlSearchBarStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      hintText: hintText ?? this.hintText,
      hintStyle: hintStyle ?? this.hintStyle,
    );
  }
}

/// Style configuration for a single context menu.
class FlMenuStyle {
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final FlMenuItemStyle itemStyle;
  final FlMenuDividerStyle dividerStyle;
  final FlSearchBarStyle searchBarStyle;
  final FlMenuStyle? secondLevelMenuStyle;
  final FlMenuStyle? thirdLevelMenuStyle;
  final FlMenuStyle? nThLevelMenuStyle;

  const FlMenuStyle({
    required this.decoration,
    required this.padding,
    required this.elevation,
    required this.itemStyle,
    required this.dividerStyle,
    required this.searchBarStyle,
    this.secondLevelMenuStyle,
    this.thirdLevelMenuStyle,
    this.nThLevelMenuStyle,
  });

  /// Basic menu appearance.
  const factory FlMenuStyle.basic() = FlMenuStyle._constBasic;

  const FlMenuStyle._constBasic()
      : decoration = const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.all(Radius.circular(10)),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFF2C2C2C), width: 1.2),
          ),
        ),
        padding = const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        elevation = 4.0,
        itemStyle = const FlMenuItemStyle.basic(),
        dividerStyle = const FlMenuDividerStyle.basic(),
        searchBarStyle = const FlSearchBarStyle.basic(),
        secondLevelMenuStyle = null,
        thirdLevelMenuStyle = null,
        nThLevelMenuStyle = null;

  FlMenuStyle copyWith({
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    double? elevation,
    FlMenuItemStyle? itemStyle,
    FlMenuDividerStyle? dividerStyle,
    FlSearchBarStyle? searchBarStyle,
    FlMenuStyle? secondLevelMenuStyle,
    FlMenuStyle? thirdLevelMenuStyle,
    FlMenuStyle? nThLevelMenuStyle,
  }) {
    return FlMenuStyle(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      elevation: elevation ?? this.elevation,
      itemStyle: itemStyle ?? this.itemStyle,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      searchBarStyle: searchBarStyle ?? this.searchBarStyle,
      secondLevelMenuStyle: secondLevelMenuStyle ?? this.secondLevelMenuStyle,
      thirdLevelMenuStyle: thirdLevelMenuStyle ?? this.thirdLevelMenuStyle,
      nThLevelMenuStyle: nThLevelMenuStyle ?? this.nThLevelMenuStyle,
    );
  }
}
