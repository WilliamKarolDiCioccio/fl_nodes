import 'dart:async';
import 'dart:math';

import 'package:fl_nodes/src/core/localization/delegate.dart';
import 'package:fl_nodes/src/core/models/config.dart';
import 'package:fl_nodes/src/core/utils/rendering/renderbox.dart';
import 'package:fl_nodes/src/widgets/context_menu.dart';
import 'package:fl_nodes/src/widgets/improved_listener.dart';
import 'package:fl_nodes/src/widgets/node_editor_render_object.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import '../constants.dart';
import '../core/controller/core.dart';
import '../core/models/entities.dart';
import '../core/models/events.dart';
import '../core/models/styles.dart';
import 'builders.dart';

class FlOverlayData {
  final Widget child;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;

  FlOverlayData({
    required this.child,
    this.top,
    this.left,
    this.bottom,
    this.right,
  });
}

class NodeEditorDataLayer extends StatefulWidget {
  final FlNodeEditorController controller;
  final bool expandToParent;
  final Size? fixedSize;
  final List<FlOverlayData> Function() overlay;
  final NodeHeaderBuilder? headerBuilder;
  final NodeFieldBuilder? fieldBuilder;
  final NodePortBuilder? portBuilder;
  final NodeContextMenuBuilder? contextMenuBuilder;
  final NodeBuilder? nodeBuilder;

  const NodeEditorDataLayer({
    super.key,
    required this.controller,
    required this.expandToParent,
    required this.fixedSize,
    required this.overlay,
    this.headerBuilder,
    this.fieldBuilder,
    this.portBuilder,
    this.contextMenuBuilder,
    this.nodeBuilder,
  });

  @override
  State<NodeEditorDataLayer> createState() => _NodeEditorDataLayerState();
}

typedef _TempLink = ({String nodeId, String portId});

class _NodeEditorDataLayerState extends State<NodeEditorDataLayer>
    with TickerProviderStateMixin {
  // Wrapper state
  Offset get offset => widget.controller.viewportOffset;
  double get zoom => widget.controller.viewportZoom;
  FlNodeEditorStyle get style => widget.controller.style;
  FlNodeEditorConfig get config => widget.controller.config;

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
  _TempLink? _tempLink;

  // Animation controllers and animations
  late final AnimationController _offsetAnimationController;
  late final AnimationController _zoomAnimationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _zoomAnimation;

  // Gesture recognizers
  late final ScaleGestureRecognizer _trackpadGestureRecognizer;

  @override
  void initState() {
    super.initState();

    widget.controller.eventBus.events.listen(_handleControllerEvents);

    _offsetAnimationController = AnimationController(vsync: this);
    _zoomAnimationController = AnimationController(vsync: this);
    _trackpadGestureRecognizer = ScaleGestureRecognizer()
      ..onStart = ((details) => _onDragStart)
      ..onUpdate = _onScaleUpdate
      ..onEnd = ((details) => _onDragEnd);
  }

  @override
  void dispose() {
    _offsetAnimationController.dispose();
    _zoomAnimationController.dispose();
    _trackpadGestureRecognizer.dispose();
    super.dispose();
  }

  void _handleControllerEvents(NodeEditorEvent event) {
    if (!mounted || event.isHandled) return;

    if (event is FlViewportOffsetEvent) {
      _setOffset(event.offset, animate: event.animate);
    } else if (event is FlViewportZoomEvent) {
      _setZoom(event.zoom, animate: event.animate);
    } else if (event is FlDragSelectionEvent) {
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
    _offsetAnimationController.stop();
    _startKineticTimer();
  }

  void _onDragUpdate(Offset delta) {
    _lastPositionDelta = delta;
    _resetKineticTimer();
    _setOffsetFromRawInput(delta);
  }

  void _onDragCancel() => _onDragEnd();

  void _onDragEnd() {
    _isDragging = false;
    _kineticEnergy = _lastPositionDelta;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      _setZoomFromRawInput(
        details.scale,
        details.focalPoint,
        isTrackpadInput: true,
      );
    } else if (details.focalPointDelta != const Offset(10, 10)) {
      _onDragUpdate(details.focalPointDelta);
    }
  }

  void _onHighlightStart(Offset position) {
    if (!widget.controller.config.enableAreaSelection) return;

    _isSelecting = true;
    _selectionStart = screenToWorld(
      position,
      offset,
      zoom,
    )!;
  }

  void _onHighlightUpdate(Offset position) {
    widget.controller.setHighlightArea(
      Rect.fromPoints(
        _selectionStart,
        screenToWorld(
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

  _TempLink? _isNearPort(Offset position) {
    final worldPosition = screenToWorld(
      position,
      offset,
      zoom,
    );

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
    final worldPosition = screenToWorld(
      position,
      offset,
      zoom,
    );

    final node = widget.controller.nodes[_tempLink!.nodeId]!;
    final port = node.ports[_tempLink!.portId]!;

    final absolutePortOffset = node.offset + port.offset;

    widget.controller.drawTempLink(
      port.style.linkStyleBuilder(FlLinkState()),
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

  void _suppressEvents() {
    if (_isDragging) {
      _onDragCancel();
    } else if (_isLinking) {
      _onLinkCancel();
    } else if (_isSelecting) {
      _onHighlightCancel();
    }
  }

  void _startKineticTimer() {
    const duration = Duration(milliseconds: 16); // ~60 FPS
    const decayFactor = 0.9; // Exponential decay factor (magic number)
    const minEnergyThreshold = 0.1; // Stop motion threshold (magic number)

    _kineticTimer?.cancel();

    _kineticTimer = Timer.periodic(duration, (timer) {
      if (_lastPositionDelta == Offset.zero) {
        timer.cancel();
        return;
      }

      final Offset adjustedKineticEnergy = _kineticEnergy / zoom;

      _setOffset(offset + adjustedKineticEnergy);

      _kineticEnergy *= decayFactor;

      if (_kineticEnergy.distance < minEnergyThreshold) {
        timer.cancel();
        _kineticEnergy = Offset.zero;
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
    _setOffset(targetOffset);
  }

  void _setOffset(Offset targetOffset, {bool animate = false}) {
    if (offset == targetOffset) return;

    final beginOffset = offset;

    final Offset endOffset = Offset(
      targetOffset.dx.clamp(
        -widget.controller.config.maxPanX,
        widget.controller.config.maxPanX,
      ),
      targetOffset.dy.clamp(
        -widget.controller.config.maxPanY,
        widget.controller.config.maxPanY,
      ),
    );

    if (animate) {
      _offsetAnimationController.reset();

      final distance = (offset - endOffset).distance;
      final durationFactor = (distance / 1000).clamp(0.5, 3.0);
      _offsetAnimationController.duration = Duration(
        milliseconds: (1000 * durationFactor).toInt(),
      );

      _offsetAnimation = Tween<Offset>(
        begin: beginOffset,
        end: endOffset,
      ).animate(
        CurvedAnimation(
          parent: _offsetAnimationController,
          curve: Curves.easeOut,
        ),
      )..addListener(() {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            widget.controller.updateViewportOffsetFromUI(
              _offsetAnimation.value,
            );
          });
        });

      _offsetAnimationController.forward();
    } else {
      widget.controller.updateViewportOffsetFromUI(
        endOffset,
      );
    }
  }

  void _setZoomFromRawInput(
    double amount,
    Offset focalPoint, {
    bool isTrackpadInput = false,
  }) {
    if (!widget.controller.config.enableZoom) return;

    const double zoomSpeed = 0.1;
    final double sensitivity = widget.controller.config.zoomSensitivity;

    late double targetZoom;

    // Check if we're on a mobile platform
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    // Mobile: simple linear/multiplicative scaling - no logarithms
    if (isMobile) {
      final double delta = defaultTargetPlatform == TargetPlatform.android
          ? -amount * zoomSpeed * sensitivity // Flip for Android
          : amount * zoomSpeed * sensitivity; // Keep as-is for iOS
      targetZoom = zoom * (1.0 + delta);
    }
    // Desktop: use logarithmic scaling for smooth trackpad/mouse wheel input
    else {
      final double logZoom = log(zoom);
      late double delta;

      if (isTrackpadInput) {
        final double weight = switch (defaultTargetPlatform) {
          TargetPlatform.macOS => 1.0,
          TargetPlatform.windows => 10.0,
          TargetPlatform.linux => 5.0,
          _ => 1.0
        };
        delta = log(amount) * sensitivity * weight;
      } else {
        delta = amount * zoomSpeed * sensitivity;
      }

      final double targetLogZoom =
          isTrackpadInput ? logZoom + delta : logZoom - delta;
      targetZoom = exp(targetLogZoom);
    }

    _setZoom(
      targetZoom,
      animate: !isMobile && defaultTargetPlatform != TargetPlatform.macOS,
    );
  }

  void _setZoom(double targetZoom, {bool animate = false}) {
    if (zoom == targetZoom) return;

    final beginZoom = zoom;

    final endZoom = targetZoom.clamp(
      widget.controller.config.minZoom,
      widget.controller.config.maxZoom,
    );

    if (animate) {
      _zoomAnimationController.reset();

      _zoomAnimationController.duration = const Duration(milliseconds: 200);

      _zoomAnimation = Tween<double>(
        begin: beginZoom,
        end: endZoom,
      ).animate(
        CurvedAnimation(
          parent: _zoomAnimationController,
          curve: Curves.easeOut,
        ),
      )..addListener(() {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            widget.controller.updateViewportZoomFromUI(
              _zoomAnimation.value,
            );
          });
        });

      _zoomAnimationController.forward();
    } else {
      widget.controller.updateViewportZoomFromUI(
        endZoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ContextMenuEntry> createSubmenuEntries(Offset position) {
      final fromLink = _tempLink != null;

      final List<MapEntry<String, FlNodePrototype>> compatiblePrototypes = [];

      if (fromLink) {
        final startPort = widget
            .controller.nodes[_tempLink!.nodeId]!.ports[_tempLink!.portId]!;

        widget.controller.nodePrototypes.forEach(
          (key, value) {
            if (value.ports.any(
              startPort.prototype.compatibleWith,
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
        offset,
        zoom,
      );

      return compatiblePrototypes.map((entry) {
        return MenuItem(
          label: entry.value.displayName(context),
          icon: Icons.widgets,
          onSelected: () {
            widget.controller.addNode(
              entry.key,
              offset: worldPosition ?? Offset.zero,
            );

            if (fromLink) {
              final addedNode = widget.controller.nodes.values.last;
              final startPort = widget.controller.nodes[_tempLink!.nodeId]!
                  .ports[_tempLink!.portId]!;

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
            }
          },
        );
      }).toList();
    }

    List<ContextMenuEntry> editorContextMenuEntries(Offset position) {
      final worldPosition = screenToWorld(
        position,
        offset,
        zoom,
      )!;
      final strings = FlNodeEditorLocalizations.of(context);

      return [
        MenuHeader(text: strings.editorMenuLabel),
        MenuItem(
          label: strings.centerViewAction,
          icon: Icons.center_focus_strong,
          onSelected: () => widget.controller.setViewportOffset(
            Offset.zero,
            absolute: true,
          ),
        ),
        MenuItem(
          label: strings.resetZoomAction,
          icon: Icons.zoom_in,
          onSelected: () => widget.controller.setViewportZoom(1.0),
        ),
        const MenuDivider(),
        MenuItem.submenu(
          label: strings.createNodeAction,
          icon: Icons.add,
          items: createSubmenuEntries(position),
        ),
        MenuItem(
          label: strings.pasteSelectionAction,
          icon: Icons.paste,
          onSelected: () => widget.controller.clipboard
              .pasteSelection(position: worldPosition),
        ),
        const MenuDivider(),
        MenuItem.submenu(
          label: strings.projectLabel,
          icon: Icons.folder,
          items: [
            MenuItem(
              label: strings.undoAction,
              icon: Icons.undo,
              onSelected: () => widget.controller.history.undo(),
            ),
            MenuItem(
              label: strings.redoAction,
              icon: Icons.redo,
              onSelected: () => widget.controller.history.redo(),
            ),
            MenuItem(
              label: strings.saveProjectAction,
              icon: Icons.save,
              onSelected: () =>
                  widget.controller.project.save(context: context),
            ),
            MenuItem(
              label: strings.openProjectAction,
              icon: Icons.folder_open,
              onSelected: () =>
                  widget.controller.project.load(context: context),
            ),
            MenuItem(
              label: strings.newProjectAction,
              icon: Icons.new_label,
              onSelected: () =>
                  widget.controller.project.create(context: context),
            ),
          ],
        ),
      ];
    }

    List<ContextMenuEntry> portContextMenuEntries(
      Offset position, {
      required _TempLink locator,
    }) {
      final strings = FlNodeEditorLocalizations.of(context);

      return [
        MenuHeader(text: strings.portMenuLabel),
        MenuItem(
          label: strings.cutLinksAction,
          icon: Icons.remove_circle,
          onSelected: () {
            widget.controller.breakPortLinks(
              locator.nodeId,
              locator.portId,
            );
          },
        ),
      ];
    }

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
                  createAndShowContextMenu(
                    context,
                    entries: portContextMenuEntries(position, locator: locator),
                    position: position,
                  );
                } else if (!isContextMenuVisible) {
                  createAndShowContextMenu(
                    context,
                    entries: editorContextMenuEntries(position),
                    position: position,
                  );
                }
              },
              onScaleStart: (ScaleStartDetails details) {
                _lastFocalPoint = details.focalPoint;

                final locator = _isNearPort(details.focalPoint);

                if (locator != null && _tempLink == null) {
                  _isLinking = true;
                  _onLinkStart(locator);
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
                      _onLinkCancel();
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
                          details.scale > 1.25 ||
                      details.scale < 0.75) {
                    _setZoomFromRawInput(
                      details.scale < 1 ? details.scale : -details.scale,
                      details.focalPoint,
                    );
                  }
                } else {
                  if (_isLinking) {
                    _onLinkUpdate(details.focalPoint);
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
                    _onLinkEnd(locator);
                  } else if (!isContextMenuVisible) {
                    createAndShowContextMenu(
                      context,
                      entries: createSubmenuEntries(_lastFocalPoint),
                      position: _lastFocalPoint,
                      onDismiss: (value) => _onLinkCancel(),
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
          : CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.delete): () {
                  for (final nodeId in widget.controller.selectedNodeIds) {
                    widget.controller.removeNodeById(
                      nodeId,
                      isHandled:
                          nodeId != widget.controller.selectedNodeIds.last,
                    );
                  }
                  for (final link in widget.controller.selectedLinkIds) {
                    widget.controller.removeLinkById(link);
                  }
                  widget.controller.clearSelection();
                },
                const SingleActivator(LogicalKeyboardKey.backspace): () {
                  for (final nodeId in widget.controller.selectedNodeIds) {
                    widget.controller.removeNodeById(
                      nodeId,
                      isHandled:
                          nodeId != widget.controller.selectedNodeIds.last,
                    );
                  }
                  for (final link in widget.controller.selectedLinkIds) {
                    widget.controller.removeLinkById(link);
                  }
                  widget.controller.clearSelection();
                },
                const SingleActivator(LogicalKeyboardKey.keyC, control: true):
                    () => widget.controller.clipboard
                        .copySelection(context: context),
                const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                    () => widget.controller.clipboard
                        .pasteSelection(context: context),
                const SingleActivator(LogicalKeyboardKey.keyX, control: true):
                    () => widget.controller.clipboard
                        .cutSelection(context: context),
                const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                    () => widget.controller.project.save(context: context),
                const SingleActivator(LogicalKeyboardKey.keyO, control: true):
                    () => widget.controller.project.load(context: context),
                SingleActivator(
                  LogicalKeyboardKey.keyN,
                  control: defaultTargetPlatform != TargetPlatform.macOS,
                  meta: defaultTargetPlatform == TargetPlatform.macOS,
                  shift: true,
                ): () => widget.controller.project.create(context: context),
                const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                    () => widget.controller.history.undo(),
                const SingleActivator(LogicalKeyboardKey.keyY, control: true):
                    () => widget.controller.history.redo(),
              },
              child: Focus(
                autofocus: true,
                child: ImprovedListener(
                  onDoubleClick: () => widget.controller.clearSelection(),
                  onPointerPressed: (event) {
                    _isLinking = false;
                    _tempLink = null;
                    _isSelecting = false;

                    final locator = _isNearPort(event.position);

                    if (event.buttons == kMiddleMouseButton) {
                      _onDragStart();
                    } else if (event.buttons == kPrimaryMouseButton) {
                      if (locator != null && !_isLinking && _tempLink == null) {
                        _onLinkStart(locator);
                      } else {
                        _onHighlightStart(event.position);
                      }
                    } else if (event.buttons == kSecondaryMouseButton) {
                      if (locator != null &&
                          !widget.controller.nodes[locator.nodeId]!.state
                              .isCollapsed) {
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
                        // Else show the editor context menu
                        createAndShowContextMenu(
                          context,
                          entries: editorContextMenuEntries(event.position),
                          position: event.position,
                        );
                      }
                    }
                  },
                  onPointerMoved: (event) {
                    if (_isDragging && widget.controller.config.enablePan) {
                      _onDragUpdate(event.localDelta);
                    } else if (_isLinking) {
                      _onLinkUpdate(event.position);
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
                        _onLinkEnd(locator);
                      } else if (!isContextMenuVisible) {
                        // Show the create submenu if no port is near the cursor
                        createAndShowContextMenu(
                          context,
                          entries: createSubmenuEntries(event.position),
                          position: event.position,
                          onDismiss: (value) => _onLinkCancel(),
                        );
                      }
                    } else if (_isSelecting) {
                      _onHighlightEnd();
                    }
                  },
                  onPointerSignalReceived: (event) {
                    if (event is PointerScrollEvent &&
                        widget.controller.config.enablePan &&
                        event.scrollDelta != const Offset(10, 10)) {
                      _setZoomFromRawInput(
                        event.scrollDelta.dy,
                        event.position,
                      );
                    }
                    if (event is PointerScaleEvent) {
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
              ),
            );
    }

    widget.controller.setLocale(Localizations.localeOf(context));

    return controlsWrapper(
      RepaintBoundary(
        child: ShaderBuilder(
          assetKey: 'packages/fl_nodes/shaders/grid.frag',
          (context, gridShader, child) => NodeEditorRenderObjectWidget(
            key: kNodeEditorWidgetKey,
            controller: widget.controller,
            style: style,
            config: config,
            gridShader: gridShader,
            headerBuilder: widget.headerBuilder,
            portBuilder: widget.portBuilder,
            fieldBuilder: widget.fieldBuilder,
            contextMenuBuilder: widget.contextMenuBuilder,
            nodeBuilder: widget.nodeBuilder,
          ),
        ),
      ),
    );
  }
}
