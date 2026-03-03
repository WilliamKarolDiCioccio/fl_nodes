import 'package:fl_nodes_core/fl_nodes_core.dart';
import 'package:fl_nodes_core/src/widgets/debug_info.dart';
import 'package:fl_nodes_core/src/widgets/node_editor_data_layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FlNodesWidget extends StatelessWidget {
  final FlNodesController controller;
  final bool expandToParent;
  final Size? fixedSize;
  final NodeBuilder nodeBuilder;

  final void Function(
    BuildContext context,
    Offset position,
    FlNodesController controller,
    PortLocator locator,
  ) showPortContextMenu;

  final void Function(
    BuildContext context,
    Offset position,
    FlNodesController controller,
    PortLocator? locator,
  ) showCanvasContextMenu;

  final void Function(
    BuildContext context,
    Offset lastFocalPoint,
    FlNodesController controller,
    PortLocator? locator,
    void Function() onTmpLinkCancel,
  ) showNodeCreationMenu;

  final void Function(
    BuildContext context,
    String linkId,
    Offset position,
    FlNodesController controller,
  ) showLinkContextMenu;

  const FlNodesWidget({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.showPortContextMenu,
    required this.showCanvasContextMenu,
    required this.showNodeCreationMenu,
    required this.showLinkContextMenu,
    this.expandToParent = true,
    this.fixedSize,
  });

  @override
  Widget build(BuildContext context) {
    final Widget editor = Container(
      decoration: controller.style.decoration,
      padding: controller.style.padding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          NodeEditorDataLayer(
            controller: controller,
            expandToParent: expandToParent,
            fixedSize: fixedSize,
            nodeBuilder: nodeBuilder,
            showPortContextMenu: showPortContextMenu,
            showCanvasContextMenu: showCanvasContextMenu,
            showNodeCreationMenu: showNodeCreationMenu,
            showLinkContextMenu: showLinkContextMenu,
          ),
          _OverlayLayer(controller: controller),
          if (kDebugMode) DebugInfoWidget(controller: controller),
        ],
      ),
    );

    if (expandToParent) {
      return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: editor,
        ),
      );
    } else {
      return SizedBox(
        width: fixedSize?.width ?? 100,
        height: fixedSize?.height ?? 100,
        child: editor,
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<FlNodesController>('controller', controller))
      ..add(DiagnosticsProperty<bool>('expandToParent', expandToParent))
      ..add(DiagnosticsProperty<Size?>('fixedSize', fixedSize))
      ..add(ObjectFlagProperty<NodeBuilder>.has('nodeBuilder', nodeBuilder))
      ..add(
        ObjectFlagProperty<
            void Function(
              BuildContext context,
              Offset position,
              FlNodesController controller,
              PortLocator locator,
            )>.has(
          'showPortContextMenu',
          showPortContextMenu,
        ),
      )
      ..add(
        ObjectFlagProperty<
            void Function(
              BuildContext context,
              Offset position,
              FlNodesController controller,
              PortLocator? locator,
            )>.has(
          'showCanvasContextMenu',
          showCanvasContextMenu,
        ),
      )
      ..add(
        ObjectFlagProperty<
            void Function(
              BuildContext context,
              Offset lastFocalPoint,
              FlNodesController controller,
              PortLocator? locator,
              void Function() onTmpLinkCancel,
            )>.has(
          'showNodeCreationMenu',
          showNodeCreationMenu,
        ),
      )
      ..add(
        ObjectFlagProperty<
            void Function(
              BuildContext context,
              String linkId,
              Offset position,
              FlNodesController controller,
            )>.has(
          'showLinkContextMenu',
          showLinkContextMenu,
        ),
      );
  }
}

class _OverlayLayer extends StatefulWidget {
  final FlNodesController controller;

  const _OverlayLayer({required this.controller});

  @override
  State<_OverlayLayer> createState() => _OverlayLayerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FlNodesController>('controller', controller));
  }
}

class _OverlayLayerState extends State<_OverlayLayer> {
  @override
  void initState() {
    super.initState();

    widget.controller.eventBus.events.listen(_handleControllerEvents);
  }

  void _handleControllerEvents(NodeEditorEvent event) {
    if (!mounted || event.isHandled) return;

    if (event is FlOverlayChangedEvent) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ...widget.controller.overlay.data.values.map(
            (data) => Positioned(
              top: data.top,
              left: data.left,
              bottom: data.bottom,
              right: data.right,
              child: RepaintBoundary(
                child: data.isVisible
                    ? Opacity(
                        opacity: data.opacity,
                        child: Builder(
                          builder: (context) => data.builder(context, data),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      );
}
