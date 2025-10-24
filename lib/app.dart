import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'l10n/app_localizations.dart';

class SoccerApp extends ConsumerWidget {
  const SoccerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(languagePrefProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(selectedLanguage),
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
    );
  }
}
