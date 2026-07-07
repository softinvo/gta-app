import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/commons/controller/shared_prefs_controller.dart';
import 'package:gta_app/src/commons/repository/shared_prefs_repo.dart';

/// One entry per language the app can be switched to. Matches the ARB
/// files under lib/l10n/ — keep both in sync when adding a language.
class AppLanguage {
  final String code;
  final String nativeName;
  final String englishName;
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });
}

const List<AppLanguage> kAppLanguages = [
  AppLanguage(code: 'en', nativeName: 'English', englishName: 'English'),
  AppLanguage(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
  AppLanguage(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
  AppLanguage(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
  AppLanguage(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
  AppLanguage(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
  AppLanguage(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
];

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  static const _prefsKey = 'APP_LOCALE';
  static const _defaultLanguageCode = 'en';

  @override
  Locale build() {
    // Seeded synchronously from main.dart via overrideWith so the UI never
    // flashes English before the persisted locale loads.
    return const Locale(_defaultLanguageCode);
  }

  Future<void> setLocale(String languageCode) async {
    if (!kAppLanguages.any((l) => l.code == languageCode)) return;
    state = Locale(languageCode);
    await ref
        .read(sharedPrefsControllerPovider)
        .setData(key: _prefsKey, cookie: languageCode);
  }

  static Future<String?> readPersistedLanguageCode() async {
    final code = await SharedPrefsRepo().getData(_prefsKey);
    if (code != null && kAppLanguages.any((l) => l.code == code)) {
      return code;
    }
    return null;
  }
}

/// Lets [LocaleController] be seeded with a persisted value at app startup
/// (see main.dart) instead of always defaulting to English on cold start.
class SeededLocaleController extends LocaleController {
  final String languageCode;
  SeededLocaleController(this.languageCode);

  @override
  Locale build() => Locale(languageCode);
}
