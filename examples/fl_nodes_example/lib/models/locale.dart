import 'package:flutter/widgets.dart';

enum SupportedLocale {
  en('en', 'US', 'English'),
  it('it', 'IT', 'Italiano'),
  fr('fr', 'FR', 'Français'),
  es('es', 'ES', 'Español'),
  de('de', 'DE', 'Deutsch'),
  ja('ja', 'JP', '日本語'),
  zh('zh', 'CN', '中文'),
  ko('ko', 'KR', '한국어'),
  ru('ru', 'RU', 'Русский'),
  ar('ar', 'SA', 'العربية');

  const SupportedLocale(this.languageCode, this.countryCode, this.displayName);

  final String languageCode;
  final String countryCode;
  final String displayName;

  Locale get locale => Locale(languageCode);
}
