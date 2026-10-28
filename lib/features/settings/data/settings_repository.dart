import 'package:sqflite/sqflite.dart';

import '../../../core/config/client_config.dart';
import '../../../core/database/app_database.dart';
import 'company_profile.dart';

/// Preferences the user can change inside the app (key/value table).
///
/// Company data is stored only when it differs from the build defaults, so
/// "restore default" is just deleting the row.
class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  static const _logoFileKey = 'company_logo_file';

  /// Keeps the key used before company data became editable, so the
  /// responsible name already saved on phones is not lost.
  static String _key(CompanyField field) => field == CompanyField.responsible
      ? 'responsible_name'
      : 'company_${field.name}';

  Database get _db => _database.db;

  Future<CompanyProfile> companyProfile(ClientConfig defaults) async {
    final rows = await _db.query('app_settings');
    final stored = {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };

    return CompanyProfile(
      defaults: defaults,
      overrides: {
        for (final field in CompanyField.values)
          if (stored[_key(field)] case final value?) field: value,
      },
      customLogoFile: stored[_logoFileKey],
    );
  }

  /// Saves the edited fields. A value equal to the default removes the
  /// override, so the field keeps following the build config.
  Future<void> saveCompanyFields(
    ClientConfig defaults,
    Map<CompanyField, String> values,
  ) {
    final profile = CompanyProfile(defaults: defaults);

    return _db.transaction((txn) async {
      for (final MapEntry(key: field, value: raw) in values.entries) {
        final value = raw.trim();
        if (value == profile.defaultValue(field)) {
          await txn.delete(
            'app_settings',
            where: 'key = ?',
            whereArgs: [_key(field)],
          );
        } else {
          await txn.insert(
            'app_settings',
            {'key': _key(field), 'value': value},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// [fileName] of a logo already copied into the app folder, or null to
  /// go back to the bundled logo.
  Future<void> setCustomLogoFile(String? fileName) {
    if (fileName == null) {
      return _db.delete(
        'app_settings',
        where: 'key = ?',
        whereArgs: [_logoFileKey],
      );
    }
    return _db.insert(
      'app_settings',
      {'key': _logoFileKey, 'value': fileName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Back to factory defaults: all company fields and the logo.
  Future<void> resetCompany() {
    final keys = [for (final field in CompanyField.values) _key(field), _logoFileKey];
    return _db.delete(
      'app_settings',
      where: 'key IN (${List.filled(keys.length, '?').join(', ')})',
      whereArgs: keys,
    );
  }
}
