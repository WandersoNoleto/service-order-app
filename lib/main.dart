import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'core/config/client_config.dart';
import 'core/database/app_database.dart';
import 'core/storage/logo_storage.dart';
import 'features/document/service_order_documents.dart';
import 'features/service_order/data/service_order_repository.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  // Required before using plugins (sqflite) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final config = ClientConfig.fromEnvironment();
  final database = await AppDatabase.open();
  final logos = LogoStorage();

  runApp(
    ServiceOrderApp(
      dependencies: AppDependencies(
        config: config,
        orders: ServiceOrderRepository(database),
        settings: SettingsRepository(database),
        documents: ServiceOrderDocuments(logos),
        logos: logos,
      ),
    ),
  );
}
