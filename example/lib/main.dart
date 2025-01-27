import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';

import 'package:fl_nodes/fl_nodes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }

  runApp(const NodeEditorExampleApp());
}

class NodeEditorExampleApp extends StatelessWidget {
  const NodeEditorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Node Editor Example',
      theme: ThemeData.dark(),
      home: const NodeEditorExampleScreen(),
      debugShowCheckedModeBanner: kDebugMode,
    );
  }
}

class NodeEditorExampleScreen extends StatefulWidget {
  const NodeEditorExampleScreen({super.key});

  @override
  State<NodeEditorExampleScreen> createState() =>
      NodeEditorExampleScreenState();
}

class NodeEditorExampleScreenState extends State<NodeEditorExampleScreen> {
  late final FlNodeEditorController _nodeEditorController;

  @override
  void initState() {
    super.initState();

    _nodeEditorController = FlNodeEditorController(
      projectSaver: (jsonData) async {
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Project',
          fileName: 'node_project.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputPath != null) {
          final File file = File(outputPath);
          await file.writeAsString(jsonEncode(jsonData));

          return true;
        } else {
          return false;
        }
      },
      projectLoader: (isSaved) async {
        if (!isSaved) {
          final bool? proceed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Unsaved Changes'),
                content: const Text(
                  'You have unsaved changes. Do you want to proceed without saving?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Proceed'),
                  ),
                ],
              );
            },
          );

          if (proceed != true) return null;
        }

        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result == null) return null;

        final File file = File(result.files.single.path!);
        final String fileContent = await file.readAsString();

        final Map<String, dynamic> jsonData = jsonDecode(fileContent);
        return jsonData;
      },
      projectCreator: (isSaved) async {
        if (isSaved) return true;

        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'You have unsaved changes. Do you want to proceed without saving?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Proceed'),
                ),
              ],
            );
          },
        );

        return proceed == true;
      },
    );

    _nodeEditorController.registerNodePrototype(
      NodePrototype(
        name: 'Add',
        description: 'Adds two numbers together.',
        ports: [
          InputPortPrototype(name: 'A', dataType: double),
          InputPortPrototype(name: 'B', dataType: double),
          OutputPortPrototype(name: 'Result', dataType: double),
        ],
        onExecute: (ports, fields) {
          final double a = ports['A'] as double;
          final double b = ports['B'] as double;

          ports['Result'] = a + b;
        },
      ),
    );

    _nodeEditorController.registerNodePrototype(
      NodePrototype(
        name: 'Input',
        description: 'Inputs a value.',
        ports: [
          OutputPortPrototype(name: 'Value', dataType: double),
        ],
        onExecute: (ports, fields) {
          ports['Value'] = Random().nextDouble();
        },
      ),
    );

    _nodeEditorController.registerNodePrototype(
      NodePrototype(
        name: 'Output',
        description: 'Outputs a value.',
        ports: [
          InputPortPrototype(
            name: 'Value',
            dataType: double,
          ),
        ],
        onExecute: (ports, fields) {
          debugPrint('Output: ${ports['Value']}');
        },
      ),
    );

    _nodeEditorController.registerNodePrototype(
      NodePrototype(
        name: 'Round',
        description: 'Rounds a number to a specified number of decimals.',
        ports: [
          InputPortPrototype(name: 'Value', dataType: double),
          OutputPortPrototype(name: 'Rounded', dataType: int),
        ],
        fields: [
          FieldPrototype(
            name: 'Decimals',
            dataType: int,
            defaultData: 2,
            visualizerBuilder: (data) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                spacing: 4,
                children: [
                  Text(
                    data.toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            editorBuilder: (context, removeOverlay, data, setData) => Container(
              constraints: const BoxConstraints(
                minHeight: 20,
                minWidth: 50,
                maxWidth: 200,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(128),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                initialValue: data.toString(),
                onChanged: (value) => setData(
                  int.tryParse(value) ?? 0,
                  eventType: FieldEventType.change,
                ),
                onFieldSubmitted: (value) {
                  setData(
                    int.tryParse(value) ?? 0,
                    eventType: FieldEventType.submit,
                  );
                  removeOverlay.call();
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(4),
                ),
              ),
            ),
          ),
        ],
        onExecute: (ports, fields) {
          final double value = ports['Value'] as double;
          final int decimals = fields['Decimals'] as int;

          ports['Rounded'] = double.parse(value.toStringAsFixed(decimals));
        },
      ),
    );
  }

  @override
  void dispose() {
    _nodeEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FlHierarchyWidget(
              controller: _nodeEditorController,
              style: const FlHierarchyStyle(),
            ),
            Expanded(
              child: FlNodeEditorWidget(
                controller: _nodeEditorController,
                expandToParent: true,
                style: const FlNodeEditorStyle(
                  gridStyle: FlGridStyle(
                    lineWidth: 1,
                    intersectionRadius: 2,
                  ),
                ),
                overlay: () {
                  return [
                    FlOverlayData(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: FlSearchWidget(
                          controller: _nodeEditorController,
                          style: const FlSearchStyle(),
                        ),
                      ),
                    ),
                    FlOverlayData(
                      top: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _nodeEditorController.runner.executeGraph(),
                            icon: const Icon(
                              Icons.play_arrow,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    FlOverlayData(
                      bottom: 0,
                      left: 0,
                      child: const Opacity(
                        opacity: 0.5,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mouse Commands:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(' - Left Click: Select Node'),
                              Text(' - Right Click: Open Context Menu'),
                              Text(' - Scroll: Zoom In/Out'),
                              Text(' - Middle Click: Pan'),
                              SizedBox(height: 8),
                              Text(
                                'Keyboard Commands:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(' - Ctrl + S: Save Project'),
                              Text(' - Ctrl + O: Open Project'),
                              Text(' - Ctrl + N: New Project'),
                              Text(' - Ctrl + C: Copy Node'),
                              Text(' - Ctrl + V: Paste Node'),
                              Text(' - Ctrl + X: Cut Node'),
                              Text(' - Delete | Backspace: Remove Node'),
                              Text(' - Ctrl + Z: Undo'),
                              Text(' - Ctrl + Y: Redo'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
