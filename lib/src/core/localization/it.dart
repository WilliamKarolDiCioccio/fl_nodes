import 'package:fl_nodes/src/core/localization/delegate.dart';

class FlNodeEditorLocalizationsIt extends FlNodeEditorLocalizations {
  FlNodeEditorLocalizationsIt(super.locale);

  @override
  String get closeAction => "Chiudi";
  @override
  String get addNodeAction => "Aggiungi";
  @override
  String get deleteNodeAction => "Elimina";
  @override
  String get centerViewAction => "Centra Vista";
  @override
  String get resetZoomAction => "Reimposta Zoom";
  @override
  String get createNodeAction => "Crea";
  @override
  String get copySelectionAction => "Copia";
  @override
  String get pasteSelectionAction => "Incolla";
  @override
  String get cutSelectionAction => "Taglia";
  @override
  String get projectLabel => "Progetto";
  @override
  String get undoAction => "Annulla";
  @override
  String get redoAction => "Ripeti";
  @override
  String get newProjectAction => "Nuovo Progetto";
  @override
  String get saveProjectAction => "Salva";
  @override
  String get openProjectAction => "Apri";
  @override
  String get seeNodeDescriptionAction => "Vedi Descrizione";
  @override
  String get collapseNodeAction => "Comprimi";
  @override
  String get expandNodeAction => "Espandi";
  @override
  String get cutLinksAction => "Taglia Collegamenti";
  @override
  String get editorMenuLabel => "Menu Editor";
  @override
  String get nodeMenuLabel => "Menu Nodo";
  @override
  String get portMenuLabel => "Menu Porta";
  @override
  String failedToCopySelectionErrorMsg(String e) =>
      "Impossibile copiare la selezione: $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "Selezione copiata con successo";
  @override
  String failedToPasteSelectionErrorMsg(String e) =>
      "Impossibile incollare la selezione: $e";
  @override
  String failedToSaveProjectErrorMsg(String e) =>
      "Impossibile salvare il progetto: $e";
  @override
  String get projectSavedSuccessfullyMsg => "Progetto salvato con successo";
  @override
  String failedToLoadProjectErrorMsg(String e) =>
      "Impossibile caricare il progetto: $e";
  @override
  String get projectLoadedSuccessfullyMsg => "Progetto caricato con successo";
  @override
  String get newProjectCreatedSuccessfullyMsg =>
      "Nuovo progetto creato con successo";
  @override
  String failedToExecuteNodeErrorMsg(String e) =>
      "Impossibile eseguire il nodo: $e";
}
