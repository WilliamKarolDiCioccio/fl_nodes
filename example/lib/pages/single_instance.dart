import 'package:example/models/locale.dart';
import 'package:example/widgets/instance.dart';
import 'package:flutter/material.dart';

class SingleInstancePage extends StatelessWidget {
  final List<LocaleDataModel> locales;
  final Locale currentLocale;

  final Function(String) onLocaleChanged;
  const SingleInstancePage({
    super.key,
    required this.locales,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Instance'),
      ),
      body: NodeEditorInstance(
        locales: locales,
        currentLocale: currentLocale,
        onLocaleChanged: onLocaleChanged,
      ),
    );
  }
}
