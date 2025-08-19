import 'package:fl_nodes/src/core/localization/delegate.dart';

class FlNodeEditorLocalizationsEn extends FlNodeEditorLocalizations {
  FlNodeEditorLocalizationsEn(super.locale);

  @override
  String get closeAction => "Close";
  @override
  String get addNodeAction => "Add";
  @override
  String get deleteNodeAction => "Delete";
  @override
  String get centerViewAction => "Center View";
  @override
  String get resetZoomAction => "Reset Zoom";
  @override
  String get createNodeAction => "Create";
  @override
  String get copySelectionAction => "Copy";
  @override
  String get pasteSelectionAction => "Paste";
  @override
  String get cutSelectionAction => "Cut";
  @override
  String get projectLabel => "Project";
  @override
  String get undoAction => "Undo";
  @override
  String get redoAction => "Redo";
  @override
  String get newProjectAction => "New Project";
  @override
  String get saveProjectAction => "Save";
  @override
  String get openProjectAction => "Open";
  @override
  String get seeNodeDescriptionAction => "See Description";
  @override
  String get collapseNodeAction => "Collapse";
  @override
  String get expandNodeAction => "Expand";
  @override
  String get cutLinksAction => "Cut Links";
  @override
  String get editorMenuLabel => "Editor Menu";
  @override
  String get nodeMenuLabel => "Node Menu";
  @override
  String get portMenuLabel => "Port Menu";
  @override
  String failedToCopySelectionErrorMsg(String e) =>
      "Failed to copy selection: $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "Selection copied successfully";
  @override
  String failedToPasteSelectionErrorMsg(String e) =>
      "Failed to paste selection: $e";
  @override
  String failedToSaveProjectErrorMsg(String e) => "Failed to save project: $e";
  @override
  String get projectSavedSuccessfullyMsg => "Project saved successfully";
  @override
  String failedToLoadProjectErrorMsg(String e) => "Failed to load project: $e";
  @override
  String get projectLoadedSuccessfullyMsg => "Project loaded successfully";
  @override
  String get newProjectCreatedSuccessfullyMsg =>
      "New project created successfully";
  @override
  String failedToExecuteNodeErrorMsg(String e) => "Failed to execute node: $e";
}
