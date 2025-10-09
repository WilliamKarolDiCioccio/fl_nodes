import 'package:flutter/material.dart';

import 'package:example/mind_map_example/nodes/data/types.dart';

import 'package:fl_nodes/fl_nodes.dart';

void registerNodes(BuildContext context, FlNodeEditorController controller) {
  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'shape.rectangle',
      displayName: (context) => 'Rectangle Node',
      ports: [
        FlGenericPortPrototype(
          idName: 'left',
          displayName: (context) => 'Left',
        ),
        FlGenericPortPrototype(
          idName: 'right',
          displayName: (context) => 'Right',
        ),
        FlGenericPortPrototype(
          idName: 'top',
          displayName: (context) => 'Top',
        ),
        FlGenericPortPrototype(
          idName: 'bottom',
          displayName: (context) => 'Bottom',
        ),
      ],
      customData: [
        ('shape', ShapeType, ShapeType.roundedRectangle),
      ],
      description: (context) => 'A node with a rectangular shape.',
      onExecute: (ports, fields, state, f, p) async => {},
    ),
  );
}
