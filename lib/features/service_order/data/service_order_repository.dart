import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import 'service_order.dart';

/// Reads and writes service orders (and their parts) in the local database.
class ServiceOrderRepository {
  ServiceOrderRepository(this._database, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _clock;

  Database get _db => _database.db;

  /// Saves a new order and returns its id.
  Future<int> create(ServiceOrder order) {
    final now = _clock().toIso8601String();

    return _db.transaction((txn) async {
      final id = await txn.insert('service_orders', {
        ...order.toMap(),
        'created_at': now,
        'updated_at': now,
      });
      await _insertItems(txn, id, order.items);
      return id;
    });
  }

  /// Overwrites an existing order. Its parts are replaced entirely.
  Future<void> update(ServiceOrder order) {
    final id = order.id;
    if (id == null) {
      throw ArgumentError('Cannot update an order that was never saved.');
    }

    return _db.transaction((txn) async {
      await txn.update(
        'service_orders',
        {...order.toMap(), 'updated_at': _clock().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'service_order_items',
        where: 'order_id = ?',
        whereArgs: [id],
      );
      await _insertItems(txn, id, order.items);
    });
  }

  Future<ServiceOrder?> findById(int id) async {
    final rows = await _db.query(
      'service_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;

    final items = await _itemsByOrder([id]);
    return ServiceOrder.fromMap(rows.first, items: items[id] ?? const []);
  }

  /// All orders, newest first. [query] filters by customer name or number.
  Future<List<ServiceOrder>> list({String query = ''}) async {
    final term = query.trim();
    final rows = await _db.query(
      'service_orders',
      where: term.isEmpty ? null : 'customer_name LIKE ? OR order_number LIKE ?',
      whereArgs: term.isEmpty ? null : ['%$term%', '%$term%'],
      orderBy: 'created_at DESC, id DESC',
    );

    final ids = [for (final row in rows) row['id'] as int];
    final items = await _itemsByOrder(ids);

    return [
      for (final row in rows)
        ServiceOrder.fromMap(row, items: items[row['id']] ?? const []),
    ];
  }

  Future<void> setPdfPath(int id, String path) {
    return _db.update(
      'service_orders',
      {'pdf_path': path},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes the order; its parts go with it (ON DELETE CASCADE).
  Future<void> delete(int id) {
    return _db.delete('service_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _insertItems(
    DatabaseExecutor executor,
    int orderId,
    List<ServiceOrderItem> items,
  ) async {
    for (var i = 0; i < items.length; i++) {
      await executor.insert(
        'service_order_items',
        items[i].toMap(orderId: orderId, position: i),
      );
    }
  }

  Future<Map<int, List<ServiceOrderItem>>> _itemsByOrder(List<int> ids) async {
    if (ids.isEmpty) return {};

    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await _db.query(
      'service_order_items',
      where: 'order_id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'order_id, position',
    );

    final result = <int, List<ServiceOrderItem>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row['order_id'] as int, () => [])
          .add(ServiceOrderItem.fromMap(row));
    }
    return result;
  }
}
