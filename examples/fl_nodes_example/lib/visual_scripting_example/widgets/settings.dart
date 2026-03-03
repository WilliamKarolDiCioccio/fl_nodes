import 'package:country_flags/country_flags.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes_example/l10n/app_localizations.dart';
import 'package:fl_nodes_example/models/locale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.controller,
  });

  final Locale currentLocale;
  final void Function(String) onLocaleChanged;
  final FlNodesController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  strings.settingsPanelTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Section
                _buildSectionTitle(
                  context,
                  strings.languageSettingsSectionTitle,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(75),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentLocale.languageCode,
                      isExpanded: true,
                      items: SupportedLocale.values
                          .map(
                            (locale) => DropdownMenuItem<String>(
                              value: locale.languageCode,
                              child: Row(
                                children: [
                                  CountryFlag.fromCountryCode(
                                    locale.countryCode,
                                    theme: const ImageTheme(
                                      shape: RoundedRectangle(4),
                                      height: 18,
                                      width: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(locale.displayName),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          onLocaleChanged(value);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Links Section
                _buildSectionTitle(context, strings.linksSectionTitle),
                const SizedBox(height: 12),
                _buildLinkTile(
                  context,
                  strings.githubRepositoryLinkTitle,
                  strings.githubRepositoryLinkSubtitle,
                  Icons.star,
                  () => _launchUrl(
                    'https://github.com/WilliamKarolDiCioccio/fl_nodes',
                  ),
                ),
                _buildLinkTile(
                  context,
                  strings.documentationLinkTitle,
                  strings.documentationLinkSubtitle,
                  Icons.book,
                  () => _launchUrl('https://pub.dev/packages/fl_nodes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _buildLinkTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: Icon(
      Icons.open_in_new,
      size: 18,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Locale>('currentLocale', currentLocale))
      ..add(ObjectFlagProperty<void Function(String)>.has('onLocaleChanged', onLocaleChanged))
      ..add(DiagnosticsProperty<FlNodesController>('controller', controller));
  }
}
