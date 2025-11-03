import 'package:fl_context_menu/src/core/models/config.dart';
import 'package:fl_context_menu/src/core/models/entries.dart';
import 'package:fl_context_menu/src/styles/styles.dart';
import 'package:fl_context_menu/src/widgets/context_menu_section.dart';
import 'package:flutter/material.dart';

class FlMenuWidget extends StatelessWidget {
  final FlMenuDataModel data;
  final Offset position;
  final FlMenuConfig config;
  final FlMenuStyle style;
  final int menuLevel;

  const FlMenuWidget({
    super.key,
    required this.data,
    required this.position,
    required this.config,
    required this.style,
    this.menuLevel = 1,
  });

  FlMenuStyle _resolveStyle(FlMenuStyle baseStyle, int level) {
    switch (level) {
      case 1:
        return baseStyle;
      case 2:
        return baseStyle.secondLevelMenuStyle ?? baseStyle;
      case 3:
        return baseStyle.thirdLevelMenuStyle ??
            baseStyle.secondLevelMenuStyle ??
            baseStyle;
      default:
        return baseStyle.nThLevelMenuStyle ??
            baseStyle.thirdLevelMenuStyle ??
            baseStyle.secondLevelMenuStyle ??
            baseStyle;
    }
  }

  Widget _buildMenuMaterial() {
    final resolvedStyle = _resolveStyle(style, menuLevel);
    final dividerStyle = resolvedStyle.dividerStyle;

    return Material(
      elevation: resolvedStyle.elevation,
      color: resolvedStyle.decoration.color ?? const Color(0xFF1E1E1E),
      borderRadius: resolvedStyle.decoration.borderRadius as BorderRadius? ??
          BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints(
          minWidth: config.minWidth,
          minHeight: config.minHeight,
          maxWidth: config.maxWidth,
          maxHeight: config.maxHeight,
        ),
        padding: resolvedStyle.padding,
        decoration: resolvedStyle.decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < data.sections.length; i++) ...[
              FlMenuSectionWidget(
                data: data.sections[i],
                style: resolvedStyle,
                menuLevel: menuLevel,
              ),
              if (i < data.sections.length - 1)
                Divider(
                  color: dividerStyle.color,
                  thickness: dividerStyle.thickness,
                  indent: dividerStyle.indent,
                  endIndent: dividerStyle.endIndent,
                  height: dividerStyle.thickness + 6,
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (menuLevel > 1) return _buildMenuMaterial();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: _buildMenuMaterial(),
        ),
      ],
    );
  }
}
