import 'package:flutter/material.dart';

import '../core/preferences/app_preferences.dart';
import '../l10n/app_localizations.dart';
import 'app_dependencies.dart';
import 'home_shell.dart';
import 'theme.dart';

class ServiceOrderApp extends StatelessWidget {
  const ServiceOrderApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final preferences = dependencies.preferences;

    // Rebuilds when the language or regional format changes in Settings.
    return PreferencesScope(
      preferences: preferences,
      child: ListenableBuilder(
        listenable: preferences,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dependencies.config.brandColor),
          locale: preferences.locale,
          supportedLocales: AppPreferences.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: HomeShell(dependencies: dependencies),
        ),
      ),
    );
  }
}
