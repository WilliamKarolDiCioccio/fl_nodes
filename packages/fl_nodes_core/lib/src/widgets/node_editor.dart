import 'package:fl_nodes_core/src/core/events/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/controller/core.dart';
import 'builders.dart';
import 'debug_info.dart';
import 'node_editor_data_layer.dart';

class FlNodeEditorWidget extends StatelessWidget {
  final FlNodeEditorController controller;
  final bool expandToParent;
  final Size? fixedSize;
  final NodeBuilder nodeBuilder;

  const FlNodeEditorWidget({
    super.key,
    required this.controller,
    required this.nodeBuilder,
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
          ),
          _OverlayLayer(controller: controller),
          if (kDebugMode) DebugInfoWidget(controller: controller),
        ],
      ),
    );

    if (expandToParent) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: editor,
          );
        },
      );
    } else {
      return SizedBox(
        width: fixedSize?.width ?? 100,
        height: fixedSize?.height ?? 100,
        child: editor,
      );
    }
  }
}

class _OverlayLayer extends StatefulWidget {
  final FlNodeEditorController controller;

  const _OverlayLayer({required this.controller});

  @override
  State<_OverlayLayer> createState() => _OverlayLayerState();
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
  Widget build(BuildContext context) {
    return Stack(
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
}
