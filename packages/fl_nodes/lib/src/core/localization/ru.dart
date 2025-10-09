import 'package:fl_nodes/src/core/localization/delegate.dart';

class FlNodeEditorLocalizationsRu extends FlNodeEditorLocalizations {
  FlNodeEditorLocalizationsRu(super.locale);

  @override
  String get closeAction => "Закрыть";
  @override
  String get addNodeAction => "Добавить";
  @override
  String get deleteNodeAction => "Удалить";
  @override
  String get centerViewAction => "Центрировать вид";
  @override
  String get resetZoomAction => "Сбросить масштаб";
  @override
  String get createNodeAction => "Создать";
  @override
  String get copySelectionAction => "Копировать";
  @override
  String get pasteSelectionAction => "Вставить";
  @override
  String get cutSelectionAction => "Вырезать";
  @override
  String get projectLabel => "Проект";
  @override
  String get undoAction => "Отменить";
  @override
  String get redoAction => "Повторить";
  @override
  String get newProjectAction => "Новый проект";
  @override
  String get saveProjectAction => "Сохранить";
  @override
  String get openProjectAction => "Открыть";
  @override
  String get seeNodeDescriptionAction => "Просмотреть описание";
  @override
  String get collapseNodeAction => "Свернуть";
  @override
  String get expandNodeAction => "Развернуть";
  @override
  String get cutLinksAction => "Разорвать связи";
  @override
  String get editorMenuLabel => "Меню редактора";
  @override
  String get nodeMenuLabel => "Меню узла";
  @override
  String get portMenuLabel => "Меню порта";
  @override
  String get linkMenuLabel => "Меню ссылки";
  @override
  String get deleteLinkAction => "Удалить связь";
  @override
  String get navigateToSourceAction => "Перейти к источнику";
  @override
  String get navigateToDestinationAction => "Перейти к назначению";
  @override
  String failedToCopySelectionErrorMsg(String e) =>
      "Не удалось скопировать выделение: $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "Выделение успешно скопировано";
  @override
  String failedToPasteSelectionErrorMsg(String e) =>
      "Не удалось вставить выделение: $e";
  @override
  String failedToSaveProjectErrorMsg(String e) =>
      "Не удалось сохранить проект: $e";
  @override
  String get projectSavedSuccessfullyMsg => "Проект успешно сохранён";
  @override
  String failedToLoadProjectErrorMsg(String e) =>
      "Не удалось загрузить проект: $e";
  @override
  String get projectLoadedSuccessfullyMsg => "Проект успешно загружен";
  @override
  String get newProjectCreatedSuccessfullyMsg => "Новый проект успешно создан";
  @override
  String failedToExecuteNodeErrorMsg(String e) =>
      "Не удалось выполнить узел: $e";
}
