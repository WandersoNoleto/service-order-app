import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:service_order_app/core/database/app_database.dart';
import 'package:service_order_app/core/storage/logo_storage.dart';
import 'package:service_order_app/features/backup/backup_service.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/service_order/data/service_order_repository.dart';
import 'package:service_order_app/features/settings/data/settings_repository.dart';

void main() {
  late Directory base;
  late AppDatabase database;
  late LogoStorage logos;
  late BackupService backup;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    base = await Directory.systemTemp.createTemp('backup_service_test');
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: p.join(base.path, AppDatabase.fileName),
    );
    logos = LogoStorage(baseDirectory: () async => base);
    backup = BackupService(
      database: database,
      logos: logos,
      settings: SettingsRepository(database),
      appVersion: () async => (name: '1.3.0', code: 1030000),
      clock: () => DateTime(2026, 11, 11, 15, 30),
    );
  });

  tearDown(() async {
    await database.close();
    await base.delete(recursive: true);
  });

  test('the zip has the manifest, the database and the logo', () async {
    await ServiceOrderRepository(database)
        .create(const ServiceOrder(orderNumber: '0042'));
    final source = File(p.join(base.path, 'photo.png'))
      ..writeAsBytesSync([1, 2, 3]);
    final logo = await logos.import(source.path);

    final file = await backup.create();
    final archive = ZipDecoder().decodeBytes(file.bytes);

    expect(file.name, 'backup_service_orders_2026-11-11_1530.zip');

    final manifest = jsonDecode(
      utf8.decode(archive.findFile(BackupService.manifestName)!.content),
    );
    expect(manifest, {
      'format': BackupService.formatVersion,
      'appVersion': '1.3.0',
      'schemaVersion': AppDatabase.schemaVersion,
      'createdAt': '2026-11-11T15:30:00.000',
    });

    expect(
      archive.findFile('${BackupService.brandingFolder}/$logo')!.content,
      [1, 2, 3],
    );

    // The copied database opens and has the order.
    final copy = File(p.join(base.path, 'copy.db'))
      ..writeAsBytesSync(archive.findFile(BackupService.databaseName)!.content);
    final restored = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: copy.path,
    );
    final orders = await ServiceOrderRepository(restored).list();
    await restored.close();
    expect(orders.map((order) => order.orderNumber), ['0042']);
  });

  test('without a backup, the last date is null', () async {
    expect(await backup.lastBackupAt(), isNull);
  });
}
