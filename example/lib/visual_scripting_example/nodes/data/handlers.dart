import 'dart:convert';

import 'package:example/visual_scripting_example/nodes/data/types.dart';
import 'package:fl_nodes/fl_nodes.dart';

void registerDataHandlers(FlNodesController controller) {
  controller.project.registerDataHandler<Operator>(
    toJson: (data) => data.toString().split('.').last,
    fromJson: (json) =>
        Operator.values.firstWhere((e) => e.toString().split('.').last == json),
  );

  controller.project.registerDataHandler<Comparator>(
    toJson: (data) => data.toString().split('.').last,
    fromJson: (json) => Comparator.values.firstWhere(
      (e) => e.toString().split('.').last == json,
    ),
  );

  controller.project.registerDataHandler<List<int>>(
    toJson: (data) => jsonEncode(data),
    fromJson: (json) => List<int>.from(jsonDecode(json)),
  );

  controller.project.registerDataHandler<List<bool>>(
    toJson: (data) => jsonEncode(data),
    fromJson: (json) => List<bool>.from(jsonDecode(json)),
  );

  controller.project.registerDataHandler<List<String>>(
    toJson: (data) => jsonEncode(data),
    fromJson: (json) => List<String>.from(jsonDecode(json)),
  );
}
