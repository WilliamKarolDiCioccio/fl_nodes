import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

bool isContextMenuVisible = false;

// `abstract final class` is basically a namespace for static methods, and cannot be instantiated or extended.
// ignore: avoid_classes_with_only_static_members
abstract final class ContextMenuUtils {
  static Future<void> createAndShowContextMenu(
    BuildContext context, {
    required List<ContextMenuEntry<String?>> entries,
    required Offset position,
    void Function(String? value)? onDismiss,
  }) async {
    if (isContextMenuVisible) return;

    isContextMenuVisible = true;

    final ContextMenu<String?> menu = ContextMenu(
      entries: entries,
      position: position,
      padding: const EdgeInsets.all(8),
    );

    final String? copiedValue = await showContextMenu<String?>(context, contextMenu: menu).then((
      value,
    ) {
      isContextMenuVisible = false;
      return value;
    });

    if (onDismiss != null) onDismiss(copiedValue);
  }

  static List<ContextMenuEntry<String?>> portContextMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodesController controller,
    required PortLocator locator,
  }) {
    final FlNodesLocalizations strings = FlNodesLocalizations.of(context);

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

  static List<ContextMenuEntry<String?>> nodeMenuEntries(
    BuildContext context,
    FlNodesController controller,
    FlNodeDataModel node,
  ) {
    final FlNodesLocalizations strings = FlNodesLocalizations.of(context);

    return [
      MenuHeader(text: strings.nodeMenuLabel),
      MenuItem(
        label: strings.seeNodeDescriptionAction,
        icon: Icons.info,
        onSelected: () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(node.prototype.displayName(context)),
              content: Text(node.prototype.description(context)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.closeAction),
                ),
              ],
            ),
          );
        },
      ),
      const MenuDivider(),
      MenuItem(
        label: node.state.isCollapsed ? strings.expandNodeAction : strings.collapseNodeAction,
        icon: node.state.isCollapsed ? Icons.arrow_drop_down : Icons.arrow_right,
        onSelected: () => controller.toggleCollapseSelectedNodes(!node.state.isCollapsed),
      ),
      const MenuDivider(),
      MenuItem(
        label: strings.deleteNodeAction,
        icon: Icons.delete,
        onSelected: () {
          if (node.state.isSelected) {
            controller.selectedNodeIds.forEach(controller.removeNodeById);
          } else {
            controller.selectedNodeIds.forEach(controller.removeNodeById);
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

  static List<ContextMenuEntry<String?>> nodeCreationMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodesController controller,
    required PortLocator? locator,
  }) {
    final List<MapEntry<String, FlNodePrototype>> compatiblePrototypes = [];

    if (locator != null) {
      final FlPortDataModel startPort = controller
          .getNodeById(locator.nodeId)!
          .ports[locator.portId]!;

      controller.nodePrototypes.forEach((key, value) {
        if (value.portPrototypes.any(
          (prototype) => startPort.prototype.compatibleWith(prototype) == null,
        )) {
          compatiblePrototypes.add(MapEntry(key, value));
        }
      });
    } else {
      controller.nodePrototypes.forEach(
        (key, value) => compatiblePrototypes.add(MapEntry(key, value)),
      );
    }

    final Offset? worldPosition = RenderBoxUtils.screenToWorld(
      controller.editorKey,
      position,
      controller.viewportOffset,
      controller.viewportZoom,
    );

    return compatiblePrototypes
        .map(
          (entry) => MenuItem<String?>(
            label: entry.value.displayName(context),
            icon: Icons.widgets,
            onSelected: () {
              final FlNodeDataModel addedNode = controller.addNode(
                entry.key,
                offset: worldPosition ?? Offset.zero,
              );

              if (locator != null) {
                final FlPortDataModel startPort =
                    controller.nodes[locator!.nodeId]!.ports[locator!.portId]!;

                controller.addLink(
                  locator!.nodeId,
                  locator!.portId,
                  addedNode.id,
                  addedNode.ports.values
                      .firstWhere((port) => startPort.canLinkTo(port) == null)
                      .prototype
                      .idName,
                );

                locator = null;
              }
            },
          ),
        )
        .toList();
  }

  static List<ContextMenuEntry<String?>> canvasMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodesController controller,
    required PortLocator? locator,
  }) {
    final Offset worldPosition = RenderBoxUtils.screenToWorld(
      controller.editorKey,
      position,
      controller.viewportOffset,
      controller.viewportZoom,
    )!;
    final FlNodesLocalizations strings = FlNodesLocalizations.of(context);

    return [
      MenuHeader(text: strings.editorMenuLabel),
      MenuItem(
        label: strings.centerViewAction,
        icon: Icons.center_focus_strong,
        onSelected: () => controller.setViewportOffset(Offset.zero, absolute: true),
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
        onSelected: () => controller.clipboard.pasteSelection(position: worldPosition),
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

  static List<ContextMenuEntry<String?>> linkContextMenuEntries(
    Offset position, {
    required BuildContext context,
    required FlNodesController controller,
    required String linkId,
  }) {
    final FlNodesLocalizations strings = FlNodesLocalizations.of(context);

    return [
      MenuHeader(text: strings.linkMenuLabel),
      MenuItem(
        label: strings.navigateToSourceAction,
        icon: Icons.launch,
        onSelected: () {
          final FlLinkDataModel? link = controller.links[linkId];
          if (link == null) return;
          controller.focusNodesById({
            FlNodesUtils.getSource(controller, link).nodeId,
          });
        },
      ),
      MenuItem(
        label: strings.navigateToDestinationAction,
        icon: Icons.call_received,
        onSelected: () {
          final FlLinkDataModel? link = controller.links[linkId];
          if (link == null) return;
          controller.focusNodesById({
            FlNodesUtils.getDestination(controller, link).nodeId,
          });
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

// `abstract final class` is basically a namespace for static methods, and cannot be instantiated or extended.
// ignore: avoid_classes_with_only_static_members
abstract final class ShowContextMenuUtils {
  static void showPortContextMenu(
    BuildContext context,
    Offset position,
    FlNodesController controller,
    PortLocator locator,
  ) => ContextMenuUtils.createAndShowContextMenu(
    context,
    entries: ContextMenuUtils.portContextMenuEntries(
      position,
      context: context,
      controller: controller,
      locator: locator,
    ),
    position: position,
  );

  static void showNodeCreationMenu(
    BuildContext context,
    Offset lastFocalPoint,
    FlNodesController controller,
    PortLocator? locator,
    void Function() onTmpLinkCancel,
  ) => ContextMenuUtils.createAndShowContextMenu(
    context,
    entries: ContextMenuUtils.nodeCreationMenuEntries(
      lastFocalPoint,
      context: context,
      controller: controller,
      locator: locator,
    ),
    position: lastFocalPoint,
    onDismiss: (value) => onTmpLinkCancel(),
  );

  static void showNodeContextMenu(
    BuildContext context,
    Offset position,
    FlNodesController controller,
    FlNodeDataModel node,
  ) => ContextMenuUtils.createAndShowContextMenu(
    context,
    entries: ContextMenuUtils.nodeMenuEntries(context, controller, node),
    position: position,
  );

  static void showCanvasContextMenu(
    BuildContext context,
    Offset position,
    FlNodesController controller,
    PortLocator? locator,
  ) => ContextMenuUtils.createAndShowContextMenu(
    context,
    entries: ContextMenuUtils.canvasMenuEntries(
      position,
      context: context,
      controller: controller,
      locator: locator,
    ),
    position: position,
  );

  static void showLinkContextMenu(
    BuildContext context,
    String linkId,
    Offset position,
    FlNodesController controller,
  ) => ContextMenuUtils.createAndShowContextMenu(
    context,
    entries: ContextMenuUtils.linkContextMenuEntries(
      position,
      context: context,
      controller: controller,
      linkId: linkId,
    ),
    position: position,
  );
}
