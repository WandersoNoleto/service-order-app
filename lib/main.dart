import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'core/config/client_config.dart';
import 'core/database/app_database.dart';
import 'core/preferences/app_preferences.dart';
import 'core/storage/logo_storage.dart';
import 'features/backup/backup_service.dart';
import 'features/document/service_order_documents.dart';
import 'features/service_order/data/service_order_repository.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/update/update_checker.dart';
import 'features/update/update_installer.dart';

Future<void> main() async {
  // Required before using plugins (sqflite) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final config = ClientConfig.fromEnvironment();
  final database = await AppDatabase.open();
  final logos = LogoStorage();
  final settings = SettingsRepository(database);
  final preferences = await AppPreferences.load(settings);
  final updates = UpdateChecker(channel: config.channel);

  runApp(
    ServiceOrderApp(
      dependencies: AppDependencies(
        config: config,
        orders: ServiceOrderRepository(database),
        settings: settings,
        documents: ServiceOrderDocuments(logos),
        logos: logos,
        updates: updates,
        installer: UpdateInstaller(),
        preferences: preferences,
        backup: BackupService(
          database: database,
          logos: logos,
          settings: settings,
          appVersion: updates.installedVersion,
        ),
        // Debug builds take their version from pubspec.yaml, so a published
        // client build (x.y.z-<client>.N) always looks newer and the prompt would
        // show on every `flutter run`.
        checkUpdatesOnStartup: !kDebugMode,
      ),
    ),
  );
}
