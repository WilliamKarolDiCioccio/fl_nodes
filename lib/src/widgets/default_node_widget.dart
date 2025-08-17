import 'dart:async';

import 'package:fl_nodes/src/core/utils/renderbox.dart';
import 'package:fl_nodes/src/widgets/context_menu.dart';
import 'package:fl_nodes/src/widgets/improved_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../constants.dart';
import '../core/controller/core.dart';
import '../core/models/entities.dart';
import '../core/models/events.dart';
import '../core/models/styles.dart';
import 'builders.dart';

typedef _TempLink = ({String nodeId, String portId});

/// The main NodeWidget which represents a node in the editor.
/// It now ensures that fields (regardless of whether a custom fieldBuilder is used)
/// still respond to tap events in the same way as before.
class DefaultNodeWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final NodeInstance node;
  final FlNodeHeaderBuilder? headerBuilder;
  final FlNodeFieldBuilder? fieldBuilder;
  final FlNodePortBuilder? portBuilder;
  final FlNodeContextMenuBuilder? contextMenuBuilder;
  final FlNodeBuilder? nodeBuilder;

  const DefaultNodeWidget({
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
  State<DefaultNodeWidget> createState() => _DefaultNodeWidgetState();
}

class _DefaultNodeWidgetState extends State<DefaultNodeWidget> {
  // Interaction state for linking ports.
  bool _isLinking = false;

  // Timer for auto-scrolling when dragging near the edge.
  Timer? _edgeTimer;

  // The last known position of the pointer (GestureDetector).
  Offset? _lastPanPosition;

  // Temporary link locator used during linking.
  _TempLink? _tempLink;

  late Color fakeTransparentColor;

  late List<PortInstance> inPorts;
  late List<PortInstance> outPorts;
  late List<FieldInstance> fields;

  double get viewportZoom => widget.controller.viewportZoom;
  Offset get viewportOffset => widget.controller.viewportOffset;

  @override
  void initState() {
    super.initState();

    // First initialization of the node's style and insertion in the spatial hash grid.

    widget.node.builtStyle =
        widget.node.prototype.styleBuilder(widget.node.state);
    widget.node.builtHeaderStyle =
        widget.node.prototype.headerStyleBuilder(widget.node.state);

    fakeTransparentColor = Color.alphaBlend(
      widget.node.builtStyle.decoration.color!.withAlpha(255),
      widget.controller.style.decoration.color!,
    );

    inPorts = widget.node.ports.values
        .where((port) => port.prototype.direction == PortDirection.input)
        .toList();
    outPorts = widget.node.ports.values
        .where((port) => port.prototype.direction == PortDirection.output)
        .toList();

    fields = widget.node.fields.values.toList();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _updatePortsPosition();
    });
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(DefaultNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Subsequent style and spatial hash grid updates are triggered by changes in the node's state or offset.
    if (widget.node.state != oldWidget.node.state ||
        widget.node.offset != oldWidget.node.offset ||
        widget.node.forceRecompute) {
      widget.node.builtStyle =
          widget.node.prototype.styleBuilder(widget.node.state);
      widget.node.builtHeaderStyle =
          widget.node.prototype.headerStyleBuilder(widget.node.state);

      fakeTransparentColor = Color.alphaBlend(
        widget.node.builtStyle.decoration.color!.withAlpha(255),
        widget.controller.style.decoration.color!,
      );

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _updatePortsPosition();
      });
    }

    if (widget.node.id != oldWidget.node.id || widget.node.forceRecompute) {
      fakeTransparentColor = Color.alphaBlend(
        widget.node.builtStyle.decoration.color!.withAlpha(255),
        widget.controller.style.decoration.color!,
      );

      inPorts = widget.node.ports.values
          .where((port) => port.prototype.direction == PortDirection.input)
          .toList();
      outPorts = widget.node.ports.values
          .where((port) => port.prototype.direction == PortDirection.output)
          .toList();

      fields = widget.node.fields.values.toList();
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

    final nearNodeIds = widget.controller.spatialHashGrid.queryArea(near);

    for (final nodeId in nearNodeIds) {
      final node = widget.controller.nodes[nodeId]!;
      for (final port in node.ports.values) {
        final absolutePortPosition = node.offset + port.offset;
        if ((worldPosition - absolutePortPosition).distance < 4) {
          return (nodeId: node.id, portId: port.prototype.idName);
        }
      }
    }

    return null;
  }

  void _onTmpLinkStart(_TempLink locator) {
    _tempLink = (nodeId: locator.nodeId, portId: locator.portId);
    _isLinking = true;
  }

  void _onTmpLinkUpdate(Offset position) {
    final worldPosition = screenToWorld(position, viewportOffset, viewportZoom);
    final node = widget.controller.nodes[_tempLink!.nodeId]!;
    final port = node.ports[_tempLink!.portId]!;
    final absolutePortOffset = node.offset + port.offset;

    widget.controller.drawTempLink(
      port.style.linkStyleBuilder(LinkState()),
      absolutePortOffset,
      worldPosition!,
    );
  }

  void _onTmpLinkCancel() {
    _isLinking = false;
    _tempLink = null;
    widget.controller.clearTempLink();
  }

  void _onTmpLinkEnd(_TempLink locator) {
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
        ? widget.fieldBuilder!(context, field, widget.node.builtStyle)
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
      return widget.portBuilder!(context, port, widget.node.builtStyle);
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
    return defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (!widget.node.state.isSelected) {
                widget.controller.selectNodesById({widget.node.id});
              }
            },
            onLongPressStart: (details) {
              final position = details.globalPosition;
              final locator = _isNearPort(position);

              if (!widget.node.state.isSelected) {
                widget.controller.selectNodesById({widget.node.id});
              }

              if (locator != null && !widget.node.state.isCollapsed) {
                createAndShowContextMenu(
                  context,
                  entries: _portContextMenuEntries(position, locator: locator),
                  position: position,
                );
              } else if (!isContextMenuVisible) {
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
            onPanDown: (details) {
              _lastPanPosition = details.globalPosition;
            },
            onPanStart: (details) {
              final position = details.globalPosition;
              _isLinking = false;
              _tempLink = null;

              final locator = _isNearPort(position);
              if (locator != null) {
                _isLinking = true;
                _onTmpLinkStart(locator);
              } else {
                if (!widget.node.state.isSelected) {
                  widget.controller.selectNodesById({widget.node.id});
                }
              }
            },
            onPanUpdate: (details) {
              _lastPanPosition = details.globalPosition;
              if (_isLinking) {
                _onTmpLinkUpdate(details.globalPosition);
              } else {
                _startEdgeTimer(details.globalPosition);
                widget.controller.dragSelection(details.delta);
              }
            },
            onPanEnd: (details) {
              if (_isLinking) {
                final locator = _isNearPort(_lastPanPosition!);
                if (locator != null) {
                  _onTmpLinkEnd(locator);
                } else {
                  createAndShowContextMenu(
                    context,
                    entries: _createSubmenuEntries(_lastPanPosition!),
                    position: _lastPanPosition!,
                    onDismiss: (value) => _onTmpLinkCancel(),
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
                  _onTmpLinkStart(locator);
                } else if (!widget.node.state.isSelected) {
                  widget.controller.selectNodesById(
                    {widget.node.id},
                    holdSelection: HardwareKeyboard.instance.isControlPressed,
                  );
                }
              }
            },
            onPointerMoved: (event) async {
              if (_isLinking) {
                _onTmpLinkUpdate(event.position);
              } else if (event.buttons == kPrimaryMouseButton) {
                _startEdgeTimer(event.position);
                widget.controller.dragSelection(event.delta);
              }
            },
            onPointerReleased: (event) async {
              if (_isLinking) {
                final locator = _isNearPort(event.position);
                if (locator != null) {
                  _onTmpLinkEnd(locator);
                } else {
                  createAndShowContextMenu(
                    context,
                    entries: _createSubmenuEntries(event.position),
                    position: event.position,
                    onDismiss: (value) => _onTmpLinkCancel(),
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
              widget.controller.removeNodeById(nodeId);
            }
          } else {
            for (final nodeId in widget.controller.selectedNodeIds) {
              widget.controller.removeNodeById(nodeId);
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
          startPort.prototype.compatibleWith,
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
              addedNode.ports.values
                  .map((port) => port.prototype)
                  .firstWhere(
                    startPort.prototype.compatibleWith,
                  )
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
                decoration: widget.controller.lodLevel <= 2
                    ? widget.node.builtStyle.decoration.copyWith(
                        color: fakeTransparentColor,
                        borderRadius: BorderRadius.zero,
                      )
                    : widget.node.builtStyle.decoration,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.headerBuilder != null
                      ? widget.headerBuilder!(
                          context,
                          widget.node,
                          widget.node.builtStyle,
                          () => widget.controller.toggleCollapseSelectedNodes(
                            !widget.node.state.isCollapsed,
                          ),
                        )
                      : _NodeHeaderWidget(
                          lodLevel: widget.controller.lodLevel,
                          nodeDisplayName: widget.node.prototype.displayName,
                          style: widget.node.builtHeaderStyle,
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

  void _updatePortsPosition() {
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
        port.prototype.direction == PortDirection.input
            ? 0
            : renderBoxSize.width,
        relativeY + portBox.size.height / 2,
      );
    }
  }
}

class _NodeHeaderWidget extends StatelessWidget {
  final int lodLevel;
  final FlNodeHeaderStyle style;
  final String nodeDisplayName;
  final VoidCallback onToggleCollapse;

  const _NodeHeaderWidget({
    required this.lodLevel,
    required this.style,
    required this.nodeDisplayName,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: style.padding,
      decoration: lodLevel <= 2
          ? style.decoration.copyWith(
              color: style.decoration.color?.withAlpha(255),
              borderRadius: BorderRadius.zero,
            )
          : style.decoration,
      child: Row(
        children: [
          Visibility(
            visible: lodLevel >= 3,
            maintainState: true,
            maintainSize: true,
            maintainAnimation: true,
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onToggleCollapse,
              child: Icon(style.icon, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              nodeDisplayName,
              style: style.textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
