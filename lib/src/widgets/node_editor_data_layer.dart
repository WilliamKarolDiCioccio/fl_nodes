import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:keymap/keymap.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import 'package:fl_nodes/src/core/utils/renderbox.dart';
import 'package:fl_nodes/src/utils/context_menu.dart';
import 'package:fl_nodes/src/utils/improved_listener.dart';
import 'package:fl_nodes/src/widgets/node_editor_render_object.dart';

import '../constants.dart';
import '../core/controllers/node_editor/core.dart';
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
  final FlNodeHeaderBuilder? headerBuilder;
  final FlNodeFieldBuilder? fieldBuilder;
  final FlNodePortBuilder? portBuilder;
  final FlNodeContextMenuBuilder? contextMenuBuilder;
  final FlNodeBuilder? nodeBuilder;

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
  set offset(Offset value) => widget.controller.viewportOffset = value;
  set zoom(double value) => widget.controller.viewportZoom = value;
  FlNodeEditorStyle get style => widget.controller.style;

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

    if (event is ViewportOffsetEvent) {
      _setOffset(event.offset, animate: event.animate);
    } else if (event is ViewportZoomEvent) {
      _setZoom(event.zoom, animate: event.animate);
    } else if (event is DragSelectionEvent) {
      setState(() {
        _suppressEvents();
      });
    } else if (event is AddNodeEvent ||
        event is RemoveNodeEvent ||
        event is RemoveLinkEvent ||
        event is DrawTempLinkEvent ||
        event is CutSelectionEvent) {
      setState(() {});
    } else if (event is UpdateStyleEvent ||
        event is AddLinkEvent ||
        event is PasteSelectionEvent ||
        event is LoadProjectEvent ||
        event is NewProjectEvent ||
        event is NodeStateEvent ||
        event is NodeFieldEvent &&
            (event.eventType == FieldEventType.submit ||
                event.eventType == FieldEventType.cancel)) {
      setState(() {});
      // We delay the second setState to ensure that the UI has been built and  the keys updated
      SchedulerBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  void _onDragStart() {
    setState(() {
      _isDragging = true;
    });
    _offsetAnimationController.stop();
    _startKineticTimer();
  }

  void _onDragUpdate(Offset delta) {
    setState(() {
      _lastPositionDelta = delta;
    });
    _resetKineticTimer();
    _setOffsetFromRawInput(delta);
  }

  void _onDragCancel() => _onDragEnd();

  void _onDragEnd() {
    setState(() {
      _isDragging = false;
      _kineticEnergy = _lastPositionDelta;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.controller.config.zoomSensitivity > 0 && details.scale != 1.0) {
      _setZoomFromRawInput(
        details.scale,
        details.focalPoint,
        isTrackpadInput: true,
      );
    } else if (widget.controller.config.panSensitivity > 0 &&
        details.focalPointDelta != const Offset(10, 10)) {
      _onDragUpdate(details.focalPointDelta);
    }
  }

  void _onSelectStart(Offset position) {
    setState(() {
      _isSelecting = true;
      _selectionStart = screenToWorld(
        position,
        offset,
        zoom,
      )!;
    });
  }

  void _onSelectUpdate(Offset position) {
    setState(() {
      widget.controller.setSelectionArea(
        Rect.fromPoints(
          _selectionStart,
          screenToWorld(
            position,
            offset,
            zoom,
          )!,
        ),
      );
    });
  }

  void _onSelectCancel() {
    setState(() {
      _isSelecting = false;
      _selectionStart = Offset.zero;
      widget.controller.setSelectionArea(Rect.zero);
    });
  }

  void _onSelectEnd() {
    setState(() {
      if (widget.controller.selectionArea.size > const Size(10, 10)) {
        widget.controller.selectNodesByArea(
          holdSelection: HardwareKeyboard.instance.isControlPressed,
        );
      } else {
        widget.controller.setSelectionArea(Rect.zero);
      }

      _isSelecting = false;
      _selectionStart = Offset.zero;
    });
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
    final worldPosition = screenToWorld(
      position,
      offset,
      zoom,
    );

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

  void _suppressEvents() {
    if (_isDragging) {
      _onDragCancel();
    } else if (_isLinking) {
      _onLinkCancel();
    } else if (_isSelecting) {
      _onSelectCancel();
    } else {
      setState(() {});
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
    final Offset offsetFactor =
        delta * widget.controller.config.panSensitivity / zoom;

    final Offset targetOffset = offset + offsetFactor;

    _setOffset(targetOffset, animate: !os_detect.isAndroid);
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
          setState(() {
            offset = _offsetAnimation.value;
          });
        });

      _offsetAnimationController.forward();
    } else {
      setState(() {
        offset = endOffset;
      });
    }
  }

  void _setZoomFromRawInput(
    double amount,
    Offset focalPoint, {
    bool isTrackpadInput = false,
  }) {
    const double zoomSpeed = 0.1; // Adjust this to fine-tune zoom sensitivity

    final double sensitivity = widget.controller.config.zoomSensitivity;
    final double logZoom = log(zoom); // Convert to logarithmic scale

    // Calculate new zoom level in log space

    late double delta;

    if (isTrackpadInput) {
      // Trackpad: amount is in range (0, 1] for zoom out, (1, ∞) for zoom in
      // Due to the logarithmic scale, we need to multiply by 10 to get a reasonable delta.
      // NOTE: macOS seems to have a different behavior, so we need to account for that.

      late final double bias;

      if (os_detect.isMacOS) {
        bias = 1;
      } else if (os_detect.isWindows) {
        bias = 10;
      } else if (os_detect.isLinux) {
        bias = 5;
      } else if (os_detect.isAndroid) {
        bias = 0.75;
      } else {
        bias = 1;
      }

      delta = log(amount) * sensitivity * bias;
    } else {
      // Mouse wheel or other input: positive zooms in, negative zooms out
      delta = amount * zoomSpeed * sensitivity;
    }

    final double targetLogZoom =
        isTrackpadInput ? logZoom + delta : logZoom - delta;

    final double targetZoom =
        exp(targetLogZoom); // Convert back to linear space

    _setZoom(
      targetZoom,
      animate: !os_detect.isMacOS && !os_detect.isIOS && !os_detect.isAndroid,
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
          setState(() {
            zoom = _zoomAnimation.value;
          });
        });

      _zoomAnimationController.forward();
    } else {
      setState(() {
        zoom = endZoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ContextMenuEntry> createSubmenuEntries(Offset position) {
      final fromLink = _tempLink != null;

      final List<MapEntry<String, NodePrototype>> compatiblePrototypes = [];

      if (fromLink) {
        final startPort = widget
            .controller.nodes[_tempLink!.nodeId]!.ports[_tempLink!.portId]!;

        widget.controller.nodePrototypes.forEach(
          (key, value) {
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
          label: entry.value.displayName,
          value: entry.value.displayName,
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
                addedNode.ports.entries
                    .firstWhere(
                      (port) =>
                          port.value.prototype.direction !=
                              startPort.prototype.direction &&
                          port.value.prototype.type ==
                              startPort.prototype.type &&
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

    List<ContextMenuEntry> editorContextMenuEntries(Offset position) {
      final worldPosition = screenToWorld(
        position,
        offset,
        zoom,
      )!;

      return [
        const MenuHeader(text: "Editor Menu"),
        MenuItem(
          label: 'Center View',
          icon: Icons.center_focus_strong,
          onSelected: () => widget.controller.setViewportOffset(
            Offset.zero,
            absolute: true,
          ),
        ),
        MenuItem(
          label: 'Reset Zoom',
          icon: Icons.zoom_in,
          onSelected: () => widget.controller.setViewportZoom(1.0),
        ),
        const MenuDivider(),
        MenuItem.submenu(
          label: 'Create',
          icon: Icons.add,
          items: createSubmenuEntries(position),
        ),
        MenuItem(
          label: 'Paste',
          icon: Icons.paste,
          onSelected: () => widget.controller.clipboard
              .pasteSelection(position: worldPosition),
        ),
        const MenuDivider(),
        MenuItem.submenu(
          label: 'Project',
          icon: Icons.folder,
          items: [
            MenuItem(
              label: 'Undo',
              icon: Icons.undo,
              onSelected: () => widget.controller.history.undo(),
            ),
            MenuItem(
              label: 'Redo',
              icon: Icons.redo,
              onSelected: () => widget.controller.history.redo(),
            ),
            MenuItem(
              label: 'Save',
              icon: Icons.save,
              onSelected: () => widget.controller.project.save(),
            ),
            MenuItem(
              label: 'Open',
              icon: Icons.folder_open,
              onSelected: () => widget.controller.project.load(),
            ),
            MenuItem(
              label: 'New',
              icon: Icons.new_label,
              onSelected: () => widget.controller.project.create(),
            ),
          ],
        ),
      ];
    }

    List<ContextMenuEntry> portContextMenuEntries(
      Offset position, {
      required _TempLink locator,
    }) {
      return [
        const MenuHeader(text: "Port Menu"),
        MenuItem(
          label: 'Remove Links',
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
      return os_detect.isAndroid || os_detect.isIOS
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
                  _onSelectStart(details.focalPoint);
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
                      _onSelectEnd();
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
                    _onSelectUpdate(details.focalPoint);
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
                  _onSelectEnd();
                  _isSelecting = false;
                }
              },
              child: child,
            )
          : KeyboardWidget(
              bindings: [
                KeyAction(
                  LogicalKeyboardKey.delete,
                  "Remove selected nodes",
                  () {
                    for (final nodeId in widget.controller.selectedNodeIds) {
                      widget.controller.removeNode(
                        nodeId,
                        isHandled:
                            nodeId != widget.controller.selectedNodeIds.last,
                      );
                    }
                  },
                ),
                KeyAction(
                  LogicalKeyboardKey.backspace,
                  "Remove selected nodes",
                  () {
                    for (final nodeId in widget.controller.selectedNodeIds) {
                      widget.controller.removeNode(
                        nodeId,
                        isHandled:
                            nodeId != widget.controller.selectedNodeIds.last,
                      );
                    }
                    widget.controller.clearSelection();
                  },
                ),
                KeyAction(
                  LogicalKeyboardKey.keyC,
                  "Copy selected nodes",
                  () => widget.controller.clipboard.copySelection(),
                  isControlPressed: true,
                ),
                KeyAction(
                  LogicalKeyboardKey.keyV,
                  "Paste selected nodes",
                  () => widget.controller.clipboard.pasteSelection(),
                  isControlPressed: true,
                ),
                KeyAction(
                  LogicalKeyboardKey.keyX,
                  "Cut selected nodes",
                  () => widget.controller.clipboard.cutSelection(),
                  isControlPressed: true,
                ),
                KeyAction(
                  LogicalKeyboardKey.keyS,
                  "Save project",
                  () => widget.controller.project.save(),
                  isControlPressed: true,
                ),
                KeyAction(
                  LogicalKeyboardKey.keyO,
                  "Open project",
                  () => widget.controller.project.load(),
                  isControlPressed: true,
                ),
                KeyAction(
                  LogicalKeyboardKey.keyN,
                  "Create new project",
                  () => widget.controller.project.create(),
                  isControlPressed: true,
                  isShiftPressed: true,
                ),
                KeyAction(
                  LogicalKeyboardKey.keyZ,
                  "Undo",
                  () => widget.controller.history.undo(),
                  isControlPressed: true,
                ),
                KeyAction(
                  LogicalKeyboardKey.keyY,
                  "Redo",
                  () => widget.controller.history.redo(),
                  isControlPressed: true,
                ),
              ],
              child: MouseRegion(
                cursor: _isDragging
                    ? SystemMouseCursors.move
                    : SystemMouseCursors.basic,
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
                        _onSelectStart(event.position);
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
                      _onSelectUpdate(event.position);
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
                      _onSelectEnd();
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
              ),
            );
    }

    return controlsWrapper(
      RepaintBoundary(
        child: ShaderBuilder(
          assetKey: 'packages/fl_nodes/shaders/grid.frag',
          (context, gridShader, child) => NodeEditorRenderObjectWidget(
            key: kNodeEditorWidgetKey,
            controller: widget.controller,
            style: style,
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
