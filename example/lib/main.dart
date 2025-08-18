import 'dart:convert';
import 'dart:io';

import 'package:example/data_handlers.dart';
import 'package:example/nodes.dart';
import 'package:example/utils/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

import './widgets/hierarchy.dart';
import './widgets/search.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  bool isHierarchyCollapsed = true;

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
          bytes: utf8.encode(jsonEncode(jsonData)),
        );

        if (outputPath != null || kIsWeb) {
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

        late final String fileContent;

        if (kIsWeb) {
          final byteData = result.files.single.bytes!;
          fileContent = utf8.decode(byteData.buffer.asUint8List());
        } else {
          final File file = File(result.files.single.path!);
          fileContent = await file.readAsString();
        }

        return jsonDecode(fileContent);
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
      onCallback: (type, message) =>
          showNodeEditorSnackbar(context, message, type),
    );

    registerDataHandlers(_nodeEditorController);
    registerNodes(context, _nodeEditorController);

    const sampleProjectLink =
        'https://raw.githubusercontent.com/WilliamKarolDiCioccio/fl_nodes/refs/heads/main/example/assets/www/node_project.json';

    () async {
      final response = await http.get(Uri.parse(sampleProjectLink));
      if (response.statusCode == 200) {
        _nodeEditorController.project.load(
          data: jsonDecode(response.body),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load sample project. Please check your internet connection.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Welcome to FlNodes live example! Keep in mind that this is a work in progress and some features may not work as expected.",
          ),
          backgroundColor: Colors.blue,
        ),
      );

      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This example is not optimized for mobile devices. Please use a desktop browser for the best experience.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nodeEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comboKey =
        defaultTargetPlatform == TargetPlatform.macOS ? "Meta" : "Ctrl";

    return Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            HierarchyWidget(
              controller: _nodeEditorController,
              isCollapsed: isHierarchyCollapsed,
            ),
            Expanded(
              child: FlNodeEditorWidget(
                controller: _nodeEditorController,
                expandToParent: true,
                overlay: () {
                  return [
                    FlOverlayData(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          spacing: 8,
                          children: [
                            IconButton.filled(
                              tooltip: 'Toggle Hierarchy Panel',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () => setState(() {
                                isHierarchyCollapsed = !isHierarchyCollapsed;
                              }),
                              icon: Icon(
                                isHierarchyCollapsed
                                    ? Icons.keyboard_arrow_right
                                    : Icons.keyboard_arrow_left,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            SearchWidget(controller: _nodeEditorController),
                            const Spacer(),
                            IconButton.filled(
                              tooltip: 'Toggle Snap to Grid',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () => setState(() {
                                _nodeEditorController.enableSnapToGrid(
                                  !_nodeEditorController
                                      .config.enableSnapToGrid,
                                );
                              }),
                              icon: Icon(
                                _nodeEditorController.config.enableSnapToGrid
                                    ? Icons.grid_on
                                    : Icons.grid_off,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            IconButton.filled(
                              tooltip: 'Execute Graph',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () =>
                                  _nodeEditorController.runner.executeGraph(),
                              icon: const Icon(
                                Icons.play_arrow,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FlOverlayData(
                      bottom: 0,
                      left: 0,
                      child: Opacity(
                        opacity: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: defaultTargetPlatform ==
                                      TargetPlatform.android ||
                                  defaultTargetPlatform == TargetPlatform.iOS
                              ? const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Touch Commands:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('- Tap: Select Node'),
                                    Text('- Double Tap: Clear Selection'),
                                    Text('- Long Press: Open Context Menu'),
                                    Text(
                                      '- Drag: Start Linking / Select Nodes',
                                    ),
                                    Text('- Pinch: Zoom In/Out'),
                                    SizedBox(height: 8),
                                    Text(
                                      'Additional Gestures:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('- Two-Finger Drag: Pan'),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mouse Commands:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      '- Left Click: Select Node/Link',
                                    ),
                                    const Text(
                                      '- Right Click: Open Context Menu',
                                    ),
                                    const Text('- Scroll: Zoom In/Out'),
                                    const Text('- Middle Click: Pan'),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Keyboard Commands:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('- $comboKey + S: Save Project'),
                                    Text('- $comboKey + O: Open Project'),
                                    Text(
                                      '- $comboKey + Shift + N: New Project',
                                    ),
                                    Text('- $comboKey + C: Copy Node'),
                                    Text('- $comboKey + V: Paste Node'),
                                    Text('- $comboKey + X: Cut Node'),
                                    const Text(
                                      '- Delete | Backspace: Remove Node',
                                    ),
                                    Text('- $comboKey + Z: Undo'),
                                    Text('- $comboKey + Y: Redo'),
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
