import '../../models/data.dart';
import 'package:flutter/widgets.dart';

/// Utility class for working with RenderBox objects.
final class RenderBoxUtils {
  /// Retrieves the global offset of a widget identified by a [GlobalKey].
  static Offset? getOffsetFromGlobalKey(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.localToGlobal(Offset.zero);
    }
    return null;
  }

  /// Retrieves the global offset of a widget relative to another widget.
  static Offset? getOffsetFromGlobalKeyRelativeTo(
    GlobalKey key,
    GlobalKey relativeTo,
  ) {
    final renderObject = key.currentContext?.findRenderObject();
    final relativeRenderObject = relativeTo.currentContext?.findRenderObject();
    if (renderObject is RenderBox && relativeRenderObject is RenderBox) {
      return renderObject.localToGlobal(
        Offset.zero,
        ancestor: relativeRenderObject,
      );
    }
    return null;
  }

  /// Retrieves the size of a widget identified by a [GlobalKey].
  static Size? getSizeFromGlobalKey(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.size;
    }
    return null;
  }

  /// Retrieves the bounds of a Node widget.
  static Rect? getEntityBoundsInWorld(FlNodeDataModel node) {
    final size = getSizeFromGlobalKey(node.key);
    if (size != null) {
      return Rect.fromLTWH(
        node.offset.dx,
        node.offset.dy,
        size.width,
        size.height,
      );
    }
    return null;
  }

  static Rect? getEditorBoundsInScreen(GlobalKey key) {
    final size = getSizeFromGlobalKey(key);
    final offset = getOffsetFromGlobalKey(key);
    if (size != null && offset != null) {
      return Rect.fromLTWH(
        offset.dx,
        offset.dy,
        size.width,
        size.height,
      );
    }
    return null;
  }

  /// Converts a screen position to a world (canvas) position.
  static Offset? screenToWorld(
    GlobalKey editorKey,
    Offset screenPosition,
    Offset offset,
    double zoom,
  ) {
    // Get the bounds of the editor widget on the screen
    final nodeEditorBounds = getEditorBoundsInScreen(editorKey);
    if (nodeEditorBounds == null) return null;
    final size = nodeEditorBounds.size;

    // Adjust the screen position relative to the top-left of the editor
    final adjustedScreenPosition = screenPosition - nodeEditorBounds.topLeft;

    // Calculate the viewport rectangle in canvas space
    final viewport = Rect.fromLTWH(
      -size.width / 2 / zoom - offset.dx,
      -size.height / 2 / zoom - offset.dy,
      size.width / zoom,
      size.height / zoom,
    );

    // Calculate the canvas position corresponding to the screen position
    final canvasX = viewport.left +
        (adjustedScreenPosition.dx / size.width) * viewport.width;
    final canvasY = viewport.top +
        (adjustedScreenPosition.dy / size.height) * viewport.height;

    return Offset(canvasX, canvasY);
  }

  /// Calculates the encompassing rectangle of a list of rectangles.
  ///
  /// If the list is empty, returns [Rect.zero].
  /// The `margin` parameter adds padding around the resulting rectangle.
  static Rect calculateBoundingRect(
    Iterable<Rect> rects, {
    double margin = 0.0,
  }) {
    if (rects.isEmpty) return Rect.zero;

    Rect boundingRect = rects.first;
    for (final rect in rects.skip(1)) {
      boundingRect = boundingRect.expandToInclude(rect);
    }

    return boundingRect.inflate(margin);
  }
}
