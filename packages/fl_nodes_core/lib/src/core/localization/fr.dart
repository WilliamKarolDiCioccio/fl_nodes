import 'delegate.dart';

class FlNodesLocalizationsFr extends FlNodesLocalizations {
  FlNodesLocalizationsFr(super.locale);

  @override
  String get closeAction => "Fermer";
  @override
  String get addNodeAction => "Ajouter";
  @override
  String get deleteNodeAction => "Supprimer";
  @override
  String get centerViewAction => "Centrer la vue";
  @override
  String get resetZoomAction => "Réinitialiser le zoom";
  @override
  String get createNodeAction => "Créer";
  @override
  String get copySelectionAction => "Copier";
  @override
  String get pasteSelectionAction => "Coller";
  @override
  String get cutSelectionAction => "Couper";
  @override
  String get projectLabel => "Projet";
  @override
  String get undoAction => "Annuler";
  @override
  String get redoAction => "Rétablir";
  @override
  String get newProjectAction => "Nouveau projet";
  @override
  String get saveProjectAction => "Enregistrer";
  @override
  String get openProjectAction => "Ouvrir";
  @override
  String get seeNodeDescriptionAction => "Voir la description";
  @override
  String get collapseNodeAction => "Réduire";
  @override
  String get expandNodeAction => "Développer";
  @override
  String get cutLinksAction => "Couper les liens";
  @override
  String get editorMenuLabel => "Menu éditeur";
  @override
  String get nodeMenuLabel => "Menu nœud";
  @override
  String get linkMenuLabel => "Menu lien";
  @override
  String get deleteLinkAction => "Supprimer le lien";
  @override
  String get navigateToSourceAction => "Aller à la source";
  @override
  String get navigateToDestinationAction => "Aller à la destination";
  @override
  String get portMenuLabel => "Menu port";
  @override
  String failedToCopySelectionErrorMsg(String e) =>
      "Échec de la copie de la sélection : $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "Sélection copiée avec succès";
  @override
  String failedToPasteSelectionErrorMsg(String e) =>
      "Échec du collage de la sélection : $e";
  @override
  String failedToSaveProjectErrorMsg(String e) =>
      "Échec de l’enregistrement du projet : $e";
  @override
  String get projectSavedSuccessfullyMsg => "Projet enregistré avec succès";
  @override
  String failedToLoadProjectErrorMsg(String e) =>
      "Échec du chargement du projet : $e";
  @override
  String get projectLoadedSuccessfullyMsg => "Projet chargé avec succès";
  @override
  String get newProjectCreatedSuccessfullyMsg =>
      "Nouveau projet créé avec succès";
  @override
  String failedToExecuteNodeErrorMsg(String e) =>
      "Échec de l’exécution du nœud : $e";
}
