import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_dependencies.dart';
import 'home_shell.dart';
import 'theme.dart';

class ServiceOrderApp extends StatelessWidget {
  const ServiceOrderApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordens de Serviço',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dependencies.config.brandColor),
      // Date/time pickers and system texts in Portuguese.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(dependencies: dependencies),
    );
  }
}
