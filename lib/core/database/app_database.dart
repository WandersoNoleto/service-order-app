import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite database. Everything the app stores lives here.
///
/// To change the schema, bump [_version] and add the migration step to
/// [_upgradeSchema]. Never edit [_createSchema] alone: phones that already
/// have the app installed only run upgrades.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const _version = 1;
  static const fileName = 'service_orders.db';

  /// [factory] and [path] exist so tests can use an in-memory database.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), fileName);

    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE service_orders (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number       TEXT    NOT NULL DEFAULT '',
        responsible_name   TEXT    NOT NULL DEFAULT '',
        customer_name      TEXT    NOT NULL DEFAULT '',
        customer_document  TEXT    NOT NULL DEFAULT '',
        customer_address   TEXT    NOT NULL DEFAULT '',
        customer_city      TEXT    NOT NULL DEFAULT '',
        customer_state     TEXT    NOT NULL DEFAULT '',
        customer_contact   TEXT    NOT NULL DEFAULT '',
        customer_zip       TEXT    NOT NULL DEFAULT '',
        invoice_number     TEXT    NOT NULL DEFAULT '',
        under_warranty     INTEGER,
        called_at          TEXT,
        scheduled_for      TEXT,
        scheduled_time     TEXT,
        installed_at       TEXT,
        services_performed TEXT    NOT NULL DEFAULT '',
        notes              TEXT    NOT NULL DEFAULT '',
        labor_cents        INTEGER NOT NULL DEFAULT 0,
        equipment_ok       INTEGER,
        pdf_path           TEXT,
        created_at         TEXT    NOT NULL,
        updated_at         TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE service_order_items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id         INTEGER NOT NULL
                         REFERENCES service_orders(id) ON DELETE CASCADE,
        position         INTEGER NOT NULL,
        quantity         INTEGER NOT NULL DEFAULT 1,
        code             TEXT    NOT NULL DEFAULT '',
        description      TEXT    NOT NULL DEFAULT '',
        unit_price_cents INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_items_order_id ON service_order_items(order_id)',
    );

    await db.execute('''
      CREATE TABLE app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Example for the first migration:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE service_orders ADD COLUMN x TEXT');
    // }
  }
}
