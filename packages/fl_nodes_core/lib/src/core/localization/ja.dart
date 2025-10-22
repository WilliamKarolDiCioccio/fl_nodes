import 'delegate.dart';

class FlNodesLocalizationsJa extends FlNodesLocalizations {
  FlNodesLocalizationsJa(super.locale);

  @override
  String get closeAction => "閉じる";
  @override
  String get addNodeAction => "追加";
  @override
  String get deleteNodeAction => "削除";
  @override
  String get centerViewAction => "ビューを中央に";
  @override
  String get resetZoomAction => "ズームをリセット";
  @override
  String get createNodeAction => "作成";
  @override
  String get copySelectionAction => "コピー";
  @override
  String get pasteSelectionAction => "貼り付け";
  @override
  String get cutSelectionAction => "切り取り";
  @override
  String get projectLabel => "プロジェクト";
  @override
  String get undoAction => "元に戻す";
  @override
  String get redoAction => "やり直す";
  @override
  String get newProjectAction => "新規プロジェクト";
  @override
  String get saveProjectAction => "保存";
  @override
  String get openProjectAction => "開く";
  @override
  String get seeNodeDescriptionAction => "説明を見る";
  @override
  String get collapseNodeAction => "折りたたむ";
  @override
  String get expandNodeAction => "展開";
  @override
  String get cutLinksAction => "リンクを切断";
  @override
  String get editorMenuLabel => "エディターメニュー";
  @override
  String get nodeMenuLabel => "ノードメニュー";
  @override
  String get portMenuLabel => "ポートメニュー";
  @override
  String get linkMenuLabel => "リンクメニュー";
  @override
  String get deleteLinkAction => "リンクを削除";
  @override
  String get navigateToSourceAction => "ソースに移動";
  @override
  String get navigateToDestinationAction => "宛先に移動";
  @override
  String failedToCopySelectionErrorMsg(String e) => "選択範囲のコピーに失敗しました: $e";
  @override
  String get selectionCopiedSuccessfullyMsg => "選択範囲をコピーしました";
  @override
  String failedToPasteSelectionErrorMsg(String e) => "選択範囲の貼り付けに失敗しました: $e";
  @override
  String failedToSaveProjectErrorMsg(String e) => "プロジェクトの保存に失敗しました: $e";
  @override
  String get projectSavedSuccessfullyMsg => "プロジェクトを保存しました";
  @override
  String failedToLoadProjectErrorMsg(String e) => "プロジェクトの読み込みに失敗しました: $e";
  @override
  String get projectLoadedSuccessfullyMsg => "プロジェクトを読み込みました";
  @override
  String get newProjectCreatedSuccessfullyMsg => "新しいプロジェクトを作成しました";
  @override
  String failedToExecuteNodeErrorMsg(String e) => "ノードの実行に失敗しました: $e";
}
