import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes_example/mind_map_example/nodes/data/types.dart';
import 'package:flutter/material.dart';

class MindMapNodeWidget extends FlBaseNodeWidget {
  const MindMapNodeWidget({
    super.key,
    required super.controller,
    required super.node,
  });

  @override
  State<MindMapNodeWidget> createState() => _MindMapNodeWidgetState();
}

class _MindMapNodeWidgetState extends FlBaseNodeWidgetState<MindMapNodeWidget> {
  @override
  Widget build(BuildContext context) {
    final shapeType =
        widget.node.customData['shape'] as ShapeType? ??
        ShapeType.roundedRectangle;
    final text = widget.node.customData['text'] as String? ?? 'Node';

    return wrapWithControls(
      SizedBox(
        width: 160,
        height: 100,
        child: SizedBox(
          width: 160,
          height: 100,
          child: Stack(
            key: widget.node.key,
            clipBehavior: Clip.none,
            children: [
              _ShapePainterWidget(
                shapeType: shapeType,
                isSelected: widget.node.state.isSelected,
                text: text,
              ),
              Positioned.fill(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 0,
                        height: 0,
                        key: widget.node.ports['top']!.key,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: 0,
                        height: 0,
                        key: widget.node.ports['bottom']!.key,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 0,
                        height: 0,
                        key: widget.node.ports['left']!.key,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 0,
                        height: 0,
                        key: widget.node.ports['right']!.key,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void updatePortsPosition() {
    // Early return with combined null checks
    final renderBox = context.findRenderObject() as RenderBox?;
    final nodeBox =
        widget.node.key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null || nodeBox == null) return;

    // Cache frequently used values
    final nodeOffset = nodeBox.localToGlobal(Offset.zero);
    final isCollapsed = widget.node.state.isCollapsed;
    final collapsedYAdjustment = isCollapsed ? -renderBox.size.height + 8 : 0;

    // Process ports
    for (final port in widget.node.ports.values) {
      final portBox = port.key.currentContext?.findRenderObject() as RenderBox?;
      if (portBox == null) continue;

      final portOffset = portBox.localToGlobal(Offset.zero);
      final localOffset = portOffset - nodeOffset;

      port.offset = Offset(
        localOffset.dx + portBox.size.width / 2,
        localOffset.dy + portBox.size.height / 2 + collapsedYAdjustment,
      );
    }
  }
}

class _ShapePainterWidget extends StatelessWidget {
  final ShapeType shapeType;
  final bool isSelected;
  final String text;

  const _ShapePainterWidget({
    required this.shapeType,
    required this.isSelected,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapePainter(shapeType, isSelected),
      child: Container(
        width: 160,
        height: 100,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final ShapeType shapeType;
  final bool isSelected;

  _ShapePainter(this.shapeType, this.isSelected);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected ? Colors.blue.shade600 : Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue.shade700 : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Offset.zero & size;

    switch (shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
        break;
      case ShapeType.roundedRectangle:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(rrect, borderPaint);
        break;
      case ShapeType.circle:
        final radius = size.shortestSide / 2;
        canvas.drawCircle(size.center(Offset.zero), radius, paint);
        canvas.drawCircle(size.center(Offset.zero), radius, borderPaint);
        break;
      case ShapeType.ellipse:
        final ellipseRect = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width,
          height: size.height * 0.75,
        );
        canvas.drawOval(ellipseRect, paint);
        canvas.drawOval(ellipseRect, borderPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      oldDelegate.shapeType != shapeType ||
      oldDelegate.isSelected != isSelected;
}
