import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'package:fl_nodes_core/src/core/localization/ar.dart';
import 'package:fl_nodes_core/src/core/localization/de.dart';
import 'package:fl_nodes_core/src/core/localization/en.dart';
import 'package:fl_nodes_core/src/core/localization/es.dart';
import 'package:fl_nodes_core/src/core/localization/fr.dart';
import 'package:fl_nodes_core/src/core/localization/it.dart';
import 'package:fl_nodes_core/src/core/localization/ja.dart';
import 'package:fl_nodes_core/src/core/localization/ko.dart';
import 'package:fl_nodes_core/src/core/localization/ru.dart';
import 'package:fl_nodes_core/src/core/localization/zh.dart';

/// An abstract class that defines the localizations for the Node Editor.
abstract class FlNodesLocalizations {
  final Locale locale;

  FlNodesLocalizations(this.locale);

  static FlNodesLocalizations of(BuildContext? context) {
    if (context == null) return _fallback;

    final FlNodesLocalizations? loc = Localizations.of<FlNodesLocalizations>(
      context,
      FlNodesLocalizations,
    );

    return loc ?? _fallback;
  }

  static final FlNodesLocalizations _fallback =
      switch (PlatformDispatcher.instance.locale.languageCode) {
    'it' => FlNodesLocalizationsIt(const Locale('it')),
    'fr' => FlNodesLocalizationsFr(const Locale('fr')),
    'es' => FlNodesLocalizationsEs(const Locale('es')),
    'de' => FlNodesLocalizationsDe(const Locale('de')),
    'ja' => FlNodesLocalizationsJa(const Locale('ja')),
    'zh' => FlNodesLocalizationsZh(const Locale('zh')),
    'ko' => FlNodesLocalizationsKo(const Locale('ko')),
    'ru' => FlNodesLocalizationsRu(const Locale('ru')),
    'ar' => FlNodesLocalizationsAr(const Locale('ar')),
    _ => FlNodesLocalizationsEn(const Locale('en')),
  };

  String get closeAction;
  String get addNodeAction;
  String get deleteNodeAction;
  String get centerViewAction;
  String get resetZoomAction;
  String get createNodeAction;
  String get copySelectionAction;
  String get pasteSelectionAction;
  String get cutSelectionAction;
  String get projectLabel;
  String get undoAction;
  String get redoAction;
  String get newProjectAction;
  String get saveProjectAction;
  String get openProjectAction;
  String get seeNodeDescriptionAction;
  String get collapseNodeAction;
  String get expandNodeAction;
  String get cutLinksAction;
  String get editorMenuLabel;
  String get nodeMenuLabel;
  String get portMenuLabel;
  String get linkMenuLabel;
  String get deleteLinkAction;
  String get navigateToSourceAction;
  String get navigateToDestinationAction;
  String failedToCopySelectionErrorMsg(String e);
  String get selectionCopiedSuccessfullyMsg;
  String failedToPasteSelectionErrorMsg(String e);
  String failedToSaveProjectErrorMsg(String e);
  String get projectSavedSuccessfullyMsg;
  String failedToLoadProjectErrorMsg(String e);
  String get projectLoadedSuccessfullyMsg;
  String get newProjectCreatedSuccessfullyMsg;
  String failedToExecuteNodeErrorMsg(String e);
}

/// A delegate that provides localized strings for the Node Editor.
class FlNodesLocalizationsDelegate extends LocalizationsDelegate<FlNodesLocalizations> {
  const FlNodesLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => [
        'en',
        'it',
        'fr',
        'es',
        'de',
        'ja',
        'zh',
        'ko',
        'ru',
        'ar',
      ].contains(locale.languageCode);

  @override
  Future<FlNodesLocalizations> load(Locale locale) async => switch (locale.languageCode) {
        'en' => FlNodesLocalizationsEn(locale),
        'it' => FlNodesLocalizationsIt(locale),
        'fr' => FlNodesLocalizationsFr(locale),
        'es' => FlNodesLocalizationsEs(locale),
        'de' => FlNodesLocalizationsDe(locale),
        'ja' => FlNodesLocalizationsJa(locale),
        'zh' => FlNodesLocalizationsZh(locale),
        'ko' => FlNodesLocalizationsKo(locale),
        'ru' => FlNodesLocalizationsRu(locale),
        'ar' => FlNodesLocalizationsAr(locale),
        _ => FlNodesLocalizationsEn(locale)
      };

  @override
  bool shouldReload(covariant LocalizationsDelegate<dynamic> old) => false;
}
