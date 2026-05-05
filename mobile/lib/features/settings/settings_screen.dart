import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'language_provider.dart';
import '../../core/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.primary),
            title: Text('language'.tr()),
            trailing: DropdownButton<AppLanguage>(
              value: _getAppLanguageFromLocale(context.locale),
              onChanged: (AppLanguage? newValue) {
                if (newValue != null) {
                  context.setLocale(newValue.locale);
                  ref.read(languageProvider.notifier).setLanguage(newValue);
                }
              },
              items: AppLanguage.values.map((AppLanguage language) {
                return DropdownMenuItem<AppLanguage>(
                  value: language,
                  child: Text(language.name),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  AppLanguage _getAppLanguageFromLocale(Locale locale) {
    if (locale.languageCode == 'fr') {
      return AppLanguage.french;
    }
    return AppLanguage.english;
  }
}
