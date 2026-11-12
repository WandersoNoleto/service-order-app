import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      supportDirectory: () async => base,
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

  test('restore brings back the orders and logo, undo reverts', () async {
    final orders = ServiceOrderRepository(database);
    await orders.create(const ServiceOrder(orderNumber: '0001'));
    final source = File(p.join(base.path, 'photo.png'))
      ..writeAsBytesSync([7, 7]);
    final oldLogo = await logos.import(source.path);
    final saved = backup.read((await backup.create()).bytes);

    // Later: another order, the logo removed.
    await orders.create(const ServiceOrder(orderNumber: '0002'));
    await logos.deleteAllExcept(null);

    await backup.restore(saved);
    expect((await orders.list()).map((o) => o.orderNumber), ['0001']);
    expect((await logos.resolve(oldLogo))!.readAsBytesSync(), [7, 7]);

    expect(await backup.undoRestore(), isTrue);
    expect(
      (await orders.list()).map((o) => o.orderNumber).toSet(),
      {'0001', '0002'},
    );
    expect(await logos.storedFiles(), isEmpty);
  });

  test('a file that is not a backup is refused', () {
    expect(
      () => backup.read(Uint8List.fromList([1, 2, 3])),
      throwsA(
        isA<BackupException>()
            .having((e) => e.problem, 'problem', BackupProblem.notABackup),
      ),
    );
  });

  test('a backup from a newer database version is refused', () {
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          BackupService.manifestName,
          jsonEncode({
            'format': BackupService.formatVersion,
            'schemaVersion': AppDatabase.schemaVersion + 1,
            'createdAt': '2030-01-01T00:00:00.000',
          }),
        ),
      )
      ..add(ArchiveFile.bytes(BackupService.databaseName, [0]));

    expect(
      () => backup.read(ZipEncoder().encodeBytes(archive)),
      throwsA(
        isA<BackupException>()
            .having((e) => e.problem, 'problem', BackupProblem.newerVersion),
      ),
    );
  });

  test('a damaged database is not restored', () async {
    await ServiceOrderRepository(database)
        .create(const ServiceOrder(orderNumber: '0001'));
    final broken = BackupContents(
      createdAt: DateTime(2026),
      database: Uint8List.fromList(List.filled(4096, 42)),
      logos: const {},
    );

    await expectLater(backup.restore(broken), throwsA(anything));
    final orders = await ServiceOrderRepository(database).list();
    expect(orders.map((o) => o.orderNumber), ['0001']);
  });

  test('without a backup, the last date is null', () async {
    expect(await backup.lastBackupAt(), isNull);
  });
}
