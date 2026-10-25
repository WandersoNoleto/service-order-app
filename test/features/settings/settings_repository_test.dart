import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:service_order_app/core/database/app_database.dart';
import 'package:service_order_app/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase database;
  late SettingsRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = SettingsRepository(database);
  });

  tearDown(() => database.close());

  test('responsible name falls back to the client config', () async {
    expect(await repository.responsibleName(fallback: 'Valdejane'), 'Valdejane');
  });

  test('responsible name can be changed', () async {
    await repository.setResponsibleName('  Valdejane Silva ');
    await repository.setResponsibleName('Valdejane Souza');

    expect(
      await repository.responsibleName(fallback: 'Valdejane'),
      'Valdejane Souza',
    );
  });
}
