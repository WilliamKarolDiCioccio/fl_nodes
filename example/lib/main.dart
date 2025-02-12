import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:example/data_handlers.dart';
import 'package:example/nodes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:os_detect/os_detect.dart' as os_detect;
import 'package:universal_html/html.dart' as universal_html;

import 'package:fl_nodes/fl_nodes.dart';

import './widgets/hierarchy.dart';
import './widgets/search.dart';

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

  bool isHierarchyCollapsed = true;

  @override
  void initState() {
    super.initState();

    _nodeEditorController = FlNodeEditorController(
      projectSaver: (jsonData) async {
        if (kIsWeb) return false;

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
        if (kIsWeb) return false;

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

    registerDataHandlers(_nodeEditorController);
    registerNodes(context, _nodeEditorController);

    const sampleProjectLink =
        'https://raw.githubusercontent.com/WilliamKarolDiCioccio/fl_nodes/refs/heads/main/example/assets/www/node_project.json';

    () async {
      _nodeEditorController.project.load(
        data: jsonDecode(
          await universal_html.HttpRequest.getString(sampleProjectLink),
        ),
      );
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

      if (os_detect.isBrowser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Currently our example code depends on https://pub.dev/packages/file_picker so you won't be able to save files on the web",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (os_detect.isAndroid || os_detect.isIOS) {
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
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () {
                                switch (_nodeEditorController
                                    .style.nodeStyle.linkStyle.curveType) {
                                  case FlLinkCurveType.straight:
                                    _nodeEditorController.setLinkCurveType(
                                      FlLinkCurveType.bezier,
                                    );
                                    break;
                                  case FlLinkCurveType.bezier:
                                    _nodeEditorController.setLinkCurveType(
                                      FlLinkCurveType.ninetyDegree,
                                    );
                                    break;
                                  case FlLinkCurveType.ninetyDegree:
                                    _nodeEditorController.setLinkCurveType(
                                      FlLinkCurveType.straight,
                                    );
                                    break;
                                }
                              },
                              icon: const Icon(
                                Icons.draw,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            IconButton.filled(
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
                              Text(' - (Ctrl/Cmd) + S: Save Project'),
                              Text(' - (Ctrl/Cmd) + O: Open Project'),
                              Text(' - (Ctrl/Cmd) + Shift + N: New Project'),
                              Text(' - (Ctrl/Cmd) + C: Copy Node'),
                              Text(' - (Ctrl/Cmd) + V: Paste Node'),
                              Text(' - (Ctrl/Cmd) + X: Cut Node'),
                              Text(' - Delete | Backspace: Remove Nodes'),
                              Text(' - (Ctrl/Cmd) + Z: Undo'),
                              Text(' - (Ctrl/Cmd) + Y: Redo'),
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
