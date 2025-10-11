import 'package:fl_nodes_core/src/core/controller/core.dart';
import 'package:fl_nodes_core/src/core/models/overlay.dart';

/// A class that manages the overlay elements of the node editor.
class FlNodeEditorOverlayHelper {
  final FlNodeEditorController controller;
  Map<String, FlOverlayData> data = {};

  FlNodeEditorOverlayHelper(this.controller);

  void add(String idName, {required FlOverlayData data}) {
    this.data[idName] = data;
  }

  void remove(String idName) {
    data.remove(idName);
  }

  void clear() {
    data.clear();
  }

  void setVisibility(String idName, {required bool isVisible}) {
    if (data.containsKey(idName)) data[idName]!.isVisible = isVisible;
  }

  void setOpacity(String idName, {required double opacity}) {
    if (data.containsKey(idName)) data[idName]!.opacity = opacity;
  }
}
