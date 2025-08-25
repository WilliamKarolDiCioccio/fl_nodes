import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/controller/core.dart';
import 'package:fl_nodes/src/core/models/events.dart';

class DebugInfoWidget extends StatelessWidget {
  final FlNodeEditorController controller;

  const DebugInfoWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ValueListenableBuilder<Offset>(
            valueListenable: controller.viewportOffsetNotifier,
            builder: (context, viewportOffset, child) {
              return Text(
                'Offset: x.${viewportOffset.dx.toStringAsFixed(2)}, y.${viewportOffset.dy.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              );
            },
          ),
          ValueListenableBuilder<double>(
            valueListenable: controller.viewportZoomNotifier,
            builder: (context, viewportZoom, child) {
              return Text(
                'Zoom: ${viewportZoom.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green, fontSize: 16),
              );
            },
          ),
          StreamBuilder(
            stream: controller.eventBus.events.where(
              (event) =>
                  event is FlAddNodeEvent ||
                  event is FlRemoveNodeEvent ||
                  event is FlAddLinkEvent ||
                  event is FlRemoveLinkEvent ||
                  event is FlNodeSelectionEvent ||
                  event is FlNodeDeselectionEvent,
            ),
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Node count: ${controller.nodes.length}',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Links count: ${controller.linksById.length}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Selection count: ${controller.selectedNodeIds.length}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: controller.lodLevelNotifier,
            builder: (context, lodLevel, child) {
              return Text(
                'LOD level: $lodLevel',
                style: const TextStyle(color: Colors.purple, fontSize: 16),
              );
            },
          ),
        ],
      ),
    );
  }
}
