import 'package:fl_nodes_core/src/core/controller/core.dart';
import 'package:fl_nodes_core/src/core/models/overlay.dart';
import 'package:fl_nodes_core/src/painters/custom_painter.dart';
import 'package:uuid/uuid.dart';

/// A class that manages the overlay elements of the node editor.
class FlNodeEditorOverlayHelper {
  final FlNodeEditorController controller;
  Map<String, FlOverlayData> data = {};

  FlNodeEditorOverlayHelper(this.controller);

  void add(String idName, {required FlOverlayData data}) {
    this.data[idName] = data;

    controller.eventBus.emit(
      FlOverlayChangedEvent({idName}, id: const Uuid().v4()),
    );
  }

  void remove(String idName) {
    data.remove(idName);

    controller.eventBus.emit(
      FlOverlayChangedEvent({idName}, id: const Uuid().v4()),
    );
  }

  void clear() {
    final idNames = data.keys.toSet();

    data.clear();

    controller.eventBus.emit(
      FlOverlayChangedEvent(idNames, id: const Uuid().v4()),
    );
  }

  void setVisibility(String idName, {required bool isVisible}) {
    if (data.containsKey(idName)) data[idName]!.isVisible = isVisible;

    controller.eventBus.emit(
      FlOverlayChangedEvent({idName}, id: const Uuid().v4()),
    );
  }

  void setOpacity(String idName, {required double opacity}) {
    if (data.containsKey(idName)) data[idName]!.opacity = opacity;

    controller.eventBus.emit(
      FlOverlayChangedEvent({idName}, id: const Uuid().v4()),
    );
  }

  void setPosition(
    String idName, {
    final double? top,
    final double? left,
    final double? bottom,
    final double? right,
  }) {
    if (!data.containsKey(idName)) return;

    data[idName]!.top = top;
    data[idName]!.left = left;
    data[idName]!.bottom = bottom;
    data[idName]!.right = right;

    controller.eventBus.emit(
      FlOverlayChangedEvent({idName}, id: const Uuid().v4()),
    );
  }
}
