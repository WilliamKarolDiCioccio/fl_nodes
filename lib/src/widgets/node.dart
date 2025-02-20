import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/utils/context_menu.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';

import '../constants.dart';
import '../core/models/entities.dart';
import '../core/utils/renderbox.dart';

import 'builders.dart';

typedef _TempLink = ({String nodeId, String portId});

/// The main NodeWidget which represents a node in the editor.
/// It now ensures that fields (regardless of whether a custom fieldBuilder is used)
/// still respond to tap events in the same way as before.
class NodeWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final NodeInstance node;
  final FlNodeHeaderBuilder? headerBuilder;
  final FlNodeFieldBuilder? fieldBuilder;
  final FlNodePortBuilder? portBuilder;
  final FlNodeContextMenuBuilder? contextMenuBuilder;
  final FlNodeBuilder? nodeBuilder;

  const NodeWidget({
    super.key,
    required this.controller,
    required this.node,
    this.fieldBuilder,
    this.headerBuilder,
    this.portBuilder,
    this.contextMenuBuilder,
    this.nodeBuilder,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  // Wrapper state
  double get viewportZoom => widget.controller.viewportZoom;
  Offset get viewportOffset => widget.controller.viewportOffset;
  FlNodeStyle get style => widget.node.prototype.style;

  // Interaction state
  bool _isLinking = false;

  // Interaction kinematics
  Offset? _lastPanPosition;
  Timer? _edgeTimer;
  _TempLink? _tempLink;

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
      setState(() {
        widget.node.state.isSelected = event.nodeIds.contains(widget.node.id);
      });
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
    const edgeThreshold = 50.0;
    final moveAmount = 5.0 / widget.controller.viewportZoom;
    final editorBounds = getEditorBoundsInScreen(kNodeEditorWidgetKey);
    if (editorBounds == null) return;

    _edgeTimer?.cancel();

    _edgeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
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

  _TempLink? _isNearPort(Offset position) {
    final worldPosition = screenToWorld(position, viewportOffset, viewportZoom);
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
          return (nodeId: node.id, portId: port.prototype.idName);
        }
      }
    }
    return null;
  }

  void _onLinkStart(_TempLink locator) {
    _tempLink = (nodeId: locator.nodeId, portId: locator.portId);
    _isLinking = true;
  }

  void _onLinkUpdate(Offset position) {
    final worldPosition = screenToWorld(position, viewportOffset, viewportZoom);
    final node = widget.controller.nodes[_tempLink!.nodeId]!;
    final port = node.ports[_tempLink!.portId]!;
    final absolutePortOffset = node.offset + port.offset;

    widget.controller.drawTempLink(
      port.prototype.style.linkStyle,
      absolutePortOffset,
      worldPosition!,
    );
  }

  void _onLinkCancel() {
    _isLinking = false;
    _tempLink = null;
    widget.controller.clearTempLink();
  }

  void _onLinkEnd(_TempLink locator) {
    widget.controller.addLink(
      _tempLink!.nodeId,
      _tempLink!.portId,
      locator.nodeId,
      locator.portId,
    );
    _isLinking = false;
    _tempLink = null;
    widget.controller.clearTempLink();
  }

  /// UPDATED _buildField:
  /// This method now always wraps the field content in a GestureDetector that
  /// handles tap events—even when a custom fieldBuilder is provided.
  Widget _buildField(FieldInstance field) {
    if (widget.node.state.isCollapsed) {
      return SizedBox(key: field.key, height: 0, width: 0);
    }

    // Get the field content either from the custom builder or use default visualizer.
    final fieldContent = widget.fieldBuilder != null
        ? widget.fieldBuilder!(context, field, style)
        : Container(
            padding: field.prototype.style.padding,
            decoration: field.prototype.style.decoration,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    field.prototype.displayName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: field.prototype.visualizerBuilder(field.data)),
              ],
            ),
          );

    // Wrap the content with a GestureDetector to ensure tap handling.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (details) {
          if (field.prototype.onVisualizerTap != null) {
            field.prototype.onVisualizerTap!(field.data, (dynamic data) {
              widget.controller.setFieldData(
                widget.node.id,
                field.prototype.idName,
                data: data,
                eventType: FieldEventType.submit,
              );
            });
          } else {
            _showFieldEditorOverlay(widget.node.id, field, details);
          }
        },
        child: fieldContent,
      ),
    );
  }

  Widget _buildPort(PortInstance port) {
    if (widget.node.state.isCollapsed) {
      return SizedBox(key: port.key, height: 0, width: 0);
    }

    if (widget.portBuilder != null) {
      return widget.portBuilder!(context, port, style);
    }

    final isInput = port.prototype.direction == PortDirection.input;
    return Row(
      mainAxisAlignment:
          isInput ? MainAxisAlignment.start : MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      key: port.key,
      children: [
        Flexible(
          child: Text(
            port.prototype.displayName,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            textAlign: isInput ? TextAlign.left : TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<Widget> _generateLayout() {
    final inPorts = widget.node.ports.values
        .where((port) => port.prototype.direction == PortDirection.input)
        .toList();
    final outPorts = widget.node.ports.values
        .where((port) => port.prototype.direction == PortDirection.output)
        .toList();
    final fields = widget.node.fields.values.toList();

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: inPorts.map((port) => _buildPort(port)).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: outPorts.map((port) => _buildPort(port)).toList(),
            ),
          ),
        ],
      ),
      if (fields.isNotEmpty) const SizedBox(height: 16),
      ...fields.map((field) => _buildField(field)),
    ];
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
                child: field.prototype.editorBuilder!(
                  context,
                  () => overlayEntry?.remove(),
                  field.data,
                  (dynamic data, {required FieldEventType eventType}) {
                    widget.controller.setFieldData(
                      nodeId,
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

  Widget controlsWrapper(Widget child) {
    return os_detect.isAndroid || os_detect.isIOS
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            // A quick tap simply selects the node if not already selected.
            onTap: () {
              if (!widget.controller.selectedNodeIds.contains(widget.node.id)) {
                widget.controller.selectNodesById({widget.node.id});
              }
            },
            // A long press opens the context menu.
            onLongPressStart: (details) {
              final position = details.globalPosition;
              final locator = _isNearPort(position);

              // Ensure the node is selected before showing context menus.
              if (!widget.node.state.isSelected) {
                widget.controller.clearSelection();
                widget.controller.selectNodesById({widget.node.id});
              }

              if (locator != null && !widget.node.state.isCollapsed) {
                // Port-specific context menu.
                createAndShowContextMenu(
                  context,
                  entries: _portContextMenuEntries(position, locator: locator),
                  position: position,
                );
              } else if (!isContextMenuVisible) {
                // Node context menu.
                final entries = widget.contextMenuBuilder != null
                    ? widget.contextMenuBuilder!(context, widget.node)
                    : _defaultNodeContextMenuEntries();
                createAndShowContextMenu(
                  context,
                  entries: entries,
                  position: position,
                );
              }
            },
            // Save the current pointer position for later use.
            onPanDown: (details) {
              _lastPanPosition = details.globalPosition;
            },
            // When the drag starts, decide whether to initiate linking or selection.
            onPanStart: (details) {
              final position = details.globalPosition;
              _isLinking = false;
              _tempLink = null;

              final locator = _isNearPort(position);
              if (locator != null) {
                // Start linking if the gesture begins near a port.
                _isLinking = true;
                _onLinkStart(locator);
              } else {
                // If not linking and the node isn’t selected, select it.
                if (!widget.controller.selectedNodeIds
                    .contains(widget.node.id)) {
                  widget.controller.selectNodesById({widget.node.id});
                }
              }
            },
            // Update linking or drag-selection as the pointer moves.
            onPanUpdate: (details) {
              _lastPanPosition = details.globalPosition;
              if (_isLinking) {
                _onLinkUpdate(details.globalPosition);
              } else {
                _startEdgeTimer(details.globalPosition);
                widget.controller.dragSelection(details.delta);
              }
            },
            // When the drag ends, complete the linking or cancel/reset the selection.
            onPanEnd: (details) {
              if (_isLinking) {
                final locator = _isNearPort(_lastPanPosition!);
                if (locator != null) {
                  _onLinkEnd(locator);
                } else {
                  createAndShowContextMenu(
                    context,
                    entries: _createSubmenuEntries(_lastPanPosition!),
                    position: _lastPanPosition!,
                    onDismiss: (value) => _onLinkCancel(),
                  );
                }
                _isLinking = false;
              } else {
                _resetEdgeTimer();
              }
            },
            child: child,
          )
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
                  createAndShowContextMenu(
                    context,
                    entries: _portContextMenuEntries(
                      event.position,
                      locator: locator,
                    ),
                    position: event.position,
                  );
                } else if (!isContextMenuVisible) {
                  final entries = widget.contextMenuBuilder != null
                      ? widget.contextMenuBuilder!(context, widget.node)
                      : _defaultNodeContextMenuEntries();
                  createAndShowContextMenu(
                    context,
                    entries: entries,
                    position: event.position,
                  );
                }
              } else if (event.buttons == kPrimaryMouseButton) {
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
                    entries: _createSubmenuEntries(event.position),
                    position: event.position,
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

  List<ContextMenuEntry> _defaultNodeContextMenuEntries() {
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
                title: Text(widget.node.prototype.displayName),
                content: Text(widget.node.prototype.description),
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
        onSelected: () => widget.controller
            .toggleCollapseSelectedNodes(!widget.node.state.isCollapsed),
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
        onSelected: () => widget.controller.clipboard.cutSelection(),
      ),
      MenuItem(
        label: 'Copy',
        icon: Icons.copy,
        onSelected: () => widget.controller.clipboard.copySelection(),
      ),
    ];
  }

  List<ContextMenuEntry> _portContextMenuEntries(
    Offset position, {
    required _TempLink locator,
  }) {
    return [
      const MenuHeader(text: "Port Menu"),
      MenuItem(
        label: 'Remove Links',
        icon: Icons.remove_circle,
        onSelected: () {
          widget.controller.breakPortLinks(locator.nodeId, locator.portId);
        },
      ),
    ];
  }

  List<ContextMenuEntry> _createSubmenuEntries(Offset position) {
    final fromLink = _tempLink != null;
    final List<MapEntry<String, NodePrototype>> compatiblePrototypes = [];

    if (fromLink) {
      final startPort =
          widget.controller.nodes[_tempLink!.nodeId]!.ports[_tempLink!.portId]!;
      widget.controller.nodePrototypes.forEach((key, value) {
        if (value.ports.any(
          (port) =>
              port.direction != startPort.prototype.direction &&
              port.type == startPort.prototype.type &&
              (port.dataType == startPort.prototype.dataType ||
                  port.dataType == dynamic ||
                  startPort.prototype.dataType == dynamic),
        )) {
          compatiblePrototypes.add(MapEntry(key, value));
        }
      });
    } else {
      widget.controller.nodePrototypes.forEach(
        (key, value) => compatiblePrototypes.add(MapEntry(key, value)),
      );
    }

    final worldPosition = screenToWorld(position, viewportOffset, viewportZoom);

    return compatiblePrototypes.map((entry) {
      return MenuItem(
        label: entry.value.displayName,
        icon: Icons.widgets,
        onSelected: () {
          widget.controller.addNode(
            entry.key,
            offset: worldPosition ?? Offset.zero,
          );
          if (fromLink) {
            final addedNode = widget.controller.nodes.values.last;
            final startPort = widget
                .controller.nodes[_tempLink!.nodeId]!.ports[_tempLink!.portId]!;
            widget.controller.addLink(
              _tempLink!.nodeId,
              _tempLink!.portId,
              addedNode.id,
              addedNode.ports.entries
                  .firstWhere(
                    (port) =>
                        port.value.prototype.direction !=
                            startPort.prototype.direction &&
                        port.value.prototype.type == startPort.prototype.type &&
                        (port.value.prototype.dataType ==
                                startPort.prototype.dataType ||
                            port.value.prototype.dataType == dynamic ||
                            startPort.prototype.dataType == dynamic),
                  )
                  .value
                  .prototype
                  .idName,
            );
            _isLinking = false;
            _tempLink = null;
            setState(() {});
          }
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.node.onRendered(widget.node);
    });

    // If a custom nodeBuilder is provided, use it directly.
    if (widget.nodeBuilder != null) {
      return widget.nodeBuilder!(context, widget.node);
    }

    return controlsWrapper(
      IntrinsicHeight(
        child: IntrinsicWidth(
          child: Stack(
            key: widget.node.key,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: widget.node.state.isSelected
                    ? style.selectedDecoration
                    : style.decoration,
              ),
              ...widget.node.ports.entries.map(
                (entry) => _buildPortIndicator(entry.value),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.headerBuilder != null
                      ? widget.headerBuilder!(
                          context,
                          widget.node,
                          style,
                          () => widget.controller.toggleCollapseSelectedNodes(
                            !widget.node.state.isCollapsed,
                          ),
                        )
                      : _NodeHeaderWidget(
                          node: widget.node,
                          onToggleCollapse: () =>
                              widget.controller.toggleCollapseSelectedNodes(
                            !widget.node.state.isCollapsed,
                          ),
                        ),
                  Offstage(
                    offstage: widget.node.state.isCollapsed,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _generateLayout(),
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
            port.prototype.direction == PortDirection.input
                ? 0
                : constraints.maxWidth,
            relativeOffset.dy + portBox.size.height / 2,
          );

          return CustomPaint(
            painter: _PortSymbolPainter(
              position: port.offset,
              style: port.prototype.style,
              direction: port.prototype.direction,
            ),
          );
        },
      ),
    );
  }
}

class _NodeHeaderWidget extends StatelessWidget {
  final NodeInstance node;
  final VoidCallback onToggleCollapse;

  const _NodeHeaderWidget({
    required this.node,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: node.prototype.style.headerStyle.padding,
      decoration: node.prototype.style.headerStyle.decoration,
      child: Row(
        children: [
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: onToggleCollapse,
            child: Icon(
              node.state.isCollapsed ? Icons.expand_more : Icons.expand_less,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              node.prototype.displayName,
              style: node.prototype.style.headerStyle.textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortSymbolPainter extends CustomPainter {
  final Offset position;
  final FlPortStyle style;
  final PortDirection direction;
  static const double portSize = 4;
  static const double hitBoxSize = 16;

  _PortSymbolPainter({
    required this.position,
    required this.style,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    switch (style.shape) {
      case FlPortShape.circle:
        _paintCircle(canvas, paint);
        break;
      case FlPortShape.triangle:
        _paintTriangle(canvas, paint);
        break;
    }

    if (kDebugMode) {
      _paintDebugHitBox(canvas);
    }
  }

  void _paintCircle(Canvas canvas, Paint paint) {
    canvas.drawCircle(position, portSize, paint);
  }

  void _paintTriangle(Canvas canvas, Paint paint) {
    final path = Path();

    if (direction == PortDirection.input) {
      path.moveTo(position.dx + portSize, position.dy - portSize);
      path.lineTo(position.dx - portSize, position.dy);
      path.lineTo(position.dx + portSize, position.dy + portSize);
    } else {
      path.moveTo(position.dx - portSize, position.dy - portSize);
      path.lineTo(position.dx + portSize, position.dy);
      path.lineTo(position.dx - portSize, position.dy + portSize);
    }

    path.close();
    canvas.drawPath(path, paint);
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
  bool shouldRepaint(covariant _PortSymbolPainter oldDelegate) {
    return oldDelegate.position != position;
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
