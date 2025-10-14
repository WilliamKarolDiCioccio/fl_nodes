import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../controller/core.dart';
import '../../localization/delegate.dart';
import '../../models/data.dart';
import '../rendering/renderbox.dart';

bool isContextMenuVisible = false;

class ContextMenuUtils {
  static void createAndShowContextMenu(
    BuildContext context, {
    required List<ContextMenuEntry> entries,
    required Offset position,
    Function(String? value)? onDismiss,
  }) async {
    if (isContextMenuVisible) return;

    isContextMenuVisible = true;

    final menu = ContextMenu(
      entries: entries,
      position: position,
      padding: const EdgeInsets.all(8),
    );

    final copiedValue = await showContextMenu(
      context,
      contextMenu: menu,
    ).then((value) {
      isContextMenuVisible = false;
      return value;
    });

    if (onDismiss != null) onDismiss(copiedValue);
  }

  static List<ContextMenuEntry> portContextMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodeEditorController controller,
    required PortLocator locator,
  }) {
    final strings = FlNodeEditorLocalizations.of(context);

    return [
      MenuHeader(text: strings.portMenuLabel),
      MenuItem(
        label: strings.cutLinksAction,
        icon: Icons.remove_circle,
        onSelected: () {
          controller.breakPortLinks(locator.nodeId, locator.portId);
        },
      ),
    ];
  }

  static List<ContextMenuEntry> nodeMenuEntries(
    BuildContext context,
    FlNodeEditorController controller,
    FlNodeDataModel node,
  ) {
    final strings = FlNodeEditorLocalizations.of(context);

    return [
      MenuHeader(text: strings.nodeMenuLabel),
      MenuItem(
        label: strings.seeNodeDescriptionAction,
        icon: Icons.info,
        onSelected: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(node.prototype.displayName(context)),
                content: Text(node.prototype.description(context)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.closeAction),
                  ),
                ],
              );
            },
          );
        },
      ),
      const MenuDivider(),
      MenuItem(
        label: node.state.isCollapsed
            ? strings.expandNodeAction
            : strings.collapseNodeAction,
        icon:
            node.state.isCollapsed ? Icons.arrow_drop_down : Icons.arrow_right,
        onSelected: () =>
            controller.toggleCollapseSelectedNodes(!node.state.isCollapsed),
      ),
      const MenuDivider(),
      MenuItem(
        label: strings.deleteNodeAction,
        icon: Icons.delete,
        onSelected: () {
          if (node.state.isSelected) {
            for (final nodeId in controller.selectedNodeIds) {
              controller.removeNodeById(nodeId);
            }
          } else {
            for (final nodeId in controller.selectedNodeIds) {
              controller.removeNodeById(nodeId);
            }
          }

          controller.clearSelection();
        },
      ),
      MenuItem(
        label: strings.cutSelectionAction,
        icon: Icons.content_cut,
        onSelected: () => controller.clipboard.cutSelection(context: context),
      ),
      MenuItem(
        label: strings.copySelectionAction,
        icon: Icons.copy,
        onSelected: () => controller.clipboard.copySelection(context: context),
      ),
    ];
  }

  static List<ContextMenuEntry> nodeCreationMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodeEditorController controller,
    required PortLocator? locator,
  }) {
    final List<MapEntry<String, FlNodePrototype>> compatiblePrototypes = [];

    if (locator != null) {
      final startPort =
          controller.getNodeById(locator.nodeId)!.ports[locator.portId]!;

      controller.nodePrototypes.forEach((key, value) {
        if (value.portPrototypes.any(
          startPort.prototype.compatibleWith,
        )) {
          compatiblePrototypes.add(MapEntry(key, value));
        }
      });
    } else {
      controller.nodePrototypes.forEach(
        (key, value) => compatiblePrototypes.add(MapEntry(key, value)),
      );
    }

    final worldPosition = RenderBoxUtils.screenToWorld(
      controller.editorKey,
      position,
      controller.viewportOffset,
      controller.viewportZoom,
    );

    return compatiblePrototypes.map((entry) {
      return MenuItem(
        label: entry.value.displayName(context),
        icon: Icons.widgets,
        onSelected: () {
          final addedNode = controller.addNode(
            entry.key,
            offset: worldPosition ?? Offset.zero,
          );

          if (locator != null) {
            final startPort =
                controller.nodes[locator!.nodeId]!.ports[locator!.portId]!;

            controller.addLink(
              locator!.nodeId,
              locator!.portId,
              addedNode.id,
              addedNode.ports.values
                  .map((port) => port.prototype)
                  .firstWhere(
                    startPort.prototype.compatibleWith,
                  )
                  .idName,
            );

            locator = null;
          }
        },
      );
    }).toList();
  }

  static List<ContextMenuEntry> canvasMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodeEditorController controller,
    required PortLocator? locator,
  }) {
    final worldPosition = RenderBoxUtils.screenToWorld(
      controller.editorKey,
      position,
      controller.viewportOffset,
      controller.viewportZoom,
    )!;
    final strings = FlNodeEditorLocalizations.of(context);

    return [
      MenuHeader(text: strings.editorMenuLabel),
      MenuItem(
        label: strings.centerViewAction,
        icon: Icons.center_focus_strong,
        onSelected: () => controller.setViewportOffset(
          Offset.zero,
          absolute: true,
        ),
      ),
      MenuItem(
        label: strings.resetZoomAction,
        icon: Icons.zoom_in,
        onSelected: () => controller.setViewportZoom(1.0, absolute: true),
      ),
      const MenuDivider(),
      MenuItem.submenu(
        label: strings.createNodeAction,
        icon: Icons.add,
        items: ContextMenuUtils.nodeCreationMenuEntries(
          position,
          context: context,
          controller: controller,
          locator: locator,
        ),
      ),
      MenuItem(
        label: strings.pasteSelectionAction,
        icon: Icons.paste,
        onSelected: () =>
            controller.clipboard.pasteSelection(position: worldPosition),
      ),
      const MenuDivider(),
      MenuItem.submenu(
        label: strings.projectLabel,
        icon: Icons.folder,
        items: [
          MenuItem(
            label: strings.undoAction,
            icon: Icons.undo,
            onSelected: () => controller.history.undo(),
          ),
          MenuItem(
            label: strings.redoAction,
            icon: Icons.redo,
            onSelected: () => controller.history.redo(),
          ),
          MenuItem(
            label: strings.saveProjectAction,
            icon: Icons.save,
            onSelected: () => controller.project.save(context: context),
          ),
          MenuItem(
            label: strings.openProjectAction,
            icon: Icons.folder_open,
            onSelected: () => controller.project.load(context: context),
          ),
          MenuItem(
            label: strings.newProjectAction,
            icon: Icons.new_label,
            onSelected: () => controller.project.create(context: context),
          ),
        ],
      ),
    ];
  }

  static List<ContextMenuEntry> linkContextMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodeEditorController controller,
    required String linkId,
  }) {
    final strings = FlNodeEditorLocalizations.of(context);

    return [
      MenuHeader(text: strings.linkMenuLabel),
      MenuItem(
        label: strings.navigateToSourceAction,
        icon: Icons.launch,
        onSelected: () {
          final link = controller.links[linkId];
          if (link != null) {
            controller.focusNodesById({link.ports.from.nodeId});
          }
        },
      ),
      MenuItem(
        label: strings.navigateToDestinationAction,
        icon: Icons.call_received,
        onSelected: () {
          final link = controller.links[linkId];
          if (link != null) {
            controller.focusNodesById({link.ports.to.nodeId});
          }
        },
      ),
      const MenuDivider(),
      MenuItem(
        label: strings.deleteLinkAction,
        icon: Icons.delete,
        onSelected: () {
          controller.removeLinkById(linkId);
        },
      ),
    ];
  }
}
