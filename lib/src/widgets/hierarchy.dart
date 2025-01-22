import 'package:fl_nodes/src/core/models/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fl_nodes/src/core/controllers/node_editor_events.dart';

import '../core/controllers/node_editor.dart';

class FlHierarchyWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final FlHierarchyStyle style;

  const FlHierarchyWidget({
    required this.controller,
    required this.style,
    super.key,
  });

  @override
  State<FlHierarchyWidget> createState() => _FlHierarchyWidgetState();
}

class _FlHierarchyWidgetState extends State<FlHierarchyWidget> {
  @override
  void initState() {
    super.initState();

    _handleControllerEvents();
  }

  void _handleControllerEvents() {
    widget.controller.eventBus.events.listen(
      (event) {
        if (event is SelectionEvent ||
            event is DragSelectionEvent ||
            event is CollapseNodeEvent ||
            event is AddNodeEvent ||
            event is RemoveNodeEvent) {
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: widget.style.decoration,
      padding: widget.style.padding,
      child: Column(
        spacing: 8,
        children: [
          const Text(
            'Hierarchy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.controller.nodesAsList.length,
              itemBuilder: (context, index) {
                final node = widget.controller.nodesAsList[index];
                return Container(
                  decoration: node.state.isSelected
                      ? widget.style.selectedNodeDecoration
                      : widget.style.nodeDecoration,
                  child: ListTile(
                    title: Text(
                      '${node.offset} - ${node.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.controller.selectNodesById(
                        {node.id},
                        holdSelection:
                            HardwareKeyboard.instance.isControlPressed,
                      );

                      widget.controller.focusNodesById(
                        widget.controller.selectedNodeIds.toSet(),
                      );
                    },
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
