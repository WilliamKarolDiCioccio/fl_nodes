import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller/core.dart';

class FlNodesShortcutsWidget extends StatelessWidget {
  final FlNodesController controller;
  final Widget child;

  const FlNodesShortcutsWidget({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.delete): () {
          for (final nodeId in controller.selectedNodeIds) {
            controller.removeNodeById(
              nodeId,
              isHandled: nodeId != controller.selectedNodeIds.last,
            );
          }
          for (final link in controller.selectedLinkIds) {
            controller.removeLinkById(link);
          }
          controller.clearSelection();
        },
        const SingleActivator(LogicalKeyboardKey.backspace): () {
          for (final nodeId in controller.selectedNodeIds) {
            controller.removeNodeById(
              nodeId,
              isHandled: nodeId != controller.selectedNodeIds.last,
            );
          }
          for (final link in controller.selectedLinkIds) {
            controller.removeLinkById(link);
          }
          controller.clearSelection();
        },
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () =>
            controller.clipboard.copySelection(context: context),
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
            controller.clipboard.pasteSelection(context: context),
        const SingleActivator(LogicalKeyboardKey.keyX, control: true): () =>
            controller.clipboard.cutSelection(context: context),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            controller.project.save(context: context),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            controller.project.load(context: context),
        SingleActivator(
          LogicalKeyboardKey.keyN,
          control: defaultTargetPlatform != TargetPlatform.macOS,
          meta: defaultTargetPlatform == TargetPlatform.macOS,
          shift: true,
        ): () => controller.project.create(context: context),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            controller.history.undo(),
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
            controller.history.redo(),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
