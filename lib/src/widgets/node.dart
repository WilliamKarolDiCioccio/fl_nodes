import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:tuple/tuple.dart';

import 'package:fl_nodes/src/core/controllers/node_editor.dart';
import 'package:fl_nodes/src/utils/context_menu.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';

import '../core/controllers/node_editor_events.dart';
import '../core/models/entities.dart';
import '../core/utils/constants.dart';
import '../core/utils/platform.dart';
import '../core/utils/renderbox.dart';

class NodeWidget extends StatefulWidget {
  final NodeInstance node;
  final FlNodeEditorController controller;
  const NodeWidget({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  // Interaction state
  bool _isLinking = false;

  // Interaction kinematics
  Timer? _edgeTimer;
  Tuple2<String, String>? _tempLink;

  double get viewportZoom => widget.controller.viewportZoom;
  Offset get viewportOffset => widget.controller.viewportOffset;

  @override
  void initState() {
    super.initState();

    widget.controller.eventBus.events.listen(_handleControllerEvents);
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    super.dispose();
  }

  void _handleControllerEvents(NodeEditorEvent event) {
    if (!mounted || event.isHandled) return;

    if (event is SelectionEvent) {
      if (event.nodeIds.contains(widget.node.id)) {
        setState(() {
          widget.node.state.isSelected = true;
        });
      } else {
        setState(() {
          widget.node.state.isSelected = false;
        });
      }
    } else if (event is DragSelectionEvent) {
      if (event.nodeIds.contains(widget.node.id)) {
        setState(() {});
      }
    } else if (event is NodeFieldEvent &&
        event.nodeId == widget.node.id &&
        event.eventType == FieldEventType.submit) {
      setState(() {});
    }
  }

  void _startEdgeTimer(Offset position) {
    // Distance from edge to start moving
    const edgeThreshold = 50.0;
    // Amount to move per frame
    final moveAmount = 5.0 / widget.controller.viewportZoom;

    final editorBounds = getEditorBoundsInScreen(kNodeEditorWidgetKey);
    if (editorBounds == null) return;

    _edgeTimer?.cancel();

    _edgeTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) async {
      double dx = 0;
      double dy = 0;
      final rect = editorBounds;

      if (position.dx < rect.left + edgeThreshold) {
        dx = -moveAmount;
      } else if (position.dx > rect.right - edgeThreshold) {
        dx = moveAmount;
      }
      if (position.dy < rect.top + edgeThreshold) {
        dy = -moveAmount;
      } else if (position.dy > rect.bottom - edgeThreshold) {
        dy = moveAmount;
      }

      if (dx != 0 || dy != 0) {
        widget.controller.dragSelection(Offset(dx, dy));
        widget.controller.setViewportOffset(
          Offset(-dx / viewportZoom, -dy / viewportZoom),
          animate: false,
        );
      }
    });
  }

  void _resetEdgeTimer() {
    _edgeTimer?.cancel();
  }

  Tuple2<String, String>? _isNearPort(Offset position) {
    final worldPosition = screenToWorld(
      position,
      viewportOffset,
      viewportZoom,
    );

    final near = Rect.fromCenter(
      center: worldPosition!,
      width: kSpatialHashingCellSize,
      height: kSpatialHashingCellSize,
    );

    final nearNodeIds =
        widget.controller.spatialHashGrid.queryNodeIdsInArea(near);

    for (final nodeId in nearNodeIds) {
      final node = widget.controller.nodes[nodeId]!;

      for (final port in node.ports.values) {
        final absolutePortPosition = node.offset + port.offset;

        if ((worldPosition - absolutePortPosition).distance < 12) {
          return Tuple2(node.id, port.id);
        }
      }
    }

    return null;
  }

  // TODO: Find a way to decouple the link drawing code

  void _onLinkStart(Tuple2<String, String> locator) {
    _tempLink = Tuple2(locator.item1, locator.item2);
    _isLinking = true;
  }

  void _onLinkUpdate(Offset position) {
    final worldPosition = screenToWorld(
      position,
      viewportOffset,
      viewportZoom,
    );

    final nodeOffset = widget.controller.nodes[_tempLink!.item1]!.offset;
    final portOffset = widget
        .controller.nodes[_tempLink!.item1]!.ports[_tempLink!.item2]!.offset;
    final absolutePortOffset = nodeOffset + portOffset;

    widget.controller.drawTempLink(absolutePortOffset, worldPosition!);
  }

  void _onLinkCancel() {
    _isLinking = false;
    _tempLink = null;
    widget.controller.clearTempLink();
  }

  void _onLinkEnd(Tuple2<String, String> locator) {
    widget.controller.addLink(
      _tempLink!.item1,
      _tempLink!.item2,
      locator.item1,
      locator.item2,
    );

    _isLinking = false;
    _tempLink = null;
    widget.controller.clearTempLink();
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.node.onRendered(widget.node);
    });

    // TODO: Find a way to decouple the context menu entries

    List<ContextMenuEntry> nodeContextMenuEntries() {
      return [
        const MenuHeader(text: 'Node Menu'),
        MenuItem(
          label: 'See Description',
          icon: Icons.info,
          onSelected: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(widget.node.name),
                  content: Text(widget.node.description),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const MenuDivider(),
        MenuItem(
          label: widget.node.state.isCollapsed ? 'Expand' : 'Collapse',
          icon: widget.node.state.isCollapsed
              ? Icons.arrow_drop_down
              : Icons.arrow_right,
          onSelected: () {
            if (widget.node.state.isCollapsed) {
              widget.controller.expandSelectedNodes();
            } else {
              widget.controller.collapseSelectedNodes();
            }
          },
        ),
        const MenuDivider(),
        MenuItem(
          label: 'Delete',
          icon: Icons.delete,
          onSelected: () {
            if (widget.node.state.isSelected) {
              for (final nodeId in widget.controller.selectedNodeIds) {
                widget.controller.removeNode(nodeId);
              }
            } else {
              for (final nodeId in widget.controller.selectedNodeIds) {
                widget.controller.removeNode(nodeId);
              }
            }
            widget.controller.clearSelection();
          },
        ),
        MenuItem(
          label: 'Cut',
          icon: Icons.content_cut,
          onSelected: () => widget.controller.cutSelection(),
        ),
        MenuItem(
          label: 'Copy',
          icon: Icons.copy,
          onSelected: () => widget.controller.copySelection(),
        ),
      ];
    }

    List<ContextMenuEntry> portContextMenuEntries(
      Offset position, {
      required Tuple2<String, String> locator,
    }) {
      return [
        const MenuHeader(text: "Port Menu"),
        MenuItem(
          label: 'Remove Links',
          icon: Icons.remove_circle,
          onSelected: () {
            widget.controller.breakPortLinks(
              locator.item1,
              locator.item2,
            );
          },
        ),
      ];
    }

    List<ContextMenuEntry> createSubmenuEntries(Offset position) {
      final fromLink = _tempLink != null;

      final List<MapEntry<String, NodePrototype>> compatiblePrototypes = [];

      if (fromLink) {
        final startPort =
            widget.controller.nodes[_tempLink!.item1]!.ports[_tempLink!.item2]!;

        widget.controller.nodePrototypes.forEach(
          (key, value) {
            if (value.ports.any((port) => port.isInput != startPort.isInput)) {
              compatiblePrototypes.add(MapEntry(key, value));
            }
          },
        );
      } else {
        widget.controller.nodePrototypes.forEach(
          (key, value) => compatiblePrototypes.add(MapEntry(key, value)),
        );
      }

      final worldPosition = screenToWorld(
        position,
        viewportOffset,
        viewportZoom,
      );

      return compatiblePrototypes.map((entry) {
        return MenuItem(
          label: entry.value.name,
          icon: Icons.widgets,
          onSelected: () {
            widget.controller.addNode(
              entry.key,
              offset: worldPosition,
            );

            if (fromLink) {
              final addedNode = widget.controller.nodes.values.last;
              final startPort = widget
                  .controller.nodes[_tempLink!.item1]!.ports[_tempLink!.item2]!;

              widget.controller.addLink(
                _tempLink!.item1,
                _tempLink!.item2,
                addedNode.id,
                addedNode.ports.entries
                    .firstWhere(
                      (element) => element.value.isInput != startPort.isInput,
                    )
                    .value
                    .id,
              );

              _isLinking = false;
              _tempLink = null;

              setState(() {});
            }
          },
        );
      }).toList();
    }

    Widget controlsWrapper(Widget child) {
      return isMobile()
          ? child
          : ImprovedListener(
              behavior: HitTestBehavior.translucent,
              onPointerPressed: (event) async {
                _isLinking = false;
                _tempLink = null;

                final locator = _isNearPort(event.position);

                if (event.buttons == kSecondaryMouseButton) {
                  if (!widget.node.state.isSelected) {
                    widget.controller.clearSelection();
                    widget.controller.selectNodesById({widget.node.id});
                  }

                  if (locator != null && !widget.node.state.isCollapsed) {
                    /// If a port is near the cursor, show the port context menu
                    createAndShowContextMenu(
                      context,
                      portContextMenuEntries(
                        event.position,
                        locator: locator,
                      ),
                      event.position,
                    );
                  } else if (!isContextMenuVisible) {
                    // Else show the node context menu
                    createAndShowContextMenu(
                      context,
                      nodeContextMenuEntries(),
                      event.position,
                    );
                  }
                } else if (event.buttons == kPrimaryMouseButton) {
                  // Abort if the cursor is over a port
                  if (locator != null && !_isLinking && _tempLink == null) {
                    _onLinkStart(locator);
                  } else if (!widget.controller.selectedNodeIds
                      .contains(widget.node.id)) {
                    widget.controller.selectNodesById(
                      {widget.node.id},
                      holdSelection: HardwareKeyboard.instance.isControlPressed,
                    );
                  }
                }
              },
              onPointerMoved: (event) async {
                if (_isLinking) {
                  _onLinkUpdate(event.position);
                } else if (event.buttons == kPrimaryMouseButton) {
                  _startEdgeTimer(event.position);
                  widget.controller.dragSelection(event.delta);
                }
              },
              onPointerReleased: (event) async {
                if (_isLinking) {
                  final locator = _isNearPort(event.position);
                  if (locator != null) {
                    _onLinkEnd(locator);
                  } else {
                    createAndShowContextMenu(
                      context,
                      createSubmenuEntries(event.position),
                      event.position,
                      onDismiss: (value) => _onLinkCancel(),
                    );
                  }
                } else {
                  _resetEdgeTimer();
                }
              },
              child: child,
            );
    }

    late Color bodyColor;
    late Color headerColor;

    if (widget.node.state.isCollapsed) {
      headerColor = Colors.transparent;
      if (widget.node.state.isSelected) {
        bodyColor = widget.node.color;
      } else {
        bodyColor = widget.node.color.withValues(
          red: widget.node.color.r / 1.35,
          green: widget.node.color.g / 1.35,
          blue: widget.node.color.b / 1.35,
        );
      }
    } else {
      bodyColor = const Color(0xFF212121);
      if (widget.node.state.isSelected) {
        headerColor = widget.node.color;
      } else {
        headerColor = widget.node.color.withValues(
          red: widget.node.color.r / 1.35,
          green: widget.node.color.g / 1.35,
          blue: widget.node.color.b / 1.35,
        );
      }
    }

    return controlsWrapper(
      IntrinsicHeight(
        child: IntrinsicWidth(
          child: Stack(
            key: widget.node.key,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bodyColor,
                  border: Border.all(
                    color: widget.node.state.isSelected
                        ? widget.node.color
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              ...widget.node.ports.entries.map(
                (entry) => _buildPortIndicator(entry.value),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(7),
                        topRight: const Radius.circular(7),
                        bottomLeft: widget.node.state.isCollapsed
                            ? const Radius.circular(7)
                            : Radius.zero,
                        bottomRight: widget.node.state.isCollapsed
                            ? const Radius.circular(7)
                            : Radius.zero,
                      ),
                    ),
                    child: Row(
                      spacing: 8,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            if (widget.node.state.isCollapsed) {
                              widget.controller.expandSelectedNodes();
                            } else {
                              widget.controller.collapseSelectedNodes();
                            }
                          },
                          child: Icon(
                            widget.node.state.isCollapsed
                                ? Icons.expand_more
                                : Icons.expand_less,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.node.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Offstage(
                    offstage: widget.node.state.isCollapsed,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: widget.node.state.isCollapsed ? 0 : 2,
                        children: [
                          ...widget.node.fields.entries.map(
                            (entry) => _buildField(entry.value),
                          ),
                          ...widget.node.ports.entries.map(
                            (entry) => _buildPortRow(entry.value),
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

  void _showFieldEditorOverlay(
    String nodeId,
    FieldInstance field,
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
                color: Colors.transparent,
                child: field.editorBuilder!(
                  context,
                  () => overlayEntry?.remove(),
                  field.data,
                  (dynamic data, {required FieldEventType eventType}) {
                    widget.controller.setFieldData(
                      nodeId,
                      field.id,
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

  Widget _buildField(FieldInstance field) {
    if (widget.node.state.isCollapsed) {
      return SizedBox(
        key: field.key,
        height: 0,
        width: 0,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        GestureDetector(
          onTapDown: (details) =>
              field.onVisualizerTap ??
              _showFieldEditorOverlay(
                widget.node.id,
                field,
                details,
              ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: field.visualizerBuilder(field.data),
          ),
        ),
        Text(
          field.name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        Text(
          field.dataType.toString(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPortRow(PortInstance port) {
    if (widget.node.state.isCollapsed) {
      return SizedBox(
        key: port.key,
        height: 0,
        width: 0,
      );
    }

    return Row(
      mainAxisAlignment:
          port.isInput ? MainAxisAlignment.start : MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      key: port.key,
      spacing: 4,
      children: [
        Text(
          port.name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        Text(
          port.dataType.toString(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPortIndicator(PortInstance port) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final portKey = port.key;
          final RenderBox? portBox =
              portKey.currentContext?.findRenderObject() as RenderBox?;

          if (portBox == null) return const SizedBox();

          final nodeBox =
              widget.node.key.currentContext?.findRenderObject() as RenderBox?;
          if (nodeBox == null) return const SizedBox();

          final portOffset = portBox.localToGlobal(Offset.zero);
          final nodeOffset = nodeBox.localToGlobal(Offset.zero);
          var relativeOffset = portOffset - nodeOffset;

          if (widget.node.state.isCollapsed) {
            relativeOffset = Offset(
              relativeOffset.dx,
              relativeOffset.dy - constraints.maxHeight + 8,
            );
          }

          port.offset = Offset(
            port.isInput ? 0 : constraints.maxWidth,
            relativeOffset.dy + portBox.size.height / 2,
          );

          return CustomPaint(
            painter: _PortDotPainter(
              position: Offset(
                port.isInput ? 0 : constraints.maxWidth,
                relativeOffset.dy + portBox.size.height / 2,
              ),
              color: port.isInput ? Colors.purple[200]! : Colors.green[300]!,
            ),
          );
        },
      ),
    );
  }
}

class _PortDotPainter extends CustomPainter {
  final Offset position;
  final Color color;
  static const double portSize = 4;
  static const double hitBoxSize = 16;

  _PortDotPainter({
    required this.position,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, portSize, paint);

    if (kDebugMode) {
      _paintDebugHitBox(canvas);
    }
  }

  void _paintDebugHitBox(Canvas canvas) {
    final hitBoxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final hitBoxRect = Rect.fromCenter(
      center: position,
      width: hitBoxSize,
      height: hitBoxSize,
    );

    canvas.drawRect(hitBoxRect, hitBoxPaint);
  }

  @override
  bool shouldRepaint(covariant _PortDotPainter oldDelegate) {
    return position != oldDelegate.position || color != oldDelegate.color;
  }

  @override
  bool hitTest(Offset position) {
    final hitBoxRect = Rect.fromCenter(
      center: this.position,
      width: hitBoxSize,
      height: hitBoxSize,
    );

    return hitBoxRect.contains(position);
  }
}
