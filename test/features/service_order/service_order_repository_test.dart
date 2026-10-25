import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:service_order_app/core/database/app_database.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/service_order/data/service_order_repository.dart';

void main() {
  late AppDatabase database;
  late ServiceOrderRepository repository;
  var now = DateTime(2026, 10, 25, 9);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    now = DateTime(2026, 10, 25, 9);
    repository = ServiceOrderRepository(database, clock: () => now);
  });

  tearDown(() => database.close());

  const order = ServiceOrder(
    orderNumber: '0001',
    responsibleName: 'Valdejane',
    customerName: 'Clínica Sorriso',
    customerCity: 'São João dos Patos',
    customerState: 'MA',
    underWarranty: false,
    scheduledTime: '14:30',
    servicesPerformed: 'Troca de rolamentos',
    laborCents: 10000,
    equipmentOk: true,
    items: [
      ServiceOrderItem(
        quantity: 2,
        description: 'Rolamentos 3604',
        unitPriceCents: 8000,
      ),
      ServiceOrderItem(
        quantity: 2,
        description: 'Lâminas do cabeçote',
        unitPriceCents: 6000,
      ),
    ],
  );

  test('creates an order and reads it back with its parts', () async {
    final id = await repository.create(order);
    final saved = await repository.findById(id);

    expect(saved, isNotNull);
    expect(saved!.customerName, 'Clínica Sorriso');
    expect(saved.underWarranty, isFalse);
    expect(saved.equipmentOk, isTrue);
    expect(saved.calledAt, isNull);
    expect(saved.scheduledTime, '14:30');
    expect(saved.items.map((i) => i.description), [
      'Rolamentos 3604',
      'Lâminas do cabeçote',
    ]);
    expect(saved.partsTotalCents, 28000);
    expect(saved.totalCents, 38000);
    expect(saved.createdAt, now);
  });

  test('stores dates without time', () async {
    final id = await repository.create(
      ServiceOrder(calledAt: DateTime(2026, 10, 20, 15, 45)),
    );

    final saved = await repository.findById(id);
    expect(saved!.calledAt, DateTime(2026, 10, 20));
  });

  test('update replaces fields and parts', () async {
    final id = await repository.create(order);
    final saved = await repository.findById(id);

    now = DateTime(2026, 10, 26);
    await repository.update(
      ServiceOrder(
        id: saved!.id,
        orderNumber: saved.orderNumber,
        customerName: 'Clínica Nova',
        items: const [ServiceOrderItem(description: 'Correia')],
      ),
    );

    final updated = await repository.findById(id);
    expect(updated!.customerName, 'Clínica Nova');
    expect(updated.items.single.description, 'Correia');
    expect(updated.createdAt, DateTime(2026, 10, 25, 9));
    expect(updated.updatedAt, DateTime(2026, 10, 26));
  });

  test('lists newest first and filters by customer or number', () async {
    await repository.create(order);
    now = DateTime(2026, 10, 26);
    await repository.create(
      const ServiceOrder(orderNumber: '0002', customerName: 'Dr. Pedro'),
    );

    final all = await repository.list();
    expect(all.map((o) => o.orderNumber), ['0002', '0001']);
    expect(all.last.items, hasLength(2));

    final byName = await repository.list(query: 'sorriso');
    expect(byName.single.orderNumber, '0001');

    final byNumber = await repository.list(query: '0002');
    expect(byNumber.single.customerName, 'Dr. Pedro');
  });

  test('delete removes the order and its parts', () async {
    final id = await repository.create(order);
    await repository.delete(id);

    expect(await repository.findById(id), isNull);
    final items = await database.db.query('service_order_items');
    expect(items, isEmpty);
  });
}
