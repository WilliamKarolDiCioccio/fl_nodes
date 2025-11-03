import 'package:fl_context_menu/fl_context_menu.dart';
import 'package:fl_context_menu/src/core/utils/page_route.dart';
import 'package:flutter/material.dart';

export 'src/core/models/config.dart';
export 'src/core/models/entries.dart';
export 'src/styles/styles.dart';
export 'src/widgets/context_menu.dart';
export 'src/widgets/context_menu_section.dart';

void showFlContextMenu({
  required BuildContext context,
  required Offset position,
  required FlMenuDataModel data,
  FlMenuConfig config = const FlMenuConfig(),
  FlMenuStyle style = const FlMenuStyle.basic(),
}) {
  createPageRoute(
    context: context,
    position: position,
    data: data,
    config: config,
    style: style,
  );
}
