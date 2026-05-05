import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faciale/features/settings/language_provider.dart';
import 'dart:ui';

void main() {
  test('LanguageNotifier initial state should be english', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(languageProvider), AppLanguage.english);
  });

  test('LanguageNotifier setLanguage should update state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(languageProvider.notifier);
    notifier.setLanguage(AppLanguage.french);

    expect(container.read(languageProvider), AppLanguage.french);
    expect(container.read(languageProvider).locale, const Locale('fr'));
  });
}
