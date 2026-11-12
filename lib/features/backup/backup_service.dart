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

/// A backup read back and checked, ready to be restored.
class BackupContents {
  const BackupContents({
    required this.createdAt,
    required this.database,
    required this.logos,
  });

  final DateTime createdAt;
  final Uint8List database;

  /// File name → content.
  final Map<String, Uint8List> logos;
}

enum BackupProblem {
  /// Not a .zip made by this app (or a damaged one).
  notABackup,

  /// Made by a newer version of the app, with data this one can't read.
  newerVersion,
}

class BackupException implements Exception {
  const BackupException(this.problem);

  final BackupProblem problem;

  @override
  String toString() => 'BackupException(${problem.name})';
}

/// Copies everything the app stores (database and company logo) into one
/// .zip the user keeps outside the app, so it survives uninstalling, and
/// puts it back.
///
/// PDFs are not included: they are generated again from the database.
class BackupService {
  BackupService({
    required this._database,
    required this._logos,
    required this._settings,
    required this._appVersion,
    DateTime Function()? clock,
    Future<Directory> Function()? supportDirectory,
  })  : _clock = clock ?? DateTime.now,
        _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final AppDatabase _database;
  final LogoStorage _logos;
  final SettingsRepository _settings;
  final Future<InstalledVersion> Function() _appVersion;
  final DateTime Function() _clock;
  final Future<Directory> Function() _supportDirectory;

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

  /// Lets the user pick a backup file and checks it. Null when cancelled;
  /// throws [BackupException] when the file can't be restored.
  Future<BackupContents?> pick() async {
    // Any type: apps like WhatsApp don't always label a .zip as one.
    final picked = await FilePicker.pickFile();
    if (picked == null) return null;
    return read(await picked.readAsBytes());
  }

  /// Opens and checks a backup made by [create].
  BackupContents read(Uint8List bytes) {
    final (archive, manifest) = _open(bytes);
    if (manifest
        case {
          'format': final int format,
          'schemaVersion': final int schemaVersion,
          'createdAt': final String createdAt,
        }) {
      if (format > formatVersion || schemaVersion > AppDatabase.schemaVersion) {
        throw const BackupException(BackupProblem.newerVersion);
      }
      final database = archive.findFile(databaseName)?.readBytes();
      final date = DateTime.tryParse(createdAt);
      if (database == null || date == null) {
        throw const BackupException(BackupProblem.notABackup);
      }
      return BackupContents(
        createdAt: date,
        database: database,
        logos: {
          for (final file in archive.files)
            if (file.isFile && p.dirname(file.name) == brandingFolder)
              p.basename(file.name): file.content,
        },
      );
    }
    throw const BackupException(BackupProblem.notABackup);
  }

  /// The archive and its decoded manifest (null when missing).
  static (Archive, Object?) _open(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifest = archive.findFile(manifestName);
      return (
        archive,
        manifest == null ? null : jsonDecode(utf8.decode(manifest.content)),
      );
    } catch (_) {
      throw const BackupException(BackupProblem.notABackup);
    }
  }

  /// Replaces all the app data with [backup]. A copy of the current data
  /// is kept first, so [undoRestore] can bring it back.
  Future<void> restore(BackupContents backup) async {
    final current = await create();
    await (await _safetyCopy()).writeAsBytes(current.bytes, flush: true);
    await _replaceWith(backup);
  }

  /// Puts back the data replaced by the last [restore]. False when there
  /// is no copy.
  Future<bool> undoRestore() async {
    final copy = await _safetyCopy();
    if (!await copy.exists()) return false;
    await _replaceWith(read(await copy.readAsBytes()));
    return true;
  }

  Future<void> _replaceWith(BackupContents backup) async {
    await _database.replaceFile(backup.database);
    await _logos.replaceAll(backup.logos);
  }

  /// Kept in the app's private folder: it only exists to undo a restore.
  Future<File> _safetyCopy() async {
    final dir = Directory(p.join((await _supportDirectory()).path, 'backups'));
    await dir.create(recursive: true);
    return File(p.join(dir.path, 'before_restore.zip'));
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
