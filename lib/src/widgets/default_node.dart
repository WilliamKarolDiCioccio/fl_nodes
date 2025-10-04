import 'dart:async';

import 'package:fl_nodes/src/core/controller/core.dart';
import 'package:fl_nodes/src/core/events/events.dart';
import 'package:fl_nodes/src/core/utils/rendering/renderbox.dart';
import 'package:fl_nodes/src/core/utils/widgets/context_menu.dart';
import 'package:fl_nodes/src/widgets/improved_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../core/models/data.dart';
import 'builders.dart';

/// The main NodeWidget which represents a node in the editor.
/// It now ensures that fields (regardless of whether a custom fieldBuilder is used)
/// still respond to tap events in the same way as before.
class DefaultNodeWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final FlNodeDataModel node;
  final NodeHeaderBuilder? headerBuilder;
  final NodeFieldBuilder? fieldBuilder;
  final NodePortBuilder? portBuilder;
  final NodeContextMenuBuilder? contextMenuBuilder;
  final NodeBuilder? nodeBuilder;

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

  // Temporary source port locator used during linking.
  PortLocator? _portLocator;

  late Color fakeTransparentColor;

  late List<FlPortDataModel> inPorts;
  late List<FlPortDataModel> outPorts;
  late List<FlFieldDataModel> fields;

  double get viewportZoom => widget.controller.viewportZoom;
  Offset get viewportOffset => widget.controller.viewportOffset;
  GlobalKey get editorKey => widget.controller.editorKey;

  @override
  void initState() {
    super.initState();

    _updateStyleCache();
    _updatePortsAndFields();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _updatePortsPosition();
    });

    widget.controller.eventBus.events.listen(_handleControllerEvents);
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(DefaultNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.node.key != widget.node.key) {
      _updateStyleCache();
      _updatePortsAndFields();

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) _updatePortsPosition();
      });
    }
  }

  void _handleControllerEvents(NodeEditorEvent event) {
    if (!mounted || event.isHandled) return;

    if (event is FlDragSelectionEvent) {
      if (!event.nodeIds.contains(widget.node.id)) return;

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) _updatePortsPosition();
      });
    } else if (event is FlNodeSelectionEvent) {
      if (event.nodeIds.contains(widget.node.id)) _updateStyleCache();
    } else if (event is FlNodeHoverEvent) {
      if (event.nodeId == widget.node.id) _updateStyleCache();
    } else if (event is FlCollapseNodeEvent) {
      if (!event.nodeIds.contains(widget.node.id)) return;

      _updateStyleCache();

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) _updatePortsPosition();
      });
    } else if (event is FlNodeFieldEvent) {
      if (event.nodeId == widget.node.id &&
          (event.eventType == FlFieldEventType.submit ||
              event.eventType == FlFieldEventType.cancel)) {
        setState(() {});
      }
    } else if (event is FlAddNodeEvent) {
      if (event.node.id == widget.node.id) setState(() {});
    } else if (event is FlConfigurationChangeEvent ||
        event is FlStyleChangeEvent ||
        event is FlLocaleChangeEvent) {
      _updatePortsAndFields();
      _updateStyleCache();

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) _updatePortsPosition();
      });
    }
  }

  void _startEdgeTimer(Offset position) {
    const edgeThreshold = 50.0;
    final moveAmount = 5.0 / widget.controller.viewportZoom;
    final editorBounds = RenderBoxUtils.getEditorBoundsInScreen(editorKey);
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

  PortLocator? _isNearPort(Offset position) {
    final worldPosition = RenderBoxUtils.screenToWorld(
      editorKey,
      position,
      viewportOffset,
      viewportZoom,
    );

    final near = Rect.fromCenter(
      center: worldPosition!,
      width: kSpatialHashingCellSize,
      height: kSpatialHashingCellSize,
    );

    final nearNodeIds = widget.controller.nodesSpatialHashGrid.queryArea(near);

    for (final nodeId in nearNodeIds) {
      final node = widget.controller.getNodeById(nodeId)!;
      for (final port in node.ports.values) {
        final absolutePortPosition = node.offset + port.offset;
        if ((worldPosition - absolutePortPosition).distance < 4) {
          return (nodeId: node.id, portId: port.prototype.idName);
        }
      }
    }

    return null;
  }

  void _onTmpLinkStart(PortLocator locator) {
    _portLocator = (nodeId: locator.nodeId, portId: locator.portId);
    _isLinking = true;
  }

  void _onTmpLinkUpdate(Offset position) {
    final worldPosition = RenderBoxUtils.screenToWorld(
      editorKey,
      position,
      viewportOffset,
      viewportZoom,
    );
    final node = widget.controller.getNodeById(_portLocator!.nodeId)!;
    final port = node.ports[_portLocator!.portId]!;
    final absolutePortOffset = node.offset + port.offset;

    widget.controller.drawTempLink(
      port.style.linkStyleBuilder(FlLinkState()),
      absolutePortOffset,
      worldPosition!,
    );
  }

  void _onTmpLinkCancel() {
    _isLinking = false;
    _portLocator = null;
    widget.controller.clearTempLink();
  }

  void _onTmpLinkEnd(PortLocator locator) {
    widget.controller.addLink(
      _portLocator!.nodeId,
      _portLocator!.portId,
      locator.nodeId,
      locator.portId,
    );
    _isLinking = false;
    _portLocator = null;
    widget.controller.clearTempLink();
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
                ContextMenuUtils.createAndShowContextMenu(
                  context,
                  entries: ContextMenuUtils.portContextMenuEntries(
                    position,
                    context: context,
                    controller: widget.controller,
                    locator: locator,
                  ),
                  position: position,
                );
              } else if (!isContextMenuVisible) {
                widget.controller.selectNodesById({widget.node.id});

                final entries = widget.contextMenuBuilder != null
                    ? widget.contextMenuBuilder!(
                        context,
                        widget.controller,
                        widget.node,
                      )
                    : ContextMenuUtils.nodeMenuEntries(
                        context,
                        widget.controller,
                        widget.node,
                      );

                ContextMenuUtils.createAndShowContextMenu(
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
              _portLocator = null;

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
                  ContextMenuUtils.createAndShowContextMenu(
                    context,
                    entries: ContextMenuUtils.nodeCreationMenuEntries(
                      _lastPanPosition!,
                      context: context,
                      controller: widget.controller,
                      locator: locator,
                    ),
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
              _portLocator = null;

              final locator = _isNearPort(event.position);

              if (event.buttons == kSecondaryMouseButton) {
                if (!widget.node.state.isSelected) {
                  widget.controller.selectNodesById({widget.node.id});
                }

                if (locator != null && !widget.node.state.isCollapsed) {
                  ContextMenuUtils.createAndShowContextMenu(
                    context,
                    entries: ContextMenuUtils.portContextMenuEntries(
                      event.position,
                      context: context,
                      controller: widget.controller,
                      locator: locator,
                    ),
                    position: event.position,
                  );
                } else if (!isContextMenuVisible) {
                  final entries = widget.contextMenuBuilder != null
                      ? widget.contextMenuBuilder!(
                          context,
                          widget.controller,
                          widget.node,
                        )
                      : ContextMenuUtils.nodeMenuEntries(
                          context,
                          widget.controller,
                          widget.node,
                        );

                  ContextMenuUtils.createAndShowContextMenu(
                    context,
                    entries: entries,
                    position: event.position,
                  );
                }
              } else if (event.buttons == kPrimaryMouseButton) {
                if (locator != null && !_isLinking && _portLocator == null) {
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
                  ContextMenuUtils.createAndShowContextMenu(
                    context,
                    entries: ContextMenuUtils.nodeCreationMenuEntries(
                      event.position,
                      context: context,
                      controller: widget.controller,
                      locator: locator,
                    ),
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
                decoration: widget.node.builtStyle.decoration,
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
                                          portBuilder: widget.portBuilder,
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
                                          portBuilder: widget.portBuilder,
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
                              fieldBuilder: widget.fieldBuilder,
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

  void _updateStyleCache() {
    setState(() {
      widget.node.builtStyle =
          widget.node.prototype.styleBuilder(widget.node.state);
      widget.node.builtHeaderStyle =
          widget.node.prototype.headerStyleBuilder(widget.node.state);

      fakeTransparentColor = Color.alphaBlend(
        widget.node.builtStyle.decoration.color!.withAlpha(255),
        widget.node.builtStyle.decoration.color!,
      );
    });
  }

  void _updatePortsAndFields() {
    setState(() {
      inPorts = widget.node.ports.values
          .where((port) => port.prototype.direction == FlPortDirection.input)
          .toList();
      outPorts = widget.node.ports.values
          .where((port) => port.prototype.direction == FlPortDirection.output)
          .toList();

      fields = widget.node.fields.values.toList();
    });
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
        port.prototype.direction == FlPortDirection.input
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
  final NodePortBuilder? portBuilder;

  const _PortWidget({
    required this.node,
    required this.port,
    this.portBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (node.state.isCollapsed) {
      return SizedBox(key: port.key, height: 0, width: 0);
    }

    if (portBuilder != null) {
      return portBuilder!(context, port, node.builtStyle);
    }

    final isInput = port.prototype.direction == FlPortDirection.input;

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
  final NodeFieldBuilder? fieldBuilder;

  const _FieldWidget({
    required this.controller,
    required this.node,
    required this.field,
    this.fieldBuilder,
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
    final fieldContent = fieldBuilder != null
        ? fieldBuilder!(context, field, node.builtStyle)
        : Container(
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
          );

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
        child: fieldContent,
      ),
    );
  }
}
