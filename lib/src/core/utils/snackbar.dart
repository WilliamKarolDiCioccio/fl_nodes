import 'package:fl_nodes/src/core/utils/constants.dart';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, warning, info }

void showNodeEditorSnackbar(String message, SnackbarType type) {
  late Color backgroundColor;

  switch (type) {
    case SnackbarType.success:
      backgroundColor = Colors.green;
      break;
    case SnackbarType.error:
      backgroundColor = Colors.red;
      break;
    case SnackbarType.warning:
      backgroundColor = Colors.orange;
      break;
    case SnackbarType.info:
      backgroundColor = Colors.blue;
      break;
  }
  if (kNodeEditorWidgetKey.currentContext != null) {
    ScaffoldMessenger.of(kNodeEditorWidgetKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
