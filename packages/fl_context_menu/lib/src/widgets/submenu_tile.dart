import 'package:fl_context_menu/src/core/models/config.dart';
import 'package:fl_context_menu/src/core/models/entries.dart';
import 'package:fl_context_menu/src/styles/styles.dart';
import 'package:fl_context_menu/src/widgets/context_menu.dart';
import 'package:flutter/material.dart';

class FlSubmenuTile extends StatefulWidget {
  final String id;
  final String? label;
  final IconData? iconData;
  final List<FlMenuEntryDataModel> data;
  final int menuLevel;
  final FlMenuStyle parentStyle;
  final FlMenuStyle submenuStyle;

  const FlSubmenuTile({
    super.key,
    required this.id,
    this.label,
    this.iconData,
    required this.data,
    required this.menuLevel,
    required this.parentStyle,
    required this.submenuStyle,
  });

  @override
  State<FlSubmenuTile> createState() => _FlSubmenuTileState();
}

class _FlSubmenuTileState extends State<FlSubmenuTile> {
  bool _isHovered = false;
  bool _isSubmenuHovered = false;
  OverlayEntry? _submenuOverlay;

  FlMenuStyle get _style => widget.submenuStyle;
  FlMenuItemStyle get _itemStyle => widget.parentStyle.itemStyle;

  void _showSubmenu(BuildContext context) {
    if (_submenuOverlay != null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _submenuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            left: position.dx + size.width - 5,
            top: position.dy,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isSubmenuHovered = true),
              onExit: (_) {
                setState(() => _isSubmenuHovered = false);
                _checkAndRemoveSubmenu();
              },
              child: FlMenuWidget(
                data: FlMenuDataModel(sections: [
                  FlMenuSectionDataModel(items: widget.data),
                ]),
                position: Offset(position.dx + size.width, position.dy),
                config: const FlMenuConfig(),
                style: _style,
                menuLevel: widget.menuLevel + 1,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_submenuOverlay!);
  }

  void _removeSubmenu() {
    _isSubmenuHovered = false;
    _submenuOverlay?.remove();
    _submenuOverlay = null;
  }

  @override
  void dispose() {
    _removeSubmenu();
    super.dispose();
  }

  void _checkAndRemoveSubmenu() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_isHovered && !_isSubmenuHovered && mounted) _removeSubmenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hoverColor = _itemStyle.hoverColor;
    final textStyle = _itemStyle.textStyle;
    final iconSize = _itemStyle.iconSize;
    final padding = _itemStyle.padding;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _showSubmenu(context);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
        _checkAndRemoveSubmenu();
      },
      child: InkWell(
        onTap: () => _showSubmenu(context),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.iconData != null) ...[
                Icon(
                  widget.iconData!,
                  size: iconSize,
                  color: textStyle.color?.withAlpha(185),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.label ?? widget.id,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              Icon(
                Icons.arrow_right,
                color: textStyle.color?.withAlpha(185),
                size: iconSize + 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
