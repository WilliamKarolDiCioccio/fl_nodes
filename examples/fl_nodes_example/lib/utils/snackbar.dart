import 'package:flutter/material.dart';

import 'package:fl_nodes/fl_nodes.dart';

/// A utility to display snackbars for fl_nodes callbacks (also used for other messages).
void showNodeEditorSnackbar(
  BuildContext context,
  String message,
  FlCallbackType type,
) {
  late Color backgroundColor;

  switch (type) {
    case FlCallbackType.success:
      backgroundColor = Colors.green;
      break;
    case FlCallbackType.error:
      backgroundColor = Colors.red;
      break;
    case FlCallbackType.warning:
      backgroundColor = Colors.orange;
      break;
    case FlCallbackType.info:
      backgroundColor = Colors.blue;
      break;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
