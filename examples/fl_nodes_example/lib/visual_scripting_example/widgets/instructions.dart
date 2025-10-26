import 'package:fl_nodes_example/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InstructionsPanel extends StatelessWidget {
  const InstructionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final comboKey = defaultTargetPlatform == TargetPlatform.macOS
        ? "Meta"
        : "Ctrl";

    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Header ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.instructionsPanelTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // --- Content ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: isMobile
                ? _buildTouchInstructions(context)
                : _buildDesktopInstructions(context, comboKey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTouchInstructions(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, strings.touchCommandsTitle),
        const SizedBox(height: 12),
        _buildBullet(strings.touchTap),
        _buildBullet(strings.touchDoubleTap),
        _buildBullet(strings.touchLongPress),
        _buildBullet(strings.touchDrag),
        _buildBullet(strings.touchPinch),
        const SizedBox(height: 16),
        _buildSectionTitle(context, strings.touchAdditionalGestures),
        const SizedBox(height: 12),
        _buildBullet(strings.touchTwoFingerDrag),
      ],
    );
  }

  Widget _buildDesktopInstructions(BuildContext context, String comboKey) {
    final strings = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, strings.mouseCommandsTitle),
        const SizedBox(height: 12),
        _buildBullet(strings.mouseLeftClick),
        _buildBullet(strings.mouseRightClick),
        _buildBullet(strings.mouseScroll),
        _buildBullet(strings.mouseMiddleClick),
        const SizedBox(height: 16),
        _buildSectionTitle(context, strings.keyboardCommandsTitle),
        const SizedBox(height: 12),
        _buildBullet(strings.keyboardSave(comboKey)),
        _buildBullet(strings.keyboardOpen(comboKey)),
        _buildBullet(strings.keyboardNew(comboKey)),
        _buildBullet(strings.keyboardCopy(comboKey)),
        _buildBullet(strings.keyboardPaste(comboKey)),
        _buildBullet(strings.keyboardCut(comboKey)),
        _buildBullet(strings.keyboardDelete),
        _buildBullet(strings.keyboardUndo(comboKey)),
        _buildBullet(strings.keyboardRedo(comboKey)),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
