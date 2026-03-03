import 'dart:async';

import 'package:fl_nodes_core/src/constants.dart';
import 'package:fl_nodes_core/src/core/controller/core.dart';
import 'package:fl_nodes_core/src/core/events/events.dart';
import 'package:fl_nodes_core/src/core/models/data.dart';
import 'package:fl_nodes_core/src/core/utils/rendering/renderbox.dart';
import 'package:fl_nodes_core/src/widgets/builders.dart';
import 'package:fl_nodes_core/src/widgets/improved_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

abstract class FlBaseNodeWidget extends StatefulWidget {
  final FlNodesController controller;
  final FlNodeDataModel node;

  final ShowPortContextMenu showPortContextMenu;
  final ShowNodeCreationtMenu showNodeCreationMenu;
  final ShowNodeContextMenu showNodeContextMenu;

  const FlBaseNodeWidget({
    super.key,
    required this.controller,
    required this.node,
    required this.showPortContextMenu,
    required this.showNodeCreationMenu,
    required this.showNodeContextMenu,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // dart format off
    properties
      ..add(DiagnosticsProperty<FlNodesController>('controller', controller))
      ..add(DiagnosticsProperty<FlNodeDataModel>('node', node))
      ..add(ObjectFlagProperty<ShowPortContextMenu>.has('showPortContextMenu', showPortContextMenu))
      ..add(ObjectFlagProperty<ShowNodeCreationtMenu>.has(
          'showNodeCreationMenu', showNodeCreationMenu))
      ..add(
          ObjectFlagProperty<ShowNodeContextMenu>.has('showNodeContextMenu', showNodeContextMenu));
    // dart format on
  }
}

abstract class FlBaseNodeWidgetState<T extends FlBaseNodeWidget> extends State<T> {
  // Interaction state for linking ports.
  bool _isLinking = false;

  // Timer for auto-scrolling when dragging near the edge.
  Timer? _edgeTimer;

  // The last known position of the pointer (GestureDetector).
  Offset? _lastPanPosition;

  // Temporary source port locator used during linking.
  PortLocator? _portLocator;

  late Color fakeTransparentColor;

  late List<FlPortDataModel> ports;
  late List<FlFieldDataModel> fields;

  double get viewportZoom => widget.controller.viewportZoom;
  Offset get viewportOffset => widget.controller.viewportOffset;
  GlobalKey get editorKey => widget.controller.editorKey;

  @override
  void initState() {
    super.initState();

    _updateStyleCache();
    _updatePortsAndFields();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      updatePortsPosition();
    });

    widget.controller.eventBus.events
        .where(
          (event) =>
              event is! FlViewportClassEvent &&
              event is! FlProjectClassEvent &&
              event is! FlTempInteractionClassEvent &&
              event is! FlClipboardClassEvent &&
              event is! FlRunnerClassEvent,
        )
        .listen(_handleControllerEvents);
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.node.key != widget.node.key) {
      _updateStyleCache();
      _updatePortsAndFields();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) updatePortsPosition();
      });
    }
  }

  void _handleControllerEvents(NodeEditorEvent event) {
    if (!mounted || event.isHandled) return;

    if (event is FlDragSelectionEvent) {
      if (!event.nodeIds.contains(widget.node.id)) return;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) updatePortsPosition();
      });
    } else if (event is FlNodeSelectionEvent) {
      if (event.nodeIds.contains(widget.node.id)) _updateStyleCache();
    } else if (event is FlNodeHoverEvent) {
      if (event.nodeId == widget.node.id) _updateStyleCache();
    } else if (event is FlCollapseNodeEvent) {
      if (!event.nodeIds.contains(widget.node.id)) return;

      _updateStyleCache();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) updatePortsPosition();
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

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) updatePortsPosition();
      });
    }
  }

  void _startEdgeTimer(Offset position) {
    const edgeThreshold = 50.0;
    final double moveAmount = 5.0 / widget.controller.viewportZoom;
    final Rect? editorBounds = RenderBoxUtils.getEditorBoundsInScreen(editorKey);
    if (editorBounds == null) return;

    _edgeTimer?.cancel();

    _edgeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      double dx = 0;
      double dy = 0;
      final Rect rect = editorBounds;

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
    final Offset? worldPosition = RenderBoxUtils.screenToWorld(
      editorKey,
      position,
      viewportOffset,
      viewportZoom,
    );

    final near = Rect.fromCenter(
      center: worldPosition!,
      width: kNodesSpatialHashingCellSize,
      height: kNodesSpatialHashingCellSize,
    );

    final Set<String> nearNodeIds = widget.controller.nodesSpatialHashGrid.queryArea(near);

    for (final nodeId in nearNodeIds) {
      final FlNodeDataModel node = widget.controller.getNodeById(nodeId)!;
      for (final FlPortDataModel port in node.ports.values) {
        final Offset absolutePortPosition = node.offset + port.offset;
        if ((worldPosition - absolutePortPosition).distance < kNearPortSnapDistance) {
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
    final Offset? worldPosition = RenderBoxUtils.screenToWorld(
      editorKey,
      position,
      viewportOffset,
      viewportZoom,
    );
    final FlNodeDataModel node = widget.controller.getNodeById(_portLocator!.nodeId)!;
    final FlPortDataModel port = node.ports[_portLocator!.portId]!;
    final Offset absolutePortOffset = node.offset + port.offset;

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

  Widget wrapWithControls(Widget child) =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (!widget.node.state.isSelected) {
                  widget.controller.selectNodesById({widget.node.id});
                }
              },
              onLongPressStart: (details) {
                final Offset position = details.globalPosition;
                final PortLocator? locator = _isNearPort(position);

                if (!widget.node.state.isSelected) {
                  widget.controller.selectNodesById(
                    {widget.node.id},
                    isSideEffect: true,
                  );
                }

                if (locator != null && !widget.node.state.isCollapsed) {
                  widget.showPortContextMenu(
                    context,
                    position,
                    widget.controller,
                    locator,
                  );
                } else {
                  widget.controller.selectNodesById({widget.node.id});
                  widget.showNodeContextMenu(
                    context,
                    position,
                    widget.controller,
                    widget.node,
                  );
                }
              },
              onPanDown: (details) {
                _lastPanPosition = details.globalPosition;
              },
              onPanStart: (details) {
                final Offset position = details.globalPosition;
                _isLinking = false;
                _portLocator = null;

                final PortLocator? locator = _isNearPort(position);
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
                  final PortLocator? locator = _isNearPort(_lastPanPosition!);
                  if (locator != null) {
                    _onTmpLinkEnd(locator);
                  } else {
                    widget.showNodeCreationMenu(
                      context,
                      _lastPanPosition!,
                      widget.controller,
                      locator,
                      _onTmpLinkCancel,
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
              onPointerPressed: (event) {
                _isLinking = false;
                _portLocator = null;

                final PortLocator? locator = _isNearPort(event.position);

                if (event.buttons == kSecondaryMouseButton) {
                  if (!widget.node.state.isSelected) {
                    widget.controller.selectNodesById(
                      {widget.node.id},
                      isSideEffect: true,
                    );
                  }

                  if (locator != null && !widget.node.state.isCollapsed) {
                    widget.showPortContextMenu(
                      context,
                      event.position,
                      widget.controller,
                      locator,
                    );
                  } else {
                    widget.showNodeContextMenu(
                      context,
                      event.position,
                      widget.controller,
                      widget.node,
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
              onPointerMoved: (event) {
                if (_isLinking) {
                  _onTmpLinkUpdate(event.position);
                } else if (event.buttons == kPrimaryMouseButton) {
                  _startEdgeTimer(event.position);
                  widget.controller.dragSelection(event.delta);
                }
              },
              onPointerReleased: (event) {
                if (_isLinking) {
                  final PortLocator? locator = _isNearPort(event.position);

                  if (locator != null) {
                    _onTmpLinkEnd(locator);
                  } else {
                    widget.showNodeCreationMenu(
                      context,
                      event.position,
                      widget.controller,
                      locator,
                      _onTmpLinkCancel,
                    );
                  }
                } else {
                  _resetEdgeTimer();
                }
              },
              child: child,
            );

  void _updateStyleCache() {
    setState(() {
      widget.node.builtStyle = widget.node.prototype.styleBuilder(widget.node.state);
      widget.node.builtHeaderStyle = widget.node.prototype.headerStyleBuilder(widget.node.state);

      fakeTransparentColor = Color.alphaBlend(
        widget.node.builtStyle.decoration.color!.withAlpha(255),
        widget.node.builtStyle.decoration.color!,
      );
    });
  }

  void _updatePortsAndFields() {
    setState(() {
      ports = widget.node.ports.values.toList();
      fields = widget.node.fields.values.toList();
    });
  }

  void updatePortsPosition();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fakeTransparentColor', fakeTransparentColor))
      ..add(IterableProperty<FlPortDataModel>('ports', ports))
      ..add(IterableProperty<FlFieldDataModel>('fields', fields))
      ..add(DoubleProperty('viewportZoom', viewportZoom))
      ..add(DiagnosticsProperty<Offset>('viewportOffset', viewportOffset))
      ..add(DiagnosticsProperty<GlobalKey<State<StatefulWidget>>>('editorKey', editorKey));
  }
}
