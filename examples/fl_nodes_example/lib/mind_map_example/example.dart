import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes_example/l10n/app_localizations.dart';
import 'package:fl_nodes_example/mind_map_example/nodes/prototypes/prototypes.dart';
import 'package:fl_nodes_example/mind_map_example/nodes/widgets/mind_map_node.dart';
import 'package:fl_nodes_example/models/locale.dart';
import 'package:fl_nodes_example/utils/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MindMapExampleScreen extends StatefulWidget {
  const MindMapExampleScreen({
    super.key,
    required this.locales,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final List<LocaleDataModel> locales;
  final Locale currentLocale;
  final Function(String) onLocaleChanged;

  @override
  State<MindMapExampleScreen> createState() => MindMapExampleScreenState();
}

final bool isMobile =
    TargetPlatform.iOS == defaultTargetPlatform ||
        TargetPlatform.android == defaultTargetPlatform
    ? true
    : false;

class MindMapExampleScreenState extends State<MindMapExampleScreen> {
  late final FlNodesController _controller;

  @override
  void initState() {
    super.initState();

    _controller = FlNodesController(
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

    _controller.overlay.add(
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

    registerNodes(context, _controller);

    _addSampleNodes();
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

  Future<void> _addSampleNodes() async {
    _controller.project.clear();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlNodesShortcutsWidget(
        controller: _controller,
        child: FlNodesWidget(
          controller: _controller,
          expandToParent: true,
          nodeBuilder: (node, controller) =>
              MindMapNodeWidget(node: node, controller: controller),
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
                onPressed: () => _controller.project.create(context: context),
              ),
              _buildToolbarButton(
                icon: Icons.folder_open,
                tooltip: strings.openProjectActionTooltip,
                onPressed: () => _controller.project.load(context: context),
              ),
              _buildToolbarButton(
                icon: Icons.save,
                tooltip: strings.saveProjectActionTooltip,
                onPressed: () => _controller.project.save(context: context),
              ),
              _buildToolbarButton(
                icon: Icons.undo,
                tooltip: strings.undoActionTooltip,
                onPressed: () => _controller.history.undo(),
              ),
              _buildToolbarButton(
                icon: Icons.redo,
                tooltip: strings.redoActionTooltip,
                onPressed: () => _controller.history.redo(),
              ),
              _buildToolbarButton(
                icon: _controller.config.enableSnapToGrid
                    ? Icons.grid_on
                    : Icons.grid_off,
                tooltip: AppLocalizations.of(context)!.toggleSnapToGridTooltip,
                onPressed: () => setState(() {
                  _controller.enableSnapToGrid(
                    !_controller.config.enableSnapToGrid,
                  );
                }),
              ),
              _buildToolbarButton(
                icon: Icons.play_arrow,
                tooltip: AppLocalizations.of(context)!.executeGraphTooltip,
                onPressed: () =>
                    _controller.runner.executeGraph(context: context),
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
