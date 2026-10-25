import 'package:flutter/material.dart';

import '../core/config/client_config.dart';
import 'home_shell.dart';
import 'theme.dart';

class ServiceOrderApp extends StatelessWidget {
  const ServiceOrderApp({super.key, required this.config});

  final ClientConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordens de Serviço',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(config.brandColor),
      home: HomeShell(config: config),
    );
  }
}
