import 'package:example/models/locale.dart';
import 'package:example/visual_scripting_example/example.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlNodesExampleApp());
}

class FlNodesExampleApp extends StatefulWidget {
  const FlNodesExampleApp({super.key});

  @override
  State<FlNodesExampleApp> createState() => _FlNodesExampleAppState();
}

class _FlNodesExampleAppState extends State<FlNodesExampleApp> {
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

  void _setLocale(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        const FlNodeEditorLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: locales.map((l) => Locale(l.code)).toList(),
      locale: _locale,
      title: 'Fl Nodes Example',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: ExampleGalleryScreen(
        locales: locales,
        currentLocale: _locale,
        onLocaleChanged: _setLocale,
      ),
      debugShowCheckedModeBanner: kDebugMode,
    );
  }
}

class ExampleGalleryScreen extends StatefulWidget {
  final List<LocaleDataModel> locales;
  final Locale currentLocale;
  final void Function(String) onLocaleChanged;

  const ExampleGalleryScreen({
    super.key,
    required this.locales,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  State<ExampleGalleryScreen> createState() => _ExampleGalleryScreenState();
}

class _ExampleGalleryScreenState extends State<ExampleGalleryScreen> {
  List<_ExampleEntry> get _examples => [
        _ExampleEntry(
          title: 'Visual Scripting',
          description:
              'Classic node graph with execution flow and visual programming capabilities.',
          icon: Icons.memory,
          tags: ['nodes', 'scripting', 'visual'],
          imageUrl:
              'https://raw.githubusercontent.com/WilliamKarolDiCioccio/fl_nodes/refs/heads/main/.github/images/node_editor_example.webp',
          builder: (ctx) => VisualScriptingExampleScreen(
            locales: widget.locales,
            currentLocale: widget.currentLocale,
            onLocaleChanged: widget.onLocaleChanged,
          ),
        ),
        _ExampleEntry(
          title: 'Mind Map',
          description: 'Classic mind map layout with draggable nodes.',
          icon: Icons.map,
          tags: ['nodes', 'mind map', 'layout'],
          builder: (ctx) => const Scaffold(
            body: Center(
              child: Text('Coming Soon'),
            ),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(51),
                ),
              ),
            ),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.account_tree,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                Text(
                  "FlNodes Examples",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildExampleGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleGrid() {
    if (_examples.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withAlpha(127),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          int crossAxisCount;
          double childAspectRatio;

          if (width > 1200) {
            crossAxisCount = 3;
            childAspectRatio = 1.3;
          } else if (width > 800) {
            crossAxisCount = 2;
            childAspectRatio = 1.2;
          } else if (width > 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.1;
          } else {
            crossAxisCount = 1;
            childAspectRatio = 1.4;
          }

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ExampleCard(entry: _examples[index]),
              childCount: _examples.length,
            ),
          );
        },
      ),
    );
  }
}

class _ExampleEntry {
  final String title;
  final String description;
  final IconData icon;
  final List<String> tags;
  final String? imageUrl;
  final WidgetBuilder builder;

  _ExampleEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.tags,
    required this.builder,
    this.imageUrl,
  });
}

class _ExampleCard extends StatefulWidget {
  final _ExampleEntry entry;

  const _ExampleCard({required this.entry});

  @override
  State<_ExampleCard> createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 8 : 2,
        shadowColor: Colors.black.withAlpha(76),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _isHovered ? const Color(0xFF64B5F6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: entry.builder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image/Icon section
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: entry.imageUrl != null
                      ? Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildIconPlaceholder(),
                        )
                      : _buildIconPlaceholder(),
                ),
              ),
              // Content section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          // Title with icon
                          Row(
                            spacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(51),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  entry.icon,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Description
                          Text(
                            entry.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Tags
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: entry.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withAlpha(179),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          widget.entry.icon,
          size: 64,
          color: Theme.of(context).colorScheme.primary.withAlpha(127),
        ),
      ),
    );
  }
}
