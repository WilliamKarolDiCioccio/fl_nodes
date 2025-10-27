import 'dart:async';
import 'dart:math';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes_example/l10n/app_localizations.dart';
import 'package:fl_nodes_example/visual_scripting_example/nodes/data/types.dart';
import 'package:fl_nodes_example/visual_scripting_example/nodes/styles/headers.dart';
import 'package:fl_nodes_example/visual_scripting_example/nodes/styles/ports.dart';
import 'package:fl_nodes_example/visual_scripting_example/widgets/terminal.dart';
import 'package:flutter/material.dart';

FlNodePrototype createValueNode<T>({
  required String idName,
  required String Function(BuildContext context) displayName,
  required T defaultValue,
  required Widget Function(T data) visualizerBuilder,
  Function(dynamic data, Function(dynamic data) setData)? onVisualizerTap,
  Widget Function(
    BuildContext context,
    Function() removeOverlay,
    dynamic data,
    Function(dynamic data, {required FlFieldEventType eventType}) setData,
  )?
  editorBuilder,
}) {
  return FlNodePrototype(
    idName: 'value.$idName',
    displayName: displayName,
    description: (context) =>
        AppLocalizations.of(context)!.valueNodeDescription(T.toString()),
    headerStyleBuilder: NodeHeaderStyles.value,
    portPrototypes: [
      FlControlOutputPortPrototype(
        idName: 'completed',
        displayName: (context) =>
            AppLocalizations.of(context)!.completedPortName,
        styleBuilder: PortStyles.controlOutput,
        geometricOrientation: FlPortGeometricOrientation.right,
      ),
      FlDataOutputPortPrototype<T>(
        idName: 'value',
        linkPrototype: FlLinkPrototype(label: (_) => T.toString()),
        displayName: (context) => AppLocalizations.of(context)!.valuePortName,
        styleBuilder: PortStyles.dataOutput,
        geometricOrientation: FlPortGeometricOrientation.right,
      ),
    ],
    fieldPrototypes: [
      FlFieldPrototype(
        idName: 'value',
        displayName: (context) => AppLocalizations.of(context)!.valueFieldName,
        dataType: T,
        defaultData: defaultValue,
        visualizerBuilder: (data) => visualizerBuilder(data as T),
        onVisualizerTap: onVisualizerTap,
        editorBuilder: editorBuilder,
      ),
    ],
    onExecute: (ports, fields, state, f, p) async {
      p({('value', fields['value']!)});

      unawaited(f({('completed')}));
    },
  );
}

void registerNodes(BuildContext context, FlNodesController controller) {
  controller.registerNodePrototype(
    createValueNode<double>(
      idName: 'numericValue',
      displayName: (context) =>
          AppLocalizations.of(context)!.numericValueNodeName,
      defaultValue: 0.0,
      visualizerBuilder: (data) => Text(
        data.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(color: Colors.white),
      ),
      editorBuilder: (context, removeOverlay, data, setData) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 100),
        child: TextFormField(
          initialValue: data.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setData(
              double.tryParse(value) ?? 0.0,
              eventType: FlFieldEventType.change,
            );
          },
          onFieldSubmitted: (value) {
            setData(
              double.tryParse(value) ?? 0.0,
              eventType: FlFieldEventType.submit,
            );
            removeOverlay();
          },
        ),
      ),
    ),
  );

  controller.registerNodePrototype(
    createValueNode<bool>(
      idName: 'boolValue',
      displayName: (context) =>
          AppLocalizations.of(context)!.booleanValueNodeName,
      defaultValue: false,
      visualizerBuilder: (data) =>
          Icon(data ? Icons.check : Icons.close, color: Colors.white, size: 18),
      onVisualizerTap: (data, setData) => setData(!data),
    ),
  );

  controller.registerNodePrototype(
    createValueNode<String>(
      idName: 'stringValue',
      displayName: (context) =>
          AppLocalizations.of(context)!.stringValueNodeName,
      defaultValue: '',
      visualizerBuilder: (data) => Text(
        '"$data"',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(color: Colors.white),
      ),
      editorBuilder: (context, removeOverlay, data, setData) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: TextFormField(
          initialValue: data,
          onChanged: (value) {
            setData(value, eventType: FlFieldEventType.change);
          },
          onFieldSubmitted: (value) {
            setData(value, eventType: FlFieldEventType.submit);
            removeOverlay();
          },
        ),
      ),
    ),
  );

  controller.registerNodePrototype(
    createValueNode<List<int>>(
      idName: 'numericListValue',
      displayName: (context) =>
          AppLocalizations.of(context)!.numericListValueNodeName,
      defaultValue: [],
      visualizerBuilder: (data) => Text(
        data.length > 3
            ? '[${data.take(3).join(', ')}...]'
            : '[${data.join(', ')}]',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(color: Colors.white),
      ),
      editorBuilder: (context, removeOverlay, data, setData) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: TextFormField(
          initialValue: data.join(', '),
          onChanged: (value) {
            setData(
              value.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList(),
              eventType: FlFieldEventType.change,
            );
          },
          onFieldSubmitted: (value) {
            setData(
              value.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList(),
              eventType: FlFieldEventType.submit,
            );
            removeOverlay();
          },
        ),
      ),
    ),
  );

  controller.registerNodePrototype(
    createValueNode<List<bool>>(
      idName: 'boolListValue',
      displayName: (context) =>
          AppLocalizations.of(context)!.booleanListValueNodeName,
      defaultValue: [],
      visualizerBuilder: (data) => Text(
        data.length > 3
            ? '[${data.take(3).map((e) => e ? 'true' : 'false').join(', ')}...]'
            : '[${data.map((e) => e ? 'true' : 'false').join(', ')}]',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(color: Colors.white),
      ),
      editorBuilder: (context, removeOverlay, data, setData) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: TextFormField(
          initialValue: data.map((e) => e ? 'true' : 'false').join(', '),
          onChanged: (value) {
            setData(
              value.split(',').map((e) => e.trim() == 'true').toList(),
              eventType: FlFieldEventType.change,
            );
          },
          onFieldSubmitted: (value) {
            setData(
              value.split(',').map((e) => e.trim() == 'true').toList(),
              eventType: FlFieldEventType.submit,
            );
            removeOverlay();
          },
        ),
      ),
    ),
  );

  String formatStringList(List<String> data) {
    if (data.isEmpty) return '[]';
    return '[${data.length > 3 ? '${data.take(3).join(', ')}...' : data.join(', ')}]';
  }

  String serializeStringList(List<String> data) {
    return data.map((e) => '"$e"').join(', ');
  }

  List<String> parseStringList(String input) {
    final regex = RegExp(r'"(.*?)"');
    return regex.allMatches(input).map((e) => e.group(1)!).toList();
  }

  controller.registerNodePrototype(
    createValueNode<List<String>>(
      idName: 'stringListValue',
      displayName: (context) =>
          AppLocalizations.of(context)!.stringListValueNodeName,
      defaultValue: [],
      visualizerBuilder: (data) => Text(
        formatStringList(data),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(color: Colors.white),
      ),
      editorBuilder: (context, removeOverlay, data, setData) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: TextFormField(
          initialValue: serializeStringList(data),
          onChanged: (value) => setData(
            parseStringList(value),
            eventType: FlFieldEventType.change,
          ),
          onFieldSubmitted: (value) {
            setData(parseStringList(value), eventType: FlFieldEventType.submit);
            removeOverlay();
          },
        ),
      ),
    ),
  );

  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'math.operator',
      displayName: (context) => AppLocalizations.of(context)!.operatorNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.operatorNodeDescription,
      headerStyleBuilder: NodeHeaderStyles.math,
      portPrototypes: [
        FlControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: PortStyles.controlInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype<double>(
          idName: 'a',
          displayName: (context) => 'A',
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype<double>(
          idName: 'b',
          displayName: (context) => 'B',
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlDataOutputPortPrototype<double>(
          idName: 'result',
          linkPrototype: FlLinkPrototype(label: (_) => 'double'),
          displayName: (context) =>
              AppLocalizations.of(context)!.resultPortName,
          styleBuilder: PortStyles.dataOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
      ],
      fieldPrototypes: [
        FlFieldPrototype(
          idName: 'operation',
          displayName: (context) =>
              AppLocalizations.of(context)!.operationPortName,
          dataType: Operator,
          defaultData: Operator.add,
          visualizerBuilder: (data) => Text(
            data.toString().split('.').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          editorBuilder: (context, removeOverlay, data, setData) =>
              SegmentedButton<Operator>(
                segments: [
                  ButtonSegment(
                    value: Operator.add,
                    label: Text(AppLocalizations.of(context)!.addFieldOption),
                  ),
                  ButtonSegment(
                    value: Operator.subtract,
                    label: Text(
                      AppLocalizations.of(context)!.subtractFieldOption,
                    ),
                  ),
                  ButtonSegment(
                    value: Operator.multiply,
                    label: Text(
                      AppLocalizations.of(context)!.multiplyFieldOption,
                    ),
                  ),
                  ButtonSegment(
                    value: Operator.divide,
                    label: Text(
                      AppLocalizations.of(context)!.divideFieldOption,
                    ),
                  ),
                ],
                selected: {data as Operator},
                onSelectionChanged: (newSelection) {
                  setData(
                    newSelection.first,
                    eventType: FlFieldEventType.submit,
                  );
                  removeOverlay();
                },
                direction: Axis.horizontal,
              ),
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        final a = ports['a']! as double;
        final b = ports['b']! as double;
        final op = fields['operation']! as Operator;

        switch (op) {
          case Operator.add:
            p({('result', a + b)});
          case Operator.subtract:
            p({('result', a - b)});
          case Operator.multiply:
            p({('result', a * b)});
          case Operator.divide:
            p({('result', b == 0 ? 0 : a / b)});
        }

        unawaited(f({('completed')}));
      },
    ),
  );

  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'generator.random',
      displayName: (context) => AppLocalizations.of(context)!.randomNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.randomNodeDescription,
      headerStyleBuilder: NodeHeaderStyles.generator,
      portPrototypes: [
        FlControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlDataOutputPortPrototype<double>(
          idName: 'value',
          linkPrototype: FlLinkPrototype(label: (_) => 'double'),
          displayName: (context) => AppLocalizations.of(context)!.valuePortName,
          styleBuilder: PortStyles.dataOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        p({('value', Random().nextDouble())});

        unawaited(f({('completed')}));
      },
    ),
  );

  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'flow.if',
      displayName: (context) => AppLocalizations.of(context)!.ifNodeName,
      description: (context) => AppLocalizations.of(context)!.ifNodeDescription,
      headerStyleBuilder: NodeHeaderStyles.flow,
      portPrototypes: [
        FlControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: PortStyles.controlInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype<bool>(
          idName: 'condition',
          displayName: (context) =>
              AppLocalizations.of(context)!.conditionPortName,
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlControlOutputPortPrototype(
          idName: 'trueBranch',
          displayName: (context) => AppLocalizations.of(context)!.truePortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlControlOutputPortPrototype(
          idName: 'falseBranch',
          displayName: (context) => AppLocalizations.of(context)!.falsePortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        final condition = ports['condition']! as bool;

        condition
            ? unawaited(f({('trueBranch')}))
            : unawaited(f({('falseBranch')}));
      },
    ),
  );

  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'flow.forEachLoop',
      displayName: (context) =>
          AppLocalizations.of(context)!.forEachLoopNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.forEachLoopNodeDescription,
      headerStyleBuilder: NodeHeaderStyles.flow,
      portPrototypes: [
        FlControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: PortStyles.controlInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype(
          idName: 'list',
          displayName: (context) => AppLocalizations.of(context)!.listPortName,
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlControlOutputPortPrototype(
          idName: 'loopBody',
          displayName: (context) =>
              AppLocalizations.of(context)!.loopBodyPortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlDataOutputPortPrototype(
          idName: 'listElem',
          linkPrototype: FlLinkPrototype(label: (_) => 'dynamic'),
          displayName: (context) =>
              AppLocalizations.of(context)!.listElementPortName,
          styleBuilder: PortStyles.dataOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlDataOutputPortPrototype<int>(
          idName: 'listIdx',
          linkPrototype: FlLinkPrototype(label: (_) => 'int'),
          displayName: (context) =>
              AppLocalizations.of(context)!.listIndexPortName,
          styleBuilder: PortStyles.dataOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        final List<dynamic> list = ports['list']! as List<dynamic>;

        late int i;

        if (!state.containsKey('iteration')) {
          i = state['iteration'] = 0;
        } else {
          i = state['iteration'] as int;
        }

        if (i < list.length) {
          p({('listElem', list[i]), ('listIdx', i)});
          state['iteration'] = ++i;
          await f({'loopBody'});
        } else {
          unawaited(f({('completed')}));
        }
      },
    ),
  );

  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'logic.comparator',
      displayName: (context) =>
          AppLocalizations.of(context)!.comparatorNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.comparatorNodeDescription,
      headerStyleBuilder: NodeHeaderStyles.logic,
      portPrototypes: [
        FlControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: PortStyles.controlInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype(
          idName: 'a',
          displayName: (context) => 'A',
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype(
          idName: 'b',
          displayName: (context) => 'B',
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlDataOutputPortPrototype<bool>(
          idName: 'result',
          linkPrototype: FlLinkPrototype(label: (_) => 'bool'),
          displayName: (context) =>
              AppLocalizations.of(context)!.resultPortName,
          styleBuilder: PortStyles.dataOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
      ],
      fieldPrototypes: [
        FlFieldPrototype(
          idName: 'comparator',
          displayName: (context) =>
              AppLocalizations.of(context)!.comparatorPortName,
          dataType: Comparator,
          defaultData: Comparator.equal,
          visualizerBuilder: (data) => Text(
            data.toString().split('.').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          editorBuilder: (context, removeOverlay, data, setData) =>
              SegmentedButton<Comparator>(
                segments: const [
                  ButtonSegment(value: Comparator.equal, label: Text('==')),
                  ButtonSegment(value: Comparator.notEqual, label: Text('!=')),
                  ButtonSegment(value: Comparator.greater, label: Text('>')),
                  ButtonSegment(
                    value: Comparator.greaterEqual,
                    label: Text('>='),
                  ),
                  ButtonSegment(value: Comparator.less, label: Text('<')),
                  ButtonSegment(value: Comparator.lessEqual, label: Text('<=')),
                ],
                selected: {data as Comparator},
                onSelectionChanged: (newSelection) {
                  setData(
                    newSelection.first,
                    eventType: FlFieldEventType.submit,
                  );
                  removeOverlay();
                },
                direction: Axis.horizontal,
              ),
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        final a = ports['a']! as dynamic;
        final b = ports['b']! as dynamic;
        final comp = fields['comparator']! as Comparator;

        switch (comp) {
          case Comparator.equal:
            p({('result', a == b)});
          case Comparator.notEqual:
            p({('result', a != b)});
          case Comparator.greater:
            p({('result', a > b)});
          case Comparator.greaterEqual:
            p({('result', a >= b)});
          case Comparator.less:
            p({('result', a < b)});
          case Comparator.lessEqual:
            p({('result', a <= b)});
        }

        unawaited(f({('completed')}));
      },
    ),
  );

  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'io.print',
      displayName: (context) => AppLocalizations.of(context)!.printNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.printNodeDescription,
      headerStyleBuilder: NodeHeaderStyles.io,
      portPrototypes: [
        FlControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: PortStyles.controlInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype(
          idName: 'value',
          displayName: (context) => AppLocalizations.of(context)!.valuePortName,
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        TerminalController.instance.info('Value: ${ports['value']}');

        unawaited(f({('completed')}));
      },
    ),
  );

  controller.registerNodePrototype(
    FlNodePrototype(
      idName: 'math.round',
      displayName: (context) => AppLocalizations.of(context)!.roundNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.roundNodeDescription,
      headerStyleBuilder: NodeHeaderStyles.math,
      portPrototypes: [
        FlControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: PortStyles.controlInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlDataInputPortPrototype<double>(
          idName: 'value',
          displayName: (context) => AppLocalizations.of(context)!.valuePortName,
          styleBuilder: PortStyles.dataInput,
          geometricOrientation: FlPortGeometricOrientation.left,
        ),
        FlControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: PortStyles.controlOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
        FlDataOutputPortPrototype<int>(
          idName: 'rounded',
          linkPrototype: FlLinkPrototype(label: (_) => 'int'),
          displayName: (context) =>
              AppLocalizations.of(context)!.roundedPortName,
          styleBuilder: PortStyles.dataOutput,
          geometricOrientation: FlPortGeometricOrientation.right,
        ),
      ],
      fieldPrototypes: [
        FlFieldPrototype(
          idName: 'decimals',
          displayName: (context) =>
              AppLocalizations.of(context)!.decimalsFieldName,
          dataType: int,
          defaultData: 2,
          visualizerBuilder: (data) => Text(
            data.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          editorBuilder: (context, removeOverlay, data, setData) =>
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: TextFormField(
                  initialValue: data.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setData(
                      int.tryParse(value) ?? 0,
                      eventType: FlFieldEventType.change,
                    );
                  },
                  onFieldSubmitted: (value) {
                    setData(
                      int.tryParse(value) ?? 0,
                      eventType: FlFieldEventType.submit,
                    );
                    removeOverlay();
                  },
                ),
              ),
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        final double value = ports['value']! as double;
        final int decimals = fields['decimals']! as int;

        p({('rounded', double.parse(value.toStringAsFixed(decimals)))});

        unawaited(f({('completed')}));
      },
    ),
  );
}
