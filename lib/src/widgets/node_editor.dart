import 'package:fl_nodes/src/core/models/overlay.dart';
import 'package:fl_nodes/src/widgets/debug_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/controller/core.dart';
import 'builders.dart';
import 'node_editor_data_layer.dart';

class FlNodeEditorWidget extends StatelessWidget {
  final FlNodeEditorController controller;
  final bool expandToParent;
  final Size? fixedSize;
  final List<FlOverlayData> Function() overlay;
  final NodeHeaderBuilder? headerBuilder;
  final NodeFieldBuilder? fieldBuilder;
  final NodePortBuilder? portBuilder;
  final NodeContextMenuBuilder? contextMenuBuilder;
  final NodeBuilder? nodeBuilder;

  const FlNodeEditorWidget({
    super.key,
    required this.controller,
    this.expandToParent = true,
    this.fixedSize,
    required this.overlay,
    this.headerBuilder,
    this.fieldBuilder,
    this.portBuilder,
    this.contextMenuBuilder,
    this.nodeBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final Widget editor = Container(
      decoration: controller.style.decoration,
      padding: controller.style.padding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            left: 0,
            child: NodeEditorDataLayer(
              controller: controller,
              expandToParent: expandToParent,
              fixedSize: fixedSize,
              overlay: overlay,
              headerBuilder: headerBuilder,
              fieldBuilder: fieldBuilder,
              portBuilder: portBuilder,
              contextMenuBuilder: contextMenuBuilder,
              nodeBuilder: nodeBuilder,
            ),
          ),
          ...overlay().map(
            (overlayData) => Positioned(
              top: overlayData.top,
              left: overlayData.left,
              bottom: overlayData.bottom,
              right: overlayData.right,
              child: RepaintBoundary(
                child: overlayData.child,
              ),
            ),
          ),
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
