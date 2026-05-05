import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  english(Locale('en'), 'English'),
  french(Locale('fr'), 'Français');

  final Locale locale;
  final String name;
  const AppLanguage(this.locale, this.name);
}

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    // Note: The actual initial locale is managed by easy_localization in main.dart
    // This provider is a bridge for Riverpod features.
    return AppLanguage.english;
  }

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(() {
  return LanguageNotifier();
});
