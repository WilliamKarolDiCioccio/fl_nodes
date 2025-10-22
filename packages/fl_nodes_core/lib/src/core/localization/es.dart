import 'delegate.dart';

class FlNodesLocalizationsEs extends FlNodesLocalizations {
  FlNodesLocalizationsEs(super.locale);

  @override
  String get closeAction => "Cerrar";
  @override
  String get addNodeAction => "Añadir";
  @override
  String get deleteNodeAction => "Eliminar";
  @override
  String get centerViewAction => "Centrar vista";
  @override
  String get resetZoomAction => "Restablecer zoom";
  @override
  String get createNodeAction => "Crear";
  @override
  String get copySelectionAction => "Copiar";
  @override
  String get pasteSelectionAction => "Pegar";
  @override
  String get cutSelectionAction => "Cortar";
  @override
  String get projectLabel => "Proyecto";
  @override
  String get undoAction => "Deshacer";
  @override
  String get redoAction => "Rehacer";
  @override
  String get newProjectAction => "Nuevo proyecto";
  @override
  String get saveProjectAction => "Guardar";
  @override
  String get openProjectAction => "Abrir";
  @override
  String get seeNodeDescriptionAction => "Ver descripción";
  @override
  String get collapseNodeAction => "Contraer";
  @override
  String get expandNodeAction => "Expandir";
  @override
  String get cutLinksAction => "Cortar enlaces";
  @override
  String get editorMenuLabel => "Menú del editor";
  @override
  String get nodeMenuLabel => "Menú del nodo";
  @override
  String get portMenuLabel => "Menú del puerto";
  @override
  String get linkMenuLabel => "Menú del enlace";
  @override
  String get deleteLinkAction => "Eliminar enlace";
  @override
  String get navigateToSourceAction => "Navegar a la fuente";
  @override
  String get navigateToDestinationAction => "Navegar al destino";
  @override
  String failedToCopySelectionErrorMsg(String e) =>
      "Error al copiar la selección: $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "Selección copiada con éxito";
  @override
  String failedToPasteSelectionErrorMsg(String e) =>
      "Error al pegar la selección: $e";
  @override
  String failedToSaveProjectErrorMsg(String e) =>
      "Error al guardar el proyecto: $e";
  @override
  String get projectSavedSuccessfullyMsg => "Proyecto guardado con éxito";
  @override
  String failedToLoadProjectErrorMsg(String e) =>
      "Error al cargar el proyecto: $e";
  @override
  String get projectLoadedSuccessfullyMsg => "Proyecto cargado con éxito";
  @override
  String get newProjectCreatedSuccessfullyMsg =>
      "Nuevo proyecto creado con éxito";
  @override
  String failedToExecuteNodeErrorMsg(String e) =>
      "Error al ejecutar el nodo: $e";
}
