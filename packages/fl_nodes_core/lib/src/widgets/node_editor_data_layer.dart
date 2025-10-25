import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide Size;
import 'package:flutter_shaders/flutter_shaders.dart';

import '../constants.dart';
import '../core/controller/core.dart';
import '../core/events/events.dart';
import '../core/models/data.dart';
import '../core/utils/rendering/renderbox.dart';
import '../core/utils/widgets/context_menu.dart';
import '../styles/styles.dart';
import 'builders.dart';
import 'improved_listener.dart';
import 'node_editor_render_object.dart';

class NodeEditorDataLayer extends StatefulWidget {
  final FlNodesController controller;
  final bool expandToParent;
  final Size? fixedSize;
  final NodeBuilder nodeBuilder;
  final CanvasContextMenuBuilder canvasContextMenuBuilder;

  const NodeEditorDataLayer({
    super.key,
    required this.controller,
    required this.expandToParent,
    required this.fixedSize,
    required this.nodeBuilder,
    required this.canvasContextMenuBuilder,
  });

  @override
  State<NodeEditorDataLayer> createState() => _NodeEditorDataLayerState();
}

class _NodeEditorDataLayerState extends State<NodeEditorDataLayer>
    with TickerProviderStateMixin {
  // Wrapper state
  Offset get offset => widget.controller.viewportOffset;
  double get zoom => widget.controller.viewportZoom;
  FlNodesStyle get style => widget.controller.style;
  FlNodesConfig get config => widget.controller.config;
  GlobalKey get editorKey => widget.controller.editorKey;

  // Interaction state
  bool _isDragging = false;
  bool _isSelecting = false;
  bool _isLinking = false;

  // Interaction kinematics
  Offset _lastPositionDelta = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;
  Offset _kineticEnergy = Offset.zero;
  Timer? _kineticTimer;
  Offset _selectionStart = Offset.zero;
  PortLocator? _portLocator;

  // Gesture recognizers
  late final ScaleGestureRecognizer _trackpadGestureRecognizer;

  @override
  void initState() {
    super.initState();

    widget.controller.eventBus.events.listen(_handleControllerEvents);

    widget.controller.setTickerProvider(this);

    _trackpadGestureRecognizer = ScaleGestureRecognizer()
      ..onStart = ((details) => _onDragStart)
      ..onUpdate = _onScaleUpdate
      ..onEnd = ((details) => _onDragEnd);
  }

  @override
  void dispose() {
    _trackpadGestureRecognizer.dispose();
    super.dispose();
  }

  void _handleControllerEvents(NodeEditorEvent event) {
    if (!mounted || event.isHandled) return;

    if (event is FlDragSelectionEvent) {
      _suppressEvents();
    } else if (event is FlAddNodeEvent ||
        event is FlRemoveNodeEvent ||
        event is FlPasteSelectionEvent ||
        event is FlCutSelectionEvent ||
        event is FlLoadProjectEvent ||
        event is FlNewProjectEvent) {
      setState(() {});
    }
  }

  void _onDragStart() {
    _isDragging = true;
    _startKineticTimer();
  }

  void _onDragUpdate(Offset delta) {
    _lastPositionDelta = delta;
    _resetKineticTimer();
    _setOffsetFromRawInput(delta);
  }

  void _onDragCancel() => _onDragEnd();

  void _onDragEnd() {
    const weight = 25.0; // Weight for drag inertia (magic number)
    _isDragging = false;
    _kineticEnergy = _lastPositionDelta * weight;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      _setZoomFromRawInput(
        details.scale,
        details.focalPoint,
        isTrackpadInput: true,
      );
    } else if (details.focalPointDelta != Offset.zero) {
      _onDragUpdate(details.focalPointDelta);
    }
  }

  void _onHighlightStart(Offset position) {
    if (!widget.controller.config.enableAreaSelection) return;

    _isSelecting = true;
    _selectionStart = RenderBoxUtils.screenToWorld(
      editorKey,
      position,
      offset,
      zoom,
    )!;
  }

  void _onHighlightUpdate(Offset position) {
    widget.controller.setHighlightArea(
      Rect.fromPoints(
        _selectionStart,
        RenderBoxUtils.screenToWorld(
          editorKey,
          position,
          offset,
          zoom,
        )!,
      ),
    );
  }

  void _onHighlightCancel() {
    _isSelecting = false;
    _selectionStart = Offset.zero;
    widget.controller.setHighlightArea(null);
  }

  void _onHighlightEnd() {
    if (widget.controller.highlightArea == null) return;

    if (widget.controller.highlightArea!.size > const Size(10, 10)) {
      widget.controller.selectNodesByArea(
        holdSelection: HardwareKeyboard.instance.isControlPressed,
      );
    }

    widget.controller.setHighlightArea(null);

    _isSelecting = false;
    _selectionStart = Offset.zero;
  }

  PortLocator? _isNearPort(Offset position) {
    final worldPosition = RenderBoxUtils.screenToWorld(
      editorKey,
      position,
      offset,
      zoom,
    );

    final near = Rect.fromCenter(
      center: worldPosition!,
      width: kNodesSpatialHashingCellSize,
      height: kNodesSpatialHashingCellSize,
    );

    final nearNodeIds = widget.controller.nodesSpatialHashGrid.queryArea(near);

    for (final nodeId in nearNodeIds) {
      final node = widget.controller.nodes[nodeId]!;

      for (final port in node.ports.values) {
        final absolutePortPosition = node.offset + port.offset;

        if ((worldPosition - absolutePortPosition).distance <
            kNearPortSnapDistance) {
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
      offset,
      zoom,
    );

    final node = widget.controller.nodes[_portLocator!.nodeId]!;
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

  void _suppressEvents() {
    if (_isDragging) {
      _onDragCancel();
    } else if (_isLinking) {
      _onTmpLinkCancel();
    } else if (_isSelecting) {
      _onHighlightCancel();
    }
  }

  void _startKineticTimer() {
    // We try to squeeze out as much performance as possible
    if (widget.controller.nodes.length > 128) return;

    const duration = Duration(milliseconds: 16); // ~60 fps
    const friction = 0.88; // stronger stop
    const minVelocity = 0.5; // stop threshold in px/frame

    _kineticTimer?.cancel();

    _kineticTimer = Timer.periodic(duration, (timer) {
      if (_kineticEnergy == Offset.zero) {
        timer.cancel();
        return;
      }

      // Apply movement
      final Offset adjusted = _kineticEnergy / zoom;
      widget.controller.setViewportOffset(
        offset + adjusted,
        absolute: true,
      );

      // Apply friction decay
      _kineticEnergy *= friction;

      // Stop when velocity is very low
      if (_kineticEnergy.distance < minVelocity) {
        _kineticEnergy = Offset.zero;
        timer.cancel();
      }
    });
  }

  void _resetKineticTimer() {
    _kineticTimer?.cancel();
    _startKineticTimer();
  }

  void _setOffsetFromRawInput(Offset delta) {
    if (!widget.controller.config.enablePan) return;

    final Offset offsetFactor =
        delta * widget.controller.config.panSensitivity / zoom;

    final Offset targetOffset = offset + offsetFactor;

    // Never animate when setting offset from raw input
    widget.controller.setViewportOffset(
      targetOffset,
      absolute: true,
      animate: false,
    );
  }

  void _setZoomFromRawInput(
    double amount,
    Offset focalPoint, {
    bool isTrackpadInput = false,
  }) {
    if (!widget.controller.config.enableZoom) return;

    final double sensitivity = widget.controller.config.zoomSensitivity;
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    late double targetZoom;

    if (isMobile) {
      const platformWeight = 0.1;

      final double delta = defaultTargetPlatform == TargetPlatform.android
          ? -amount * platformWeight * sensitivity
          : amount * platformWeight * sensitivity;

      targetZoom = zoom * (1.0 + delta);
    } else {
      final double logZoom = log(zoom);
      late double delta;

      if (isTrackpadInput) {
        late double platformWeight;

        if (kIsWeb) {
          platformWeight = 3;
        } else {
          platformWeight = switch (defaultTargetPlatform) {
            TargetPlatform.macOS => 0.3,
            TargetPlatform.windows => 2.0,
            TargetPlatform.linux => 1.0,
            _ => 0.6
          };
        }

        delta = log(amount) * sensitivity * platformWeight;
      } else {
        const platformWeight = 0.01;

        delta = amount * platformWeight * sensitivity;
      }

      final double targetLogZoom =
          isTrackpadInput ? logZoom + delta : logZoom - delta;

      targetZoom = exp(targetLogZoom);
    }

    // Clamp zoom to reasonable bounds
    targetZoom = targetZoom.clamp(0.1, 10.0);

    if (isTrackpadInput && !kIsWeb) {
      widget.controller.setViewportZoom(
        targetZoom,
        absolute: true,
        animate: false,
      );

      return;
    }

    final localFocalPoint = RenderBoxUtils.screenToWorld(
      editorKey,
      focalPoint,
      offset,
      zoom,
    );

    widget.controller.setViewportZoom(
      targetZoom,
      absolute: true,
      animate: false,
    );

    final newLocalFocalPoint = RenderBoxUtils.screenToWorld(
      editorKey,
      focalPoint,
      widget.controller.viewportOffset,
      widget.controller.viewportZoom,
    );

    final focalPointOffsetDelta = newLocalFocalPoint! - localFocalPoint!;

    widget.controller.setViewportOffset(
      widget.controller.viewportOffset + focalPointOffsetDelta,
      absolute: true,
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget controlsWrapper(Widget child) {
      return defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS
          ? GestureDetector(
              onTap: () => widget.controller.clearSelection(),
              onLongPressStart: (LongPressStartDetails details) {
                final position = details.globalPosition;
                final locator = _isNearPort(position);

                if (locator != null &&
                    !widget
                        .controller.nodes[locator.nodeId]!.state.isCollapsed) {
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
                  ContextMenuUtils.createAndShowContextMenu(
                    context,
                    entries: widget.canvasContextMenuBuilder(
                      position,
                      context: context,
                      controller: widget.controller,
                      locator: locator,
                    ),
                    position: position,
                  );
                }
              },
              onScaleStart: (ScaleStartDetails details) {
                _lastFocalPoint = details.focalPoint;

                final locator = _isNearPort(details.focalPoint);

                if (locator != null && _portLocator == null) {
                  _isLinking = true;
                  _onTmpLinkStart(locator);
                } else {
                  _isSelecting = true;
                  _onHighlightStart(details.focalPoint);
                }
              },
              onScaleUpdate: (ScaleUpdateDetails details) {
                _lastFocalPoint = details.focalPoint;

                if (details.scale != 1.0) {
                  if (!_isDragging) {
                    if (_isLinking) {
                      _onTmpLinkCancel();
                      _isLinking = false;
                    } else if (_isSelecting) {
                      _onHighlightEnd();
                      _isSelecting = false;
                    } else {
                      _isDragging = true;
                      _onDragStart();
                    }
                  }

                  if (widget.controller.config.enablePan && _isDragging) {
                    _onDragUpdate(details.focalPointDelta);
                  }
                  if (widget.controller.config.enableZoom &&
                          details.scale > 1.5 ||
                      details.scale < 0.5) {
                    _setZoomFromRawInput(
                      details.scale < 1 ? details.scale : -details.scale,
                      details.focalPoint,
                    );
                  }
                } else {
                  if (_isLinking) {
                    _onTmpLinkUpdate(details.focalPoint);
                  } else if (_isSelecting) {
                    _onHighlightUpdate(details.focalPoint);
                  }
                }
              },
              onScaleEnd: (ScaleEndDetails details) {
                if (_isDragging) {
                  _onDragEnd();
                  _isDragging = false;
                } else if (_isLinking) {
                  final locator = _isNearPort(_lastFocalPoint);

                  if (locator != null) {
                    _onTmpLinkEnd(locator);
                  } else if (!isContextMenuVisible) {
                    ContextMenuUtils.createAndShowContextMenu(
                      context,
                      entries: ContextMenuUtils.nodeCreationMenuEntries(
                        _lastFocalPoint,
                        context: context,
                        controller: widget.controller,
                        locator: _portLocator,
                      ),
                      position: _lastFocalPoint,
                      onDismiss: (value) => _onTmpLinkCancel(),
                    );
                  }

                  _isLinking = false;
                } else if (_isSelecting) {
                  _onHighlightEnd();
                  _isSelecting = false;
                }
              },
              child: child,
            )
          : Focus(
              autofocus: true,
              child: ImprovedListener(
                onDoubleClick: () => widget.controller.clearSelection(),
                onPointerPressed: (event) {
                  _isLinking = false;
                  _portLocator = null;
                  _isSelecting = false;

                  final locator = _isNearPort(event.position);

                  if (event.buttons == kMiddleMouseButton) {
                    _onDragStart();
                  } else if (event.buttons == kPrimaryMouseButton) {
                    if (locator != null &&
                        !_isLinking &&
                        _portLocator == null) {
                      _onTmpLinkStart(locator);
                    } else {
                      _onHighlightStart(event.position);
                    }
                  } else if (event.buttons == kSecondaryMouseButton) {
                    if (locator != null &&
                        !widget.controller.nodes[locator.nodeId]!.state
                            .isCollapsed) {
                      /// If a port is near the cursor, show the port context menu
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
                      // Else show the editor context menu
                      ContextMenuUtils.createAndShowContextMenu(
                        context,
                        entries: widget.canvasContextMenuBuilder(
                          event.position,
                          context: context,
                          controller: widget.controller,
                          locator: locator,
                        ),
                        position: event.position,
                      );
                    }
                  }
                },
                onPointerMoved: (event) {
                  if (_isDragging && widget.controller.config.enablePan) {
                    _onDragUpdate(event.localDelta);
                  } else if (_isLinking) {
                    _onTmpLinkUpdate(event.position);
                  } else if (_isSelecting) {
                    _onHighlightUpdate(event.position);
                  }
                },
                onPointerReleased: (event) {
                  if (_isDragging) {
                    _onDragEnd();
                  } else if (_isLinking) {
                    final locator = _isNearPort(event.position);

                    if (locator != null) {
                      _onTmpLinkEnd(locator);
                    } else if (!isContextMenuVisible) {
                      // Show the create submenu if no port is near the cursor
                      ContextMenuUtils.createAndShowContextMenu(
                        context,
                        entries: ContextMenuUtils.nodeCreationMenuEntries(
                          event.position,
                          context: context,
                          controller: widget.controller,
                          locator: _portLocator,
                        ),
                        position: event.position,
                        onDismiss: (value) => _onTmpLinkCancel(),
                      );
                    }
                  } else if (_isSelecting) {
                    _onHighlightEnd();
                  }
                },
                onPointerSignalReceived: (event) {
                  if (event is PointerScrollEvent &&
                      widget.controller.config.enablePan) {
                    if (kIsWeb) {
                      final isZoomModifier =
                          HardwareKeyboard.instance.isControlPressed ||
                              HardwareKeyboard.instance.isMetaPressed;

                      if (isZoomModifier &&
                          widget.controller.config.enableZoom) {
                        _setZoomFromRawInput(
                          event.scrollDelta.dy,
                          event.position,
                        );
                      } else {
                        _setOffsetFromRawInput(-event.scrollDelta);
                      }
                    } else {
                      if (widget.controller.config.enableZoom) {
                        _setZoomFromRawInput(
                          event.scrollDelta.dy,
                          event.position,
                        );
                      }
                    }
                  }
                  if (event is PointerScaleEvent &&
                      widget.controller.config.enableZoom) {
                    if (kIsWeb) {
                      _setZoomFromRawInput(
                        event.scale,
                        event.position,
                        isTrackpadInput: true,
                      );
                    }
                  }
                },
                onPointerPanZoomStart:
                    _trackpadGestureRecognizer.addPointerPanZoom,
                child: child,
              ),
            );
    }

    widget.controller.setLocale(Localizations.localeOf(context));

    return controlsWrapper(
      RepaintBoundary(
        child: ShaderBuilder(
          assetKey: 'packages/fl_nodes_core/shaders/grid.frag',
          (context, gridShader, child) => NodeEditorRenderObjectWidget(
            key: editorKey,
            controller: widget.controller,
            gridShader: gridShader,
            showLinkContextMenu: (linkId, position) {
              if (!isContextMenuVisible) {
                ContextMenuUtils.createAndShowContextMenu(
                  context,
                  entries: ContextMenuUtils.linkContextMenuEntries(
                    position,
                    context: context,
                    controller: widget.controller,
                    linkId: linkId,
                  ),
                  position: position,
                );
              }
            },
            nodeBuilder: widget.nodeBuilder,
          ),
        ),
      ),
    );
  }
}
