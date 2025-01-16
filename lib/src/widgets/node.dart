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

  double get _zoom => widget.controller.viewportZoom;
  Offset get _offset => widget.controller.viewportOffset;

  @override
  void initState() {
    super.initState();

    _handleControllerEvents();
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    super.dispose();
  }

  void _handleControllerEvents() {
    widget.controller.eventBus.events.listen((event) {
      if (event.isHandled || !mounted) return;

      if (event is SelectionEvent) {
        if (event.ids.contains(widget.node.id)) {
          setState(() {
            widget.node.state.isSelected = true;
          });
        } else {
          setState(() {
            widget.node.state.isSelected = false;
          });
        }
      } else if (event is DragSelectionEvent) {
        if (event.ids.contains(widget.node.id)) {
          setState(() {
            widget.node.offset += event.delta / widget.controller.viewportZoom;
          });
        }
      } else if (event is CollapseNodeEvent) {
        if (event.ids.contains(widget.node.id)) {
          setState(() {});
        }
      } else if (event is ExpandNodeEvent) {
        if (event.ids.contains(widget.node.id)) {
          setState(() {});
        }
      } else if (event is NodeFieldEditEvent) {
        if (event.id == widget.node.id) {
          setState(() {});
        }
      }
    });
  }

  void _startEdgeTimer(Offset position) {
    const edgeThreshold = 50.0; // Distance from edge to start moving
    final moveAmount =
        5.0 / widget.controller.viewportZoom; // Amount to move per frame

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
          Offset(-dx / _zoom, -dy / _zoom),
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
      _offset,
      _zoom,
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
      _offset,
      _zoom,
    );

    final nodeOffset = widget.controller.nodes[_tempLink!.item1]!.offset;
    final portOffset = widget
        .controller.nodes[_tempLink!.item1]!.ports[_tempLink!.item2]!.offset;
    final absolutePortOffset = nodeOffset + portOffset;

    widget.controller.drawTempLink(absolutePortOffset, worldPosition!);
  }

  void _onLinkCancel() {
    widget.controller.clearTempLink();
    _isLinking = false;
    _tempLink = null;
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
              widget.controller.removeNodes(
                widget.controller.selectedNodeIds,
              );
            } else {
              widget.controller.removeNodes({widget.node.id});
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
        _offset,
        _zoom,
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
                final locator = _isNearPort(event.position);

                if (event.buttons == kSecondaryMouseButton) {
                  if (!widget.node.state.isSelected) {
                    widget.controller.clearSelection();
                    widget.controller.selectNodesById({widget.node.id});
                  }

                  if (locator != null) {
                    /// If a port is near the cursor, show the port context menu
                    await createAndShowContextMenu(
                      context,
                      portContextMenuEntries(
                        event.position,
                        locator: locator,
                      ),
                      event.position,
                    );
                  } else if (!isContextMenuVisible) {
                    // Else show the node context menu
                    await createAndShowContextMenu(
                      context,
                      nodeContextMenuEntries(),
                      event.position,
                    );
                  }
                } else if (event.buttons == kPrimaryMouseButton) {
                  // Abort if the cursor is over a port
                  if (locator != null) {
                    if (_isLinking && _tempLink != null) {
                      _onLinkEnd(locator);
                    } else {
                      _onLinkStart(locator);
                    }
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
                    await createAndShowContextMenu(
                      context,
                      createSubmenuEntries(event.position),
                      event.position,
                    ).then((value) {
                      _onLinkCancel();
                    });
                  }
                } else {
                  _resetEdgeTimer();
                }
              },
              child: child,
            );
    }

    return controlsWrapper(
      IntrinsicWidth(
        child: IntrinsicHeight(
          key: widget.node.key,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Visibility(
                visible: !widget.node.state.isCollapsed,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF212121),
                    border: Border.all(
                      color: widget.node.state.isSelected
                          ? widget.node.color
                          : Colors.transparent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              ...widget.node.ports.entries.map(
                (entry) => _buildPortIndicator(entry.value),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.node.state.isSelected
                            ? widget.node.color
                            : widget.node.color.withValues(
                                red: widget.node.color.r / 1.35,
                                green: widget.node.color.g / 1.35,
                                blue: widget.node.color.b / 1.35,
                              ),
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
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              setState(() {
                                widget.node.state.isCollapsed =
                                    !widget.node.state.isCollapsed;
                              });
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
                    Visibility(
                      visible: !widget.node.state.isCollapsed,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 2.0,
                          children: [
                            ...widget.node.fields.entries.map(
                              (entry) => _buildField(entry.value),
                            ),
                            if (widget.node.fields.isNotEmpty)
                              const SizedBox(height: 8),
                            ...widget.node.ports.entries.map(
                              (entry) => _buildPortRow(entry.value),
                            ),
                          ],
                        ),
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
                  (value) {
                    widget.controller.setFieldData(
                      nodeId,
                      field.id,
                      value,
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
          field.dataType.runtimeType.toString(),
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
    return Visibility(
      visible: !widget.node.state.isCollapsed,
      child: Row(
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
      ),
    );
  }

  Widget _buildPortIndicator(PortInstance port) {
    return Visibility(
      visible: !widget.node.state.isCollapsed,
      child: Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final portColor =
                port.isInput ? Colors.purple[200]! : Colors.green[300]!;

            if (widget.node.state.isCollapsed) {
              return CustomPaint(
                painter: _PortDotPainter(
                  position: Offset.zero,
                  color: portColor,
                ),
              );
            }

            final portKey = port.key;
            final RenderBox? portBox =
                portKey.currentContext?.findRenderObject() as RenderBox?;

            if (portBox == null) return const SizedBox();

            final nodeBox = widget.node.key.currentContext?.findRenderObject()
                as RenderBox?;
            if (nodeBox == null) return const SizedBox();

            final portOffset = portBox.localToGlobal(Offset.zero);
            final nodeOffset = nodeBox.localToGlobal(Offset.zero);
            final relativeOffset = portOffset - nodeOffset;

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
