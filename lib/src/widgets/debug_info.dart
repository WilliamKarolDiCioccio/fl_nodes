import 'package:flutter/material.dart';

class DebugInfoWidget extends StatelessWidget {
  final Offset offset;
  final double zoom;
  final int selectionCount;

  const DebugInfoWidget({
    super.key,
    required this.offset,
    required this.zoom,
    required this.selectionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'X: ${offset.dx.toStringAsFixed(2)}, Y: ${offset.dy.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          Text(
            'Zoom: ${zoom.toStringAsFixed(2)}',
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
