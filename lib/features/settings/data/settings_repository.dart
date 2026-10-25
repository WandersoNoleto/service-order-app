import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

/// Preferences the user can change inside the app (key/value table).
class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  static const _responsibleNameKey = 'responsible_name';

  /// Name shown as "Responsável" on the OS header. Until the user edits
  /// it, [fallback] (from the client config) is used.
  Future<String> responsibleName({required String fallback}) async {
    return await _get(_responsibleNameKey) ?? fallback;
  }

  Future<void> setResponsibleName(String name) {
    return _set(_responsibleNameKey, name.trim());
  }

  Future<String?> _get(String key) async {
    final rows = await _database.db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> _set(String key, String value) {
    return _database.db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
