/// A class that defines the behavior of a node editor.
///
/// This class is responsible for handling the interactions and
/// behaviors associated with a node editor, such as node selection,
/// movement, and other editor-specific functionalities.
class FlNodeEditorConfig {
  final bool enableZoom;
  final double zoomSensitivity;
  final double minZoom;
  final double maxZoom;
  final bool enablePan;
  final double panSensitivity;
  final double maxPanX;
  final double maxPanY;
  final bool enableKineticScrolling;
  final bool enableAutoScrolling;
  final bool enableAreaSelection;
  final bool enableSnapToGrid;
  final double snapToGridSize;
  final bool enableAutoPlacement;
  final bool enableZoomToCursor;

  const FlNodeEditorConfig({
    this.enableZoom = true,
    this.zoomSensitivity = 0.1,
    this.minZoom = 0.1,
    this.maxZoom = 10.0,
    this.enablePan = true,
    this.panSensitivity = 1.0,
    this.maxPanX = 100000.0,
    this.maxPanY = 100000.0,
    this.enableKineticScrolling = true,
    this.enableAutoScrolling = true,
    this.enableAreaSelection = true,
    this.enableSnapToGrid = true,
    this.snapToGridSize = 64.0,
    this.enableAutoPlacement = false,
    this.enableZoomToCursor = true,
  });

  FlNodeEditorConfig copyWith({
    bool? enableZoom,
    double? zoomSensitivity,
    double? minZoom,
    double? maxZoom,
    bool? enablePan,
    double? panSensitivity,
    double? maxPanX,
    double? maxPanY,
    bool? enableKineticScrolling,
    bool? enableAutoScrolling,
    bool? enableAreaSelection,
    bool? enableSnapToGrid,
    double? snapToGridSize,
    bool? enableAutoPlacement,
    bool? enableZoomToCursor,
  }) {
    return FlNodeEditorConfig(
      enableZoom: enableZoom ?? this.enableZoom,
      zoomSensitivity: zoomSensitivity ?? this.zoomSensitivity,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      enablePan: enablePan ?? this.enablePan,
      panSensitivity: panSensitivity ?? this.panSensitivity,
      maxPanX: maxPanX ?? this.maxPanX,
      maxPanY: maxPanY ?? this.maxPanY,
      enableKineticScrolling:
          enableKineticScrolling ?? this.enableKineticScrolling,
      enableAutoScrolling: enableAutoScrolling ?? this.enableAutoScrolling,
      enableAreaSelection: enableAreaSelection ?? this.enableAreaSelection,
      enableSnapToGrid: enableSnapToGrid ?? this.enableSnapToGrid,
      snapToGridSize: snapToGridSize ?? this.snapToGridSize,
      enableAutoPlacement: enableAutoPlacement ?? this.enableAutoPlacement,
      enableZoomToCursor: enableZoomToCursor ?? this.enableZoomToCursor,
    );
  }
}
