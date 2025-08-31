import 'package:example/models/locale.dart';
import 'package:example/widgets/instance.dart';
import 'package:flutter/material.dart';

class MultipleInstancesPage extends StatelessWidget {
  final List<LocaleDataModel> locales;
  final Locale currentLocale;

  final Function(String) onLocaleChanged;
  const MultipleInstancesPage({
    super.key,
    required this.locales,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Instances'),
      ),
      body: Row(
        children: [
          Expanded(
            child: NodeEditorInstance(
              locales: locales,
              currentLocale: currentLocale,
              onLocaleChanged: onLocaleChanged,
            ),
          ),
          Expanded(
            child: NodeEditorInstance(
              locales: locales,
              currentLocale: currentLocale,
              onLocaleChanged: onLocaleChanged,
              sidebarPosition: SidebarPosition.end,
            ),
          ),
        ],
      ),
    );
  }
}
