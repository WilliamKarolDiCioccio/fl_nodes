import 'package:fl_nodes/src/constants.dart';
import 'package:fl_nodes/src/core/models/entities.dart';
import 'package:flutter/widgets.dart';

/// Retrieves the global offset of a widget identified by a [GlobalKey].
Offset? getOffsetFromGlobalKey(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.localToGlobal(Offset.zero);
  }
  return null;
}

/// Retrieves the global offset of a widget relative to another widget.
Offset? getOffsetFromGlobalKeyRelativeTo(
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
Size? getSizeFromGlobalKey(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.size;
  }
  return null;
}

/// Retrieves the bounds of a Node widget.
Rect? getNodeBoundsInWorld(NodeInstance node) {
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

Rect? getEditorBoundsInScreen(GlobalKey key) {
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
Offset? screenToWorld(
  Offset screenPosition,
  Offset offset,
  double zoom,
) {
  // Get the bounds of the editor widget on the screen
  final nodeEditorBounds = getEditorBoundsInScreen(kNodeEditorWidgetKey);
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
  final canvasX =
      viewport.left + (adjustedScreenPosition.dx / size.width) * viewport.width;
  final canvasY = viewport.top +
      (adjustedScreenPosition.dy / size.height) * viewport.height;

  return Offset(canvasX, canvasY);
}
