import 'dart:convert';
import 'dart:io';

import 'package:example/l10n/app_localizations.dart';
import 'package:example/models/locale.dart';
import 'package:example/utils/snackbar.dart';
import 'package:example/visual_scripting_example/nodes/data/handlers.dart';
import 'package:example/visual_scripting_example/nodes/prototypes/prototypes.dart';
import 'package:example/visual_scripting_example/widgets/hierarchy.dart';
import 'package:example/visual_scripting_example/widgets/instructions.dart';
import 'package:example/visual_scripting_example/widgets/settings.dart';
import 'package:example/visual_scripting_example/widgets/terminal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VisualScriptingExampleScreen extends StatefulWidget {
  const VisualScriptingExampleScreen({
    super.key,
    required this.locales,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final List<LocaleDataModel> locales;
  final Locale currentLocale;
  final Function(String) onLocaleChanged;

  @override
  State<VisualScriptingExampleScreen> createState() =>
      VisualScriptingExampleScreenState();
}

final bool isMobile =
    TargetPlatform.iOS == defaultTargetPlatform ||
        TargetPlatform.android == defaultTargetPlatform
    ? true
    : false;

class VisualScriptingExampleScreenState
    extends State<VisualScriptingExampleScreen> {
  late final FlNodesController _nodeEditorController;
  final TerminalController _terminalController = TerminalController();

  bool isHierarchyCollapsed = isMobile ? true : false;
  bool isHierarchyFullyCollapsed = isMobile ? true : false;
  bool isTerminalCollapsed = isMobile ? true : false;
  bool isTerminalFullyCollapsed = isMobile ? true : false;

  void _toggleHierarchy() {
    setState(() {
      isHierarchyCollapsed = !isHierarchyCollapsed;
    });
  }

  void _toggleTerminal() {
    setState(() {
      isTerminalCollapsed = !isTerminalCollapsed;
    });
  }

  @override
  void initState() {
    super.initState();

    _nodeEditorController = FlNodesController(
      appVersion: '0.0.1',
      projectSaver: (jsonData) async {
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context)!.saveProjectDialogTitle,
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
          final bool? proceed = await _showUnsavedChangesDialog();
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
        return await _showUnsavedChangesDialog() == true;
      },
      onCallback: (type, message) =>
          showNodeEditorSnackbar(context, message, type),
    );

    _nodeEditorController.overlay.add(
      'top_toolbar',
      data: FlOverlayData(
        builder: (context, data) => _buildTopToolbar(),
        top: 16,
        left: 16,
        right: 16,
        isVisible: true,
        opacity: 1.0,
      ),
    );

    registerDataHandlers(_nodeEditorController);
    registerNodes(context, _nodeEditorController);

    _loadSampleProject();
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.unsavedChangesTitle),
          content: Text(AppLocalizations.of(context)!.unsavedChangesMsg),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.proceed),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadSampleProject() async {
    const sampleProjectLink =
        'https://raw.githubusercontent.com/WilliamKarolDiCioccio/fl_nodes/refs/heads/main/example/assets/www/node_project.json';

    try {
      final response = await http.get(Uri.parse(sampleProjectLink));

      if (response.statusCode == 200 && mounted) {
        _nodeEditorController.project.load(
          data: jsonDecode(response.body),
          context: context,
        );
      } else {
        if (!mounted) return;
        showNodeEditorSnackbar(
          context,
          AppLocalizations.of(context)!.failedToLoadSampleProject,
          FlCallbackType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showNodeEditorSnackbar(
        context,
        AppLocalizations.of(context)!.failedToLoadSampleProject,
        FlCallbackType.error,
      );
    }
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsPanel(
        locales: widget.locales,
        currentLocale: widget.currentLocale,
        onLocaleChanged: widget.onLocaleChanged,
        controller: _nodeEditorController,
      ),
    );
  }

  void _showInstructionsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const InstructionsPanel(),
    );
  }

  Future<void> _launchGitHub() async {
    const url = 'https://github.com/WilliamKarolDiCioccio/fl_nodes';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      showNodeEditorSnackbar(
        context,
        'Could not launch GitHub',
        FlCallbackType.error,
      );
    }
  }

  @override
  void dispose() {
    _nodeEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlNodesShortcutsWidget(
        controller: _nodeEditorController,
        child: Row(
          children: [
            ClipRect(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: isHierarchyCollapsed ? 1.0 : 0.0,
                  end: isHierarchyCollapsed ? 0.0 : 1.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                onEnd: () {
                  setState(() {
                    isHierarchyFullyCollapsed = isHierarchyCollapsed;
                  });
                },
                builder: (context, widthFactor, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor.clamp(0.0, 1.0),
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 300,
                  child: HierarchyWidget(
                    controller: _nodeEditorController,
                    isCollapsed: isHierarchyFullyCollapsed,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: FlNodesWidget(
                      controller: _nodeEditorController,
                      expandToParent: true,
                      nodeBuilder: (node, controller) => FlDefaultNodeWidget(
                        node: node,
                        controller: controller,
                      ),
                    ),
                  ),
                  ClipRect(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: isTerminalCollapsed ? 1.0 : 0.0,
                        end: isTerminalCollapsed ? 0.0 : 1.0,
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      onEnd: () {
                        setState(() {
                          isTerminalFullyCollapsed = isTerminalCollapsed;
                        });
                      },
                      builder: (context, heightFactor, child) {
                        return Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: heightFactor.clamp(0.0, 1.0),
                          child: child,
                        );
                      },
                      child: SizedBox(
                        height: 400,
                        child: TerminalWidget(
                          controller: _terminalController,
                          isCollapsed: isTerminalFullyCollapsed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    final strings = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 16,
        children: [
          // Hierarchy controls
          _buildToobarSection(
            children: [
              _buildToolbarButton(
                icon: isHierarchyCollapsed ? Icons.menu_open : Icons.menu,
                tooltip: AppLocalizations.of(context)!.toggleHierarchyTooltip,
                onPressed: _toggleHierarchy,
              ),
              _buildToolbarButton(
                icon: isTerminalCollapsed
                    ? Icons.terminal
                    : Icons.terminal_outlined,
                tooltip: AppLocalizations.of(context)!.toggleTerminalTooltip,
                onPressed: _toggleTerminal,
              ),
            ],
          ),
          // Editor controls
          _buildToobarSection(
            children: [
              _buildToolbarButton(
                icon: Icons.home,
                tooltip: strings.goHomeProjectActionTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
              _buildToolbarButton(
                icon: Icons.add,
                tooltip: strings.createProjectActionTooltip,
                onPressed: () =>
                    _nodeEditorController.project.create(context: context),
              ),
              _buildToolbarButton(
                icon: Icons.folder_open,
                tooltip: strings.openProjectActionTooltip,
                onPressed: () =>
                    _nodeEditorController.project.load(context: context),
              ),
              _buildToolbarButton(
                icon: Icons.save,
                tooltip: strings.saveProjectActionTooltip,
                onPressed: () =>
                    _nodeEditorController.project.save(context: context),
              ),
              _buildToolbarButton(
                icon: Icons.undo,
                tooltip: strings.undoActionTooltip,
                onPressed: () => _nodeEditorController.history.undo(),
              ),
              _buildToolbarButton(
                icon: Icons.redo,
                tooltip: strings.redoActionTooltip,
                onPressed: () => _nodeEditorController.history.redo(),
              ),
              _buildToolbarButton(
                icon: _nodeEditorController.config.enableSnapToGrid
                    ? Icons.grid_on
                    : Icons.grid_off,
                tooltip: AppLocalizations.of(context)!.toggleSnapToGridTooltip,
                onPressed: () => setState(() {
                  _nodeEditorController.enableSnapToGrid(
                    !_nodeEditorController.config.enableSnapToGrid,
                  );
                }),
              ),
              _buildToolbarButton(
                icon: Icons.play_arrow,
                tooltip: AppLocalizations.of(context)!.executeGraphTooltip,
                onPressed: () =>
                    _nodeEditorController.runner.executeGraph(context: context),
                color: Colors.green,
              ),
            ],
          ),
          const Spacer(),
          // Miscellaneous
          _buildToobarSection(
            children: [
              _buildToolbarButton(
                icon: Icons.star_border,
                tooltip: strings.starOnGitHubTooltip,
                onPressed: _launchGitHub,
                color: Colors.amber,
              ),
              _buildToolbarButton(
                icon: Icons.settings,
                tooltip: strings.settingsTooltip,
                onPressed: _showSettingsPanel,
              ),
              _buildToolbarButton(
                icon: Icons.help_outline,
                tooltip: strings.instructionsTooltip,
                onPressed: _showInstructionsPanel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToobarSection({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: children,
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
