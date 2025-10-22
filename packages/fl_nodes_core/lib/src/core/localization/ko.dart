import 'delegate.dart';

class FlNodesLocalizationsKo extends FlNodesLocalizations {
  FlNodesLocalizationsKo(super.locale);

  @override
  String get closeAction => "닫기";
  @override
  String get addNodeAction => "추가";
  @override
  String get deleteNodeAction => "삭제";
  @override
  String get centerViewAction => "화면 중앙으로";
  @override
  String get resetZoomAction => "확대/축소 초기화";
  @override
  String get createNodeAction => "생성";
  @override
  String get copySelectionAction => "복사";
  @override
  String get pasteSelectionAction => "붙여넣기";
  @override
  String get cutSelectionAction => "잘라내기";
  @override
  String get projectLabel => "프로젝트";
  @override
  String get undoAction => "실행 취소";
  @override
  String get redoAction => "다시 실행";
  @override
  String get newProjectAction => "새 프로젝트";
  @override
  String get saveProjectAction => "저장";
  @override
  String get openProjectAction => "열기";
  @override
  String get seeNodeDescriptionAction => "설명 보기";
  @override
  String get collapseNodeAction => "접기";
  @override
  String get expandNodeAction => "펼치기";
  @override
  String get cutLinksAction => "링크 끊기";
  @override
  String get editorMenuLabel => "편집기 메뉴";
  @override
  String get nodeMenuLabel => "노드 메뉴";
  @override
  String get portMenuLabel => "포트 메뉴";
  @override
  String get linkMenuLabel => "링크 메뉴";
  @override
  String get deleteLinkAction => "링크 삭제";
  @override
  String get navigateToSourceAction => "소스으로 이동";
  @override
  String get navigateToDestinationAction => "대상으로 이동";
  @override
  String failedToCopySelectionErrorMsg(String e) => "선택 항목 복사 실패: $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "선택 항목이 성공적으로 복사되었습니다";
  @override
  String failedToPasteSelectionErrorMsg(String e) => "선택 항목 붙여넣기 실패: $e";
  @override
  String failedToSaveProjectErrorMsg(String e) => "프로젝트 저장 실패: $e";
  @override
  String get projectSavedSuccessfullyMsg => "프로젝트가 성공적으로 저장되었습니다";
  @override
  String failedToLoadProjectErrorMsg(String e) => "프로젝트 불러오기 실패: $e";
  @override
  String get projectLoadedSuccessfullyMsg => "프로젝트가 성공적으로 불러와졌습니다";
  @override
  String get newProjectCreatedSuccessfullyMsg => "새 프로젝트가 성공적으로 생성되었습니다";
  @override
  String failedToExecuteNodeErrorMsg(String e) => "노드 실행 실패: $e";
}
