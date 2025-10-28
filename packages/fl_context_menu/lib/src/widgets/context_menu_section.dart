import 'package:fl_context_menu/src/core/models/entries.dart';
import 'package:fl_context_menu/src/styles/styles.dart';
import 'package:fl_context_menu/src/widgets/item_tile.dart';
import 'package:fl_context_menu/src/widgets/submenu_tile.dart';
import 'package:flutter/material.dart';

class FlMenuSectionWidget extends StatelessWidget {
  final FlMenuSectionDataModel data;
  final FlMenuStyle style;
  final int menuLevel;

  const FlMenuSectionWidget({
    super.key,
    required this.data,
    required this.style,
    required this.menuLevel,
  });

  FlMenuStyle _resolveNextLevelStyle(FlMenuStyle base, int nextLevel) {
    switch (nextLevel) {
      case 2:
        return base.secondLevelMenuStyle ?? base;
      case 3:
        return base.thirdLevelMenuStyle ?? base.secondLevelMenuStyle ?? base;
      default:
        return base.nThLevelMenuStyle ??
            base.thirdLevelMenuStyle ??
            base.secondLevelMenuStyle ??
            base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemStyle = style.itemStyle;

    return Padding(
      padding: data.padding ?? const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.label != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                data.label!,
                style: itemStyle.textStyle.copyWith(
                  fontSize: 12,
                  color: itemStyle.textStyle.color?.withAlpha(185),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          for (final entry in data.items)
            switch (entry) {
              // Simple menu item
              FlMenuItemDataModel(
                :final idName,
                :final label,
                :final icon,
                :final onPressed,
                :final isEnabled,
              ) =>
                FlMenuItemTile(
                  id: idName,
                  label: label,
                  iconData: icon,
                  onPressed: onPressed,
                  isEnabled: isEnabled,
                  style: itemStyle,
                ),

              // Submenu entry
              FlSubmenuDataModel(
                :final idName,
                :final label,
                :final icon,
                :final items,
              ) =>
                FlSubmenuTile(
                  id: idName,
                  label: label,
                  iconData: icon,
                  data: items,
                  menuLevel: menuLevel + 1,
                  parentStyle: style,
                  submenuStyle: _resolveNextLevelStyle(style, menuLevel + 1),
                ),

              // Fallback
              _ => const SizedBox.shrink(),
            },
        ],
      ),
    );
  }
}
