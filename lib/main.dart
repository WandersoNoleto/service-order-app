import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'core/config/client_config.dart';
import 'core/database/app_database.dart';
import 'features/service_order/data/service_order_repository.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  // Required before using plugins (sqflite) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open();

  runApp(
    ServiceOrderApp(
      dependencies: AppDependencies(
        config: ClientConfig.fromEnvironment(),
        orders: ServiceOrderRepository(database),
        settings: SettingsRepository(database),
      ),
    ),
  );
}
