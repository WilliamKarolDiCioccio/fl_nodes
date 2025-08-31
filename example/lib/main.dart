import 'package:example/models/locale.dart';
import 'package:example/pages/home_page.dart';
import 'package:example/pages/multiple_instances.dart';
import 'package:example/pages/single_instance.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NodeEditorExampleApp());
}

class NodeEditorExampleApp extends StatefulWidget {
  const NodeEditorExampleApp({super.key});

  @override
  State<NodeEditorExampleApp> createState() => _NodeEditorExampleAppState();
}

class _NodeEditorExampleAppState extends State<NodeEditorExampleApp> {
  late Locale _locale;

  final List<LocaleDataModel> locales = [
    const LocaleDataModel('en', '🇺🇸', 'English'),
    const LocaleDataModel('it', '🇮🇹', 'Italiano'),
    const LocaleDataModel('fr', '🇫🇷', 'Français'),
    const LocaleDataModel('es', '🇪🇸', 'Español'),
    const LocaleDataModel('de', '🇩🇪', 'Deutsch'),
    const LocaleDataModel('ja', '🇯🇵', '日本語'),
    const LocaleDataModel('zh', '🇨🇳', '中文'),
    const LocaleDataModel('ko', '🇰🇷', '한국어'),
    const LocaleDataModel('ru', '🇷🇺', 'Русский'),
    const LocaleDataModel('ar', '🇸🇦', 'العربية'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        const FlNodeEditorLocalizationsDelegate(),
      ],
      supportedLocales: locales.map((l) => Locale(l.code)).toList(),
      locale: _locale,
      title: 'Fl Nodes Example',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/single_instance': (context) => SingleInstancePage(
              locales: locales,
              currentLocale: _locale,
              onLocaleChanged: _setLocale,
            ),
        '/multiple_instances': (context) => MultipleInstancesPage(
              locales: locales,
              currentLocale: _locale,
              onLocaleChanged: _setLocale,
            ),
      },
      debugShowCheckedModeBanner: kDebugMode,
    );
  }

  @override
  void initState() {
    super.initState();

    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final supportedLanguageCodes = locales.map((l) => l.code).toSet();
    final defaultLanguageCode =
        supportedLanguageCodes.contains(systemLocale.languageCode)
            ? systemLocale.languageCode
            : 'en';

    _locale = Locale(defaultLanguageCode);
  }

  void _setLocale(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
  }
}
