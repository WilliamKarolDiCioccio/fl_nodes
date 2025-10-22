import 'delegate.dart';

class FlNodesLocalizationsDe extends FlNodesLocalizations {
  FlNodesLocalizationsDe(super.locale);

  @override
  String get closeAction => "Schließen";
  @override
  String get addNodeAction => "Hinzufügen";
  @override
  String get deleteNodeAction => "Löschen";
  @override
  String get centerViewAction => "Ansicht zentrieren";
  @override
  String get resetZoomAction => "Zoom zurücksetzen";
  @override
  String get createNodeAction => "Erstellen";
  @override
  String get copySelectionAction => "Kopieren";
  @override
  String get pasteSelectionAction => "Einfügen";
  @override
  String get cutSelectionAction => "Ausschneiden";
  @override
  String get projectLabel => "Projekt";
  @override
  String get undoAction => "Rückgängig";
  @override
  String get redoAction => "Wiederholen";
  @override
  String get newProjectAction => "Neues Projekt";
  @override
  String get saveProjectAction => "Speichern";
  @override
  String get openProjectAction => "Öffnen";
  @override
  String get seeNodeDescriptionAction => "Beschreibung anzeigen";
  @override
  String get collapseNodeAction => "Einklappen";
  @override
  String get expandNodeAction => "Ausklappen";
  @override
  String get cutLinksAction => "Verbindungen trennen";
  @override
  String get editorMenuLabel => "Editor-Menü";
  @override
  String get nodeMenuLabel => "Knoten-Menü";
  @override
  String get portMenuLabel => "Port-Menü";
  @override
  String get linkMenuLabel => "Link-Menü";
  @override
  String get deleteLinkAction => "Link löschen";
  @override
  String get navigateToSourceAction => "Zur Quelle navigieren";
  @override
  String get navigateToDestinationAction => "Zur Destination navigieren";
  @override
  String failedToCopySelectionErrorMsg(String e) =>
      "Auswahl konnte nicht kopiert werden: $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "Auswahl erfolgreich kopiert";
  @override
  String failedToPasteSelectionErrorMsg(String e) =>
      "Auswahl konnte nicht eingefügt werden: $e";
  @override
  String failedToSaveProjectErrorMsg(String e) =>
      "Projekt konnte nicht gespeichert werden: $e";
  @override
  String get projectSavedSuccessfullyMsg => "Projekt erfolgreich gespeichert";
  @override
  String failedToLoadProjectErrorMsg(String e) =>
      "Projekt konnte nicht geladen werden: $e";
  @override
  String get projectLoadedSuccessfullyMsg => "Projekt erfolgreich geladen";
  @override
  String get newProjectCreatedSuccessfullyMsg =>
      "Neues Projekt erfolgreich erstellt";
  @override
  String failedToExecuteNodeErrorMsg(String e) =>
      "Knoten konnte nicht ausgeführt werden: $e";
}
