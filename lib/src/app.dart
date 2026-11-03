import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/commons/controller/locale_controller.dart';
import 'package:gta_app/l10n/generated/app_localizations.dart';
import 'package:gta_app/src/res/strings.dart';
import 'package:gta_app/src/res/theme.dart';
import 'package:gta_app/src/utils/responsive.dart';
import 'package:gta_app/src/utils/router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: AppString.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);

        // Phones stay portrait; tablets may rotate to use the wider screen.
        SystemChrome.setPreferredOrientations(
          media.size.shortestSide >= kTabletShortestSide
              ? DeviceOrientation.values
              : const [
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ],
        );

        // Respect the user's font size, but cap it so layouts don't break.
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
