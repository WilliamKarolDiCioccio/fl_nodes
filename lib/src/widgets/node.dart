import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:os_detect/os_detect.dart' as os_detect;
import 'package:tuple/tuple.dart';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/utils/context_menu.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';

import '../constants.dart';
import '../core/models/entities.dart';
import '../core/utils/renderbox.dart';

class NodeWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final NodeInstance node;
  final FlNodeStyle style;

  const NodeWidget({
    super.key,
    required this.controller,
    required this.node,
    required this.style,
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
  String get nodeName => widget.node.prototype.displayName;
  Color get nodeColor => widget.node.prototype.color;

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
          return Tuple2(node.id, port.prototype.idName);
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

    final node = widget.controller.nodes[_tempLink!.item1]!;
    final port = node.ports[_tempLink!.item2]!;

    final absolutePortOffset = node.offset + port.offset;

    widget.controller.drawTempLink(
      port.prototype.type,
      absolutePortOffset,
      worldPosition!,
    );
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
          onSelected: () => widget.controller.toggleCollapseSelectedNodes(
            !widget.node.state.isCollapsed,
          ),
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
            if (value.ports.any(
              (port) => port.direction != startPort.prototype.direction,
            )) {
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
          label: entry.value.displayName,
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
                      (element) =>
                          element.value.prototype.direction !=
                          startPort.prototype.direction,
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

    Widget controlsWrapper(Widget child) {
      return os_detect.isAndroid || os_detect.isIOS
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
                      entries: portContextMenuEntries(
                        event.position,
                        locator: locator,
                      ),
                      position: event.position,
                    );
                  } else if (!isContextMenuVisible) {
                    // Else show the node context menu
                    createAndShowContextMenu(
                      context,
                      entries: nodeContextMenuEntries(),
                      position: event.position,
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
                      entries: createSubmenuEntries(event.position),
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

    return controlsWrapper(
      IntrinsicHeight(
        child: IntrinsicWidth(
          child: Stack(
            key: widget.node.key,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: widget.node.state.isSelected
                    ? widget.style.selectedDecoration
                    : widget.style.decoration,
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
                      color: widget.node.prototype.color,
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
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () =>
                              widget.controller.toggleCollapseSelectedNodes(
                            !widget.node.state.isCollapsed,
                          ),
                          child: Icon(
                            widget.node.state.isCollapsed
                                ? Icons.expand_more
                                : Icons.expand_less,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Text(
                          nodeName,
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
                          ..._generateRows().map(
                            (row) => _buildRow(row.item1, row.item2, row.item3),
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

  List<Tuple3<PortInstance?, FieldInstance?, PortInstance?>> _generateRows() {
    final rows = <Tuple3<PortInstance?, FieldInstance?, PortInstance?>>[];

    final inPorts = widget.node.ports.values
        .where((port) => port.prototype.direction == PortDirection.input)
        .toList();
    final outPorts = widget.node.ports.values
        .where((port) => port.prototype.direction == PortDirection.output)
        .toList();
    final fields = widget.node.fields.values.toList();

    final maxLength = [inPorts.length, fields.length, outPorts.length]
        .reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < maxLength; i++) {
      final inPort = i < inPorts.length ? inPorts[i] : null;
      final field = i < fields.length ? fields[i] : null;
      final outPort = i < outPorts.length ? outPorts[i] : null;
      rows.add(Tuple3(inPort, field, outPort));
    }

    return rows;
  }

  Widget _buildRow(
    PortInstance? inPort,
    FieldInstance? field,
    PortInstance? outPort,
  ) {
    late final MainAxisAlignment alignment;

    if (inPort != null && field == null && outPort == null) {
      alignment = MainAxisAlignment.start;
    } else if (inPort == null && field != null && outPort == null) {
      alignment = MainAxisAlignment.center;
    } else if (inPort == null && field == null && outPort != null) {
      alignment = MainAxisAlignment.end;
    } else {
      alignment = MainAxisAlignment.spaceBetween;
    }

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.max,
      spacing: 16,
      children: [
        if (inPort != null) _buildPort(inPort),
        if (field != null) _buildField(field),
        if (outPort != null) _buildPort(outPort),
      ],
    );
  }

  // See https://github.com/WilliamKarolDiCioccio/fl_nodes/issues/8
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
                color: widget.style.fieldStyle.decoration.color,
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
          onTapDown: (details) {
            if (field.prototype.onVisualizerTap != null) {
              field.prototype.onVisualizerTap?.call(
                (dynamic data) {
                  widget.controller.setFieldData(
                    widget.node.id,
                    field.prototype.idName,
                    data: data,
                    eventType: FieldEventType.submit,
                  );
                },
              );
            } else {
              _showFieldEditorOverlay(
                widget.node.id,
                field,
                details,
              );
            }
          },
          child: Container(
            padding: widget.style.fieldStyle.padding,
            decoration: widget.style.fieldStyle.decoration,
            child: field.prototype.visualizerBuilder(field.data),
          ),
        ),
        Text(
          field.prototype.displayName,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        if (field.prototype.icon != null)
          Icon(
            field.prototype.icon,
            color: Colors.white70,
            size: 16,
          ),
      ],
    );
  }

  Widget _buildPort(PortInstance port) {
    if (widget.node.state.isCollapsed) {
      return SizedBox(
        key: port.key,
        height: 0,
        width: 0,
      );
    }

    return Row(
      mainAxisAlignment: port.prototype.direction == PortDirection.input
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      key: port.key,
      spacing: 4,
      children: [
        Text(
          port.prototype.displayName,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        if (port.prototype.icon != null)
          Icon(
            port.prototype.icon,
            color: Colors.white70,
            size: 16,
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
            port.prototype.direction == PortDirection.input
                ? 0
                : constraints.maxWidth,
            relativeOffset.dy + portBox.size.height / 2,
          );

          final type = port.prototype.type;
          final direction = port.prototype.direction;

          return CustomPaint(
            painter: _PortSymbolPainter(
              position: port.offset,
              style: widget.style.portStyle,
              direction: direction,
              type: type,
            ),
          );
        },
      ),
    );
  }
}

class _PortSymbolPainter extends CustomPainter {
  final Offset position;
  final FlPortStyle style;
  final PortDirection direction;
  final PortType type;
  static const double portSize = 4;
  static const double hitBoxSize = 16;

  _PortSymbolPainter({
    required this.position,
    required this.style,
    required this.direction,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.color[type]![direction]!
      ..style = PaintingStyle.fill;

    if (type == PortType.control) {
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
    } else {
      canvas.drawCircle(position, portSize, paint);
    }

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
