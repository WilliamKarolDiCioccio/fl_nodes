import 'package:fl_nodes/src/core/models/events.dart';
import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/controller/core.dart';

class DebugInfoWidget extends StatefulWidget {
  final FlNodeEditorController controller;

  const DebugInfoWidget({
    super.key,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() => _DebugInfoWidgetState();
}

class _DebugInfoWidgetState extends State<DebugInfoWidget> {
  double get viewportZoom => widget.controller.viewportZoom;
  Offset get viewportOffset => widget.controller.viewportOffset;
  int get selectionCount => widget.controller.selectedNodeIds.length;

  @override
  void initState() {
    super.initState();

    widget.controller.eventBus.events.listen((event) {
      if (event is ViewportOffsetEvent ||
          event is ViewportZoomEvent ||
          event is NodeSelectionEvent) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'X: ${viewportOffset.dx.toStringAsFixed(2)}, Y: ${viewportOffset.dy.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          Text(
            'Zoom: ${viewportZoom.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green, fontSize: 16),
          ),
          Text(
            'Selection count: $selectionCount',
            style: const TextStyle(color: Colors.blue, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
