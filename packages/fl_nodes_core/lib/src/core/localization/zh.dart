import 'delegate.dart';

class FlNodeEditorLocalizationsZh extends FlNodeEditorLocalizations {
  FlNodeEditorLocalizationsZh(super.locale);

  @override
  String get closeAction => "关闭";
  @override
  String get addNodeAction => "添加";
  @override
  String get deleteNodeAction => "删除";
  @override
  String get centerViewAction => "视图居中";
  @override
  String get resetZoomAction => "重置缩放";
  @override
  String get createNodeAction => "创建";
  @override
  String get copySelectionAction => "复制";
  @override
  String get pasteSelectionAction => "粘贴";
  @override
  String get cutSelectionAction => "剪切";
  @override
  String get projectLabel => "项目";
  @override
  String get undoAction => "撤销";
  @override
  String get redoAction => "重做";
  @override
  String get newProjectAction => "新建项目";
  @override
  String get saveProjectAction => "保存";
  @override
  String get openProjectAction => "打开";
  @override
  String get seeNodeDescriptionAction => "查看描述";
  @override
  String get collapseNodeAction => "折叠";
  @override
  String get expandNodeAction => "展开";
  @override
  String get cutLinksAction => "剪断连接";
  @override
  String get editorMenuLabel => "编辑器菜单";
  @override
  String get nodeMenuLabel => "节点菜单";
  @override
  String get portMenuLabel => "端口菜单";
  @override
  String get linkMenuLabel => "链接菜单";
  @override
  String get deleteLinkAction => "删除链接";
  @override
  String get navigateToSourceAction => "导航到源";
  @override
  String get navigateToDestinationAction => "导航到目标";
  @override
  String failedToCopySelectionErrorMsg(String e) => "复制选区失败：$e";
  @override
  String get selectionCopiedSuccessfullyMsg => "选区复制成功";
  @override
  String failedToPasteSelectionErrorMsg(String e) => "粘贴选区失败：$e";
  @override
  String failedToSaveProjectErrorMsg(String e) => "保存项目失败：$e";
  @override
  String get projectSavedSuccessfullyMsg => "项目保存成功";
  @override
  String failedToLoadProjectErrorMsg(String e) => "加载项目失败：$e";
  @override
  String get projectLoadedSuccessfullyMsg => "项目加载成功";
  @override
  String get newProjectCreatedSuccessfullyMsg => "新项目创建成功";
  @override
  String failedToExecuteNodeErrorMsg(String e) => "执行节点失败：$e";
}
