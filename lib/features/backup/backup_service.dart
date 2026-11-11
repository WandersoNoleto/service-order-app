import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/storage/logo_storage.dart';
import '../settings/data/settings_repository.dart';
import '../update/update_checker.dart';

/// A backup ready to be shared or saved.
typedef BackupFile = ({String name, Uint8List bytes});

/// Copies everything the app stores (database and company logo) into one
/// .zip the user keeps outside the app, so it survives uninstalling.
///
/// PDFs are not included: they are generated again from the database.
class BackupService {
  BackupService({
    required this._database,
    required this._logos,
    required this._settings,
    required this._appVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final LogoStorage _logos;
  final SettingsRepository _settings;
  final Future<InstalledVersion> Function() _appVersion;
  final DateTime Function() _clock;

  /// Version of the .zip layout below; bump it when the layout changes.
  static const formatVersion = 1;

  static const manifestName = 'manifest.json';
  static const databaseName = 'database/${AppDatabase.fileName}';
  static const brandingFolder = 'branding';

  static const _lastBackupKey = 'last_backup_at';

  /// Builds the .zip: manifest, database file and logos.
  Future<BackupFile> create() async {
    final now = _clock();
    final version = await _appVersion();

    await _database.flush();
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          manifestName,
          jsonEncode({
            'format': formatVersion,
            'appVersion': version.name,
            'schemaVersion': AppDatabase.schemaVersion,
            'createdAt': now.toIso8601String(),
          }),
        ),
      )
      ..add(
        ArchiveFile.bytes(
          databaseName,
          await File(_database.path).readAsBytes(),
        ),
      );
    for (final logo in await _logos.storedFiles()) {
      archive.add(
        ArchiveFile.bytes(
          '$brandingFolder/${p.basename(logo.path)}',
          await logo.readAsBytes(),
        ),
      );
    }

    return (name: fileName(now), bytes: ZipEncoder().encodeBytes(archive));
  }

  /// Opens the share sheet (Drive, WhatsApp, e-mail…). False when the
  /// user closed it without choosing an app.
  Future<bool> share() async {
    final backup = await create();
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
    await dir.create(recursive: true);
    final file = await File(p.join(dir.path, backup.name))
        .writeAsBytes(backup.bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/zip')]),
    );
    if (result.status == ShareResultStatus.dismissed) return false;
    await _markDone();
    return true;
  }

  /// Lets the user pick a folder on the phone (Downloads…). False when
  /// cancelled.
  Future<bool> saveToDevice() async {
    final backup = await create();
    final saved = await FilePicker.saveFile(
      fileName: backup.name,
      bytes: backup.bytes,
      mimeType: 'application/zip',
    );
    if (saved == null) return false;
    await _markDone();
    return true;
  }

  /// When the last backup was shared or saved; null if never.
  Future<DateTime?> lastBackupAt() async =>
      DateTime.tryParse(await _settings.preference(_lastBackupKey) ?? '');

  Future<void> _markDone() =>
      _settings.setPreference(_lastBackupKey, _clock().toIso8601String());

  /// "backup_service_orders_2026-11-11_1530.zip" — sorts by date.
  static String fileName(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'backup_service_orders_${at.year}-${two(at.month)}-${two(at.day)}'
        '_${two(at.hour)}${two(at.minute)}.zip';
  }
}
