import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gta_app/src/app.dart';
import 'package:gta_app/src/commons/controller/locale_controller.dart';
import 'package:gta_app/src/services/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FcmService.initialize();

  final persistedLanguageCode =
      await LocaleController.readPersistedLanguageCode();

  runApp(
    ProviderScope(
      overrides: [
        if (persistedLanguageCode != null)
          localeControllerProvider.overrideWith(
            () => SeededLocaleController(persistedLanguageCode),
          ),
      ],
      child: const App(),
    ),
  );
}
