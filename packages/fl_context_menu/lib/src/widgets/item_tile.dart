import 'package:fl_context_menu/fl_context_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FlMenuItemTile extends StatefulWidget {
  final String id;
  final String? label;
  final IconData? iconData;
  final VoidCallback? onTap;
  final void Function(String)? onPressed;
  final bool closeOnTap;
  final FlMenuItemStyle style;
  final bool isEnabled;

  const FlMenuItemTile({
    super.key,
    required this.id,
    required this.style,
    this.isEnabled = true,
    this.label,
    this.iconData,
    this.onPressed,
    this.onTap,
    this.closeOnTap = true,
  });

  @override
  State<FlMenuItemTile> createState() => _FlMenuItemTileState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<IconData?>('iconData', iconData))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap))
      ..add(ObjectFlagProperty<void Function(String)?>.has('onPressed', onPressed))
      ..add(DiagnosticsProperty<bool>('closeOnTap', closeOnTap))
      ..add(DiagnosticsProperty<FlMenuItemStyle>('style', style))
      ..add(DiagnosticsProperty<bool>('isEnabled', isEnabled));
  }
}

class _FlMenuItemTileState extends State<FlMenuItemTile> {
  bool _isHovered = false;

  void _handleTap(BuildContext context) {
    widget.onPressed?.call(widget.id);
    widget.onTap?.call();

    if (widget.closeOnTap) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHovered = _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: isHovered ? Colors.white.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.iconData != null) ...[
                Icon(
                  widget.iconData,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.label ?? widget.id,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
