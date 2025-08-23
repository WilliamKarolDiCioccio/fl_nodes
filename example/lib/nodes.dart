import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:example/l10n/app_localizations.dart';

import 'package:fl_nodes/fl_nodes.dart';

enum Operator { add, subtract, multiply, divide }

enum Comparator { equal, notEqual, greater, greaterEqual, less, lessEqual }

FlPortStyle outputDataPortStyle(PortState state) => FlPortStyle(
      color: state.isHovered ? Colors.limeAccent : Colors.deepOrange,
      shape: FlPortShape.circle,
      linkStyleBuilder: (state) => FlLinkStyle(
        color: state.isSelected
            ? Colors.orangeAccent
            : state.isHovered
                ? Colors.limeAccent
                : Colors.deepOrange,
        lineWidth: state.isSelected
            ? 3.5
            : state.isHovered
                ? 4.5
                : 2.5,
        drawMode: FlLineDrawMode.solid,
        curveType: FlLinkCurveType.bezier,
      ),
    );

FlPortStyle inputDataPortStyle(PortState state) => outputDataPortStyle(state);

FlPortStyle controlOutputPortStyle(PortState state) => FlPortStyle(
      color: state.isHovered ? Colors.limeAccent : Colors.green,
      shape: FlPortShape.triangle,
      linkStyleBuilder: (state) => FlLinkStyle.gradient(
        gradient: const LinearGradient(
          colors: [Colors.lightGreenAccent, Colors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        lineWidth: state.isSelected
            ? 3.5
            : state.isHovered
                ? 4.5
                : 2.5,
        drawMode: FlLineDrawMode.solid,
        curveType: FlLinkCurveType.bezier,
      ),
    );

FlPortStyle controlInputPortStyle(PortState state) =>
    controlOutputPortStyle(state);

NodePrototype createValueNode<T>({
  required String idName,
  required String Function(BuildContext context) displayName,
  required T defaultValue,
  required Widget Function(T data) visualizerBuilder,
  Function(
    dynamic data,
    Function(dynamic data) setData,
  )? onVisualizerTap,
  Widget Function(
    BuildContext context,
    Function() removeOverlay,
    dynamic data,
    Function(dynamic data, {required FieldEventType eventType}) setData,
  )? editorBuilder,
}) {
  return NodePrototype(
    idName: idName,
    displayName: displayName,
    description: (context) =>
        AppLocalizations.of(context)!.valueNodeDescription(T.toString()),
    styleBuilder: (state) => FlNodeStyle(
      decoration: defaultNodeStyle(state).decoration,
    ),
    headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(7),
          topRight: const Radius.circular(7),
          bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
          bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
        ),
      ),
    ),
    ports: [
      ControlOutputPortPrototype(
        idName: 'completed',
        displayName: (context) =>
            AppLocalizations.of(context)!.completedPortName,
        styleBuilder: controlOutputPortStyle,
      ),
      DataOutputPortPrototype<T>(
        idName: 'value',
        displayName: (context) => AppLocalizations.of(context)!.valuePortName,
        styleBuilder: outputDataPortStyle,
      ),
    ],
    fields: [
      FieldPrototype(
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

void registerNodes(BuildContext context, FlNodeEditorController controller) {
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
              eventType: FieldEventType.change,
            );
          },
          onFieldSubmitted: (value) {
            setData(
              double.tryParse(value) ?? 0.0,
              eventType: FieldEventType.submit,
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
      visualizerBuilder: (data) => Icon(
        data ? Icons.check : Icons.close,
        color: Colors.white,
        size: 18,
      ),
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
            setData(
              value,
              eventType: FieldEventType.change,
            );
          },
          onFieldSubmitted: (value) {
            setData(
              value,
              eventType: FieldEventType.submit,
            );
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
              eventType: FieldEventType.change,
            );
          },
          onFieldSubmitted: (value) {
            setData(
              value.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList(),
              eventType: FieldEventType.submit,
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
              eventType: FieldEventType.change,
            );
          },
          onFieldSubmitted: (value) {
            setData(
              value.split(',').map((e) => e.trim() == 'true').toList(),
              eventType: FieldEventType.submit,
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
            eventType: FieldEventType.change,
          ),
          onFieldSubmitted: (value) {
            setData(
              parseStringList(value),
              eventType: FieldEventType.submit,
            );
            removeOverlay();
          },
        ),
      ),
    ),
  );

  controller.registerNodePrototype(
    NodePrototype(
      idName: 'operator',
      displayName: (context) => AppLocalizations.of(context)!.operatorNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.operatorNodeDescription,
      styleBuilder: (state) => FlNodeStyle(
        decoration: defaultNodeStyle(state).decoration,
      ),
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.pink,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
      ports: [
        ControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: controlInputPortStyle,
        ),
        DataInputPortPrototype<double>(
          idName: 'a',
          displayName: (context) => 'A',
          styleBuilder: inputDataPortStyle,
        ),
        DataInputPortPrototype<double>(
          idName: 'b',
          displayName: (context) => 'B',
          styleBuilder: inputDataPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: controlOutputPortStyle,
        ),
        DataOutputPortPrototype<double>(
          idName: 'result',
          displayName: (context) =>
              AppLocalizations.of(context)!.resultPortName,
          styleBuilder: outputDataPortStyle,
        ),
      ],
      fields: [
        FieldPrototype(
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
                label: Text(
                  AppLocalizations.of(context)!.addFieldOption,
                ),
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
              setData(newSelection.first, eventType: FieldEventType.submit);
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
    NodePrototype(
      idName: 'random',
      displayName: (context) => AppLocalizations.of(context)!.randomNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.randomNodeDescription,
      styleBuilder: (state) => FlNodeStyle(
        decoration: defaultNodeStyle(state).decoration,
      ),
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
      ports: [
        ControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: controlOutputPortStyle,
        ),
        DataOutputPortPrototype<double>(
          idName: 'value',
          displayName: (context) => AppLocalizations.of(context)!.valuePortName,
          styleBuilder: outputDataPortStyle,
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        p({('value', Random().nextDouble())});

        unawaited(f({('completed')}));
      },
    ),
  );

  controller.registerNodePrototype(
    NodePrototype(
      idName: 'if',
      displayName: (context) => AppLocalizations.of(context)!.ifNodeName,
      description: (context) => AppLocalizations.of(context)!.ifNodeDescription,
      styleBuilder: (state) => FlNodeStyle(
        decoration: defaultNodeStyle(state).decoration,
      ),
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
      ports: [
        ControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: controlInputPortStyle,
        ),
        DataInputPortPrototype<bool>(
          idName: 'condition',
          displayName: (context) =>
              AppLocalizations.of(context)!.conditionPortName,
          styleBuilder: inputDataPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'trueBranch',
          displayName: (context) => AppLocalizations.of(context)!.truePortName,
          styleBuilder: controlOutputPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'falseBranch',
          displayName: (context) => AppLocalizations.of(context)!.falsePortName,
          styleBuilder: controlOutputPortStyle,
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
    NodePrototype(
      idName: 'comparator',
      displayName: (context) =>
          AppLocalizations.of(context)!.comparatorNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.comparatorNodeDescription,
      styleBuilder: (state) => FlNodeStyle(
        decoration: defaultNodeStyle(state).decoration,
      ),
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.cyan,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
      ports: [
        ControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: controlInputPortStyle,
        ),
        DataInputPortPrototype(
          idName: 'a',
          displayName: (context) => 'A',
          styleBuilder: inputDataPortStyle,
        ),
        DataInputPortPrototype(
          idName: 'b',
          displayName: (context) => 'B',
          styleBuilder: inputDataPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: controlOutputPortStyle,
        ),
        DataOutputPortPrototype<bool>(
          idName: 'result',
          displayName: (context) =>
              AppLocalizations.of(context)!.resultPortName,
          styleBuilder: outputDataPortStyle,
        ),
      ],
      fields: [
        FieldPrototype(
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
              ButtonSegment(value: Comparator.greaterEqual, label: Text('>=')),
              ButtonSegment(value: Comparator.less, label: Text('<')),
              ButtonSegment(value: Comparator.lessEqual, label: Text('<=')),
            ],
            selected: {data as Comparator},
            onSelectionChanged: (newSelection) {
              setData(newSelection.first, eventType: FieldEventType.submit);
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
    NodePrototype(
      idName: 'print',
      displayName: (context) => AppLocalizations.of(context)!.printNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.printNodeDescription,
      styleBuilder: (state) => FlNodeStyle(
        decoration: defaultNodeStyle(state).decoration,
      ),
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
      ports: [
        ControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: controlInputPortStyle,
        ),
        DataInputPortPrototype(
          idName: 'value',
          displayName: (context) => AppLocalizations.of(context)!.valuePortName,
          styleBuilder: inputDataPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: controlOutputPortStyle,
        ),
      ],
      onExecute: (ports, fields, state, f, p) async {
        if (kDebugMode) {
          print(ports['value']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Value: ${ports['value']}'),
          ),
        );

        unawaited(f({('completed')}));
      },
    ),
  );

  controller.registerNodePrototype(
    NodePrototype(
      idName: 'round',
      displayName: (context) => AppLocalizations.of(context)!.roundNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.roundNodeDescription,
      styleBuilder: (state) => FlNodeStyle(
        decoration: defaultNodeStyle(state).decoration,
      ),
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
      ports: [
        ControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: controlInputPortStyle,
        ),
        DataInputPortPrototype<double>(
          idName: 'value',
          displayName: (context) => AppLocalizations.of(context)!.valuePortName,
          styleBuilder: inputDataPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: controlOutputPortStyle,
        ),
        DataOutputPortPrototype<int>(
          idName: 'rounded',
          displayName: (context) =>
              AppLocalizations.of(context)!.roundedPortName,
          styleBuilder: outputDataPortStyle,
        ),
      ],
      fields: [
        FieldPrototype(
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
                  eventType: FieldEventType.change,
                );
              },
              onFieldSubmitted: (value) {
                setData(
                  int.tryParse(value) ?? 0,
                  eventType: FieldEventType.submit,
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

  controller.registerNodePrototype(
    NodePrototype(
      idName: 'forEachLoop',
      displayName: (context) =>
          AppLocalizations.of(context)!.forEachLoopNodeName,
      description: (context) =>
          AppLocalizations.of(context)!.forEachLoopNodeDescription,
      styleBuilder: (state) => FlNodeStyle(
        decoration: defaultNodeStyle(state).decoration,
      ),
      headerStyleBuilder: (state) => defaultNodeHeaderStyle(state).copyWith(
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
            bottomLeft: Radius.circular(state.isCollapsed ? 7 : 0),
            bottomRight: Radius.circular(state.isCollapsed ? 7 : 0),
          ),
        ),
      ),
      ports: [
        ControlInputPortPrototype(
          idName: 'exec',
          displayName: (context) => AppLocalizations.of(context)!.execPortName,
          styleBuilder: controlInputPortStyle,
        ),
        DataInputPortPrototype(
          idName: 'list',
          displayName: (context) => AppLocalizations.of(context)!.listPortName,
          styleBuilder: inputDataPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'loopBody',
          displayName: (context) =>
              AppLocalizations.of(context)!.loopBodyPortName,
          styleBuilder: controlOutputPortStyle,
        ),
        ControlOutputPortPrototype(
          idName: 'completed',
          displayName: (context) =>
              AppLocalizations.of(context)!.completedPortName,
          styleBuilder: controlOutputPortStyle,
        ),
        DataOutputPortPrototype(
          idName: 'listElem',
          displayName: (context) =>
              AppLocalizations.of(context)!.listElementPortName,
          styleBuilder: outputDataPortStyle,
        ),
        DataOutputPortPrototype<int>(
          idName: 'listIdx',
          displayName: (context) =>
              AppLocalizations.of(context)!.listIndexPortName,
          styleBuilder: outputDataPortStyle,
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
}
