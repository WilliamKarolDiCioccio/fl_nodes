import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fl_nodes/fl_nodes_ext.dart';

class HierarchyWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final bool isCollapsed;

  const HierarchyWidget({
    required this.controller,
    required this.isCollapsed,
    super.key,
  });

  @override
  State<HierarchyWidget> createState() => _HierarchyWidgetState();
}

class _HierarchyWidgetState extends State<HierarchyWidget> {
  @override
  void initState() {
    super.initState();
    _subscribeToControllerEvents();
  }

  void _subscribeToControllerEvents() {
    widget.controller.eventBus.events.listen((event) {
      if (event is SelectionEvent ||
          event is DragSelectionEvent ||
          event is NodeRenderModeEvent ||
          event is AddNodeEvent ||
          event is RemoveNodeEvent) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _onNodeTap(NodeInstance node) {
    widget.controller.selectNodesById(
      {node.id},
      holdSelection: HardwareKeyboard.instance.isControlPressed,
    );
    widget.controller.focusNodesById(
      widget.controller.selectedNodeIds.toSet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 0 : 300,
      color: const Color(0xFF212121),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isCollapsed)
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.controller.nodesAsList.length,
                itemBuilder: (context, index) {
                  final reversedIdx =
                      widget.controller.nodesAsList.length - index - 1;
                  final node = widget.controller.nodesAsList[reversedIdx];

                  // Custom selection style
                  final isSelected = node.state.isSelected;
                  final backgroundColor = isSelected
                      ? Colors.blue.withAlpha(156)
                      : Colors.transparent;

                  return Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        '${node.offset} - ${node.prototype.displayName}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => _onNodeTap(node),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
