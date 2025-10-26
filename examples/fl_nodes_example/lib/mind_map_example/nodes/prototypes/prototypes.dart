import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes_example/mind_map_example/nodes/data/types.dart';
import 'package:flutter/material.dart';

void registerNodes(BuildContext context, FlNodesController controller) {
  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'shape.rectangle',
      displayName: (context) => 'Rectangle Node',
      portPrototypes: [
        FlGenericPortPrototype(
          idName: 'left',
          displayName: (context) => 'Left',
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlGenericPortPrototype(
          idName: 'right',
          displayName: (context) => 'Right',
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlGenericPortPrototype(
          idName: 'top',
          displayName: (context) => 'Top',
          geometricOrientation: FlPortGeometricOrientation.top,
        ),
        FlGenericPortPrototype(
          idName: 'bottom',
          displayName: (context) => 'Bottom',
          geometricOrientation: FlPortGeometricOrientation.bottom,
        ),
      ],
      customData: [('shape', ShapeType, ShapeType.roundedRectangle)],
      description: (context) => 'A node with a rectangular shape.',
      onExecute: (ports, fields, state, f, p) async => {},
    ),
  );
}
