import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:example/l10n/app_localizations.dart';

class InstructionsWidget extends StatelessWidget {
  const InstructionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final comboKey =
        defaultTargetPlatform == TargetPlatform.macOS ? "Meta" : "Ctrl";

    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.touchCommandsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.touchTap,
                  ),
                  Text(
                    AppLocalizations.of(context)!.touchDoubleTap,
                  ),
                  Text(
                    AppLocalizations.of(context)!.touchLongPress,
                  ),
                  Text(
                    AppLocalizations.of(context)!.touchDrag,
                  ),
                  Text(
                    AppLocalizations.of(context)!.touchPinch,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.touchAdditionalGestures,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.touchTwoFingerDrag,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.mouseCommandsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.mouseLeftClick,
                  ),
                  Text(
                    AppLocalizations.of(context)!.mouseLeftClick,
                  ),
                  Text(
                    AppLocalizations.of(context)!.mouseRightClick,
                  ),
                  Text(
                    AppLocalizations.of(context)!.mouseScroll,
                  ),
                  Text(
                    AppLocalizations.of(context)!.mouseMiddleClick,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.keyboardCommandsTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardSave(comboKey),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardOpen(comboKey),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardNew(comboKey),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardCopy(comboKey),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardPaste(comboKey),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardCut(comboKey),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardDelete,
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardUndo(comboKey),
                  ),
                  Text(
                    AppLocalizations.of(context)!.keyboardRedo(comboKey),
                  ),
                ],
              ),
      ),
    );
  }
}
