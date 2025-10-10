import 'dart:ui';

import 'ar.dart';
import 'de.dart';
import 'en.dart';
import 'es.dart';
import 'fr.dart';
import 'it.dart';
import 'ja.dart';
import 'ko.dart';
import 'ru.dart';
import 'zh.dart';
import 'package:flutter/widgets.dart';

/// An abstract class that defines the localizations for the Node Editor.
abstract class FlNodeEditorLocalizations {
  final Locale locale;

  FlNodeEditorLocalizations(this.locale);

  static FlNodeEditorLocalizations of(BuildContext? context) {
    if (context == null) return _fallback;

    final loc = Localizations.of<FlNodeEditorLocalizations>(
      context,
      FlNodeEditorLocalizations,
    );

    return loc ?? _fallback;
  }

  static final FlNodeEditorLocalizations _fallback =
      switch (PlatformDispatcher.instance.locale.languageCode) {
    'it' => FlNodeEditorLocalizationsIt(const Locale('it')),
    'fr' => FlNodeEditorLocalizationsFr(const Locale('fr')),
    'es' => FlNodeEditorLocalizationsEs(const Locale('es')),
    'de' => FlNodeEditorLocalizationsDe(const Locale('de')),
    'ja' => FlNodeEditorLocalizationsJa(const Locale('ja')),
    'zh' => FlNodeEditorLocalizationsZh(const Locale('zh')),
    'ko' => FlNodeEditorLocalizationsKo(const Locale('ko')),
    'ru' => FlNodeEditorLocalizationsRu(const Locale('ru')),
    'ar' => FlNodeEditorLocalizationsAr(const Locale('ar')),
    _ => FlNodeEditorLocalizationsEn(const Locale('en')),
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
class FlNodeEditorLocalizationsDelegate
    extends LocalizationsDelegate<FlNodeEditorLocalizations> {
  const FlNodeEditorLocalizationsDelegate();

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
  Future<FlNodeEditorLocalizations> load(Locale locale) async {
    return switch (locale.languageCode) {
      'en' => FlNodeEditorLocalizationsEn(locale),
      'it' => FlNodeEditorLocalizationsIt(locale),
      'fr' => FlNodeEditorLocalizationsFr(locale),
      'es' => FlNodeEditorLocalizationsEs(locale),
      'de' => FlNodeEditorLocalizationsDe(locale),
      'ja' => FlNodeEditorLocalizationsJa(locale),
      'zh' => FlNodeEditorLocalizationsZh(locale),
      'ko' => FlNodeEditorLocalizationsKo(locale),
      'ru' => FlNodeEditorLocalizationsRu(locale),
      'ar' => FlNodeEditorLocalizationsAr(locale),
      _ => FlNodeEditorLocalizationsEn(locale)
    };
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
