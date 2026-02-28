import 'package:fl_context_menu/src/core/models/config.dart';
import 'package:fl_context_menu/src/core/models/entries.dart';
import 'package:fl_context_menu/src/styles/styles.dart';
import 'package:fl_context_menu/src/widgets/context_menu.dart';
import 'package:flutter/material.dart';

Future<T?> createPageRoute<T>({
  required BuildContext context,
  required Offset position,
  required FlMenuDataModel data,
  required FlMenuConfig config,
  required FlMenuStyle style,
}) async =>
    Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => Material(
          type: MaterialType.transparency,
          child: FlMenuWidget(
            position: position,
            data: data,
            config: config,
            style: style,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
