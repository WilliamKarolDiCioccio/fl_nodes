import 'package:flutter/material.dart';

import '../core/controller/core.dart';
import '../core/events/events.dart';
import '../core/models/data.dart';

import 'base_node.dart';

/// The main NodeWidget which represents a node in the editor.
/// It now ensures that fields (regardless of whether a custom fieldBuilder is used)
/// still respond to tap events in the same way as before.
class FlDefaultNodeWidget extends FlBaseNodeWidget {
  const FlDefaultNodeWidget({
    super.key,
    required super.controller,
    required super.node,
    super.contextMenuBuilder,
  });

  @override
  State<FlDefaultNodeWidget> createState() => _FlDefaultNodeWidgetState();
}

class _FlDefaultNodeWidgetState
    extends FlBaseNodeWidgetState<FlDefaultNodeWidget> {
  @override
  Widget build(BuildContext context) {
    return wrapWithControls(
      IntrinsicHeight(
        child: IntrinsicWidth(
          child: Stack(
            key: widget.node.key,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: widget.node.builtStyle.decoration,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NodeHeaderWidget(
                    controller: widget.controller,
                    node: widget.node,
                  ),
                  Offstage(
                    offstage: widget.node.state.isCollapsed,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: inPorts
                                      .map(
                                        (port) => _PortWidget(
                                          node: widget.node,
                                          port: port,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: outPorts
                                      .map(
                                        (port) => _PortWidget(
                                          node: widget.node,
                                          port: port,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                          if (fields.isNotEmpty) const SizedBox(height: 16),
                          ...fields.map(
                            (field) => _FieldWidget(
                              controller: widget.controller,
                              node: widget.node,
                              field: field,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
    final renderBoxSize = renderBox.size;
    final nodeOffset = nodeBox.localToGlobal(Offset.zero);
    final isCollapsed = widget.node.state.isCollapsed;
    final collapsedYAdjustment = isCollapsed ? -renderBoxSize.height + 8 : 0;

    // Process ports
    for (final port in widget.node.ports.values) {
      final portBox = port.key.currentContext?.findRenderObject() as RenderBox?;
      if (portBox == null) continue;

      // Calculate relative offset with collapsed adjustment
      final portOffset = portBox.localToGlobal(Offset.zero);
      final relativeY = portOffset.dy - nodeOffset.dy + collapsedYAdjustment;

      // Set port offset based on direction
      port.offset = Offset(
        port.prototype.logicalOrientation == FlPortLogicalOrientation.input
            ? 0
            : renderBoxSize.width,
        relativeY + portBox.size.height / 2,
      );
    }
  }
}

class _NodeHeaderWidget extends StatelessWidget {
  final FlNodeEditorController controller;
  final FlNodeDataModel node;

  const _NodeHeaderWidget({
    required this.controller,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: node.builtHeaderStyle.padding,
      decoration: node.builtHeaderStyle.decoration,
      child: Row(
        children: [
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            onTap: () => controller.toggleCollapseSelectedNodes(
              !node.state.isCollapsed,
            ),
            child: Icon(
              node.builtHeaderStyle.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              node.prototype.displayName(context),
              style: node.builtHeaderStyle.textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortWidget extends StatelessWidget {
  final FlNodeDataModel node;
  final FlPortDataModel port;

  const _PortWidget({
    required this.node,
    required this.port,
  });

  @override
  Widget build(BuildContext context) {
    if (node.state.isCollapsed) {
      return SizedBox(key: port.key, height: 0, width: 0);
    }

    final isInput =
        port.prototype.logicalOrientation == FlPortLogicalOrientation.input;

    return Row(
      mainAxisAlignment:
          isInput ? MainAxisAlignment.start : MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      key: port.key,
      children: [
        Flexible(
          child: Text(
            port.prototype.displayName(context),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            textAlign: isInput ? TextAlign.left : TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _FieldWidget extends StatelessWidget {
  final FlNodeEditorController controller;
  final FlNodeDataModel node;
  final FlFieldDataModel field;

  const _FieldWidget({
    required this.controller,
    required this.node,
    required this.field,
  });

  void _showFieldEditorOverlay(
    BuildContext context,
    TapDownDetails details,
  ) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => overlayEntry?.remove(),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: details.globalPosition.dx,
              top: details.globalPosition.dy,
              child: Material(
                child: field.prototype.editorBuilder!(
                  context,
                  () => overlayEntry?.remove(),
                  field.data,
                  (dynamic data, {required FlFieldEventType eventType}) {
                    controller.setFieldData(
                      node.id,
                      field.prototype.idName,
                      data: data,
                      eventType: eventType,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    if (node.state.isCollapsed) {
      return SizedBox.shrink(key: field.key);
    }

    // Get the field content either from the custom builder or use default visualizer.

    // Wrap the content with a GestureDetector to ensure tap handling.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (details) {
          if (field.prototype.onVisualizerTap != null) {
            field.prototype.onVisualizerTap!(field.data, (dynamic data) {
              controller.setFieldData(
                node.id,
                field.prototype.idName,
                data: data,
                eventType: FlFieldEventType.submit,
              );
            });
          } else {
            _showFieldEditorOverlay(context, details);
          }
        },
        child: Container(
          padding: field.prototype.style.padding,
          decoration: field.prototype.style.decoration,
          child: Row(
            spacing: 8,
            children: [
              Flexible(
                child: Text(
                  field.prototype.displayName(context),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 56,
                child: field.prototype.visualizerBuilder(field.data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
