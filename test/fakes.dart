import 'package:flutter/painting.dart';

import 'package:service_order_app/app/app_dependencies.dart';
import 'package:service_order_app/core/config/client_config.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/service_order/data/service_order_repository.dart';
import 'package:service_order_app/features/settings/data/settings_repository.dart';

/// In-memory repositories for widget tests (real SQLite is covered by the
/// repository tests).
AppDependencies fakeDependencies({String responsible = 'Valdejane'}) {
  return AppDependencies(
    config: ClientConfig(
      channel: '',
      companyName: 'Empresa Teste',
      companyDocument: '',
      companyPhone: '',
      companyAddress: '',
      companyCity: '',
      companyState: '',
      companyResponsible: responsible,
      brandColor: const Color(0xFF1B1B1B),
      logoAsset: '',
    ),
    orders: FakeServiceOrderRepository(),
    settings: FakeSettingsRepository(),
  );
}

class FakeServiceOrderRepository implements ServiceOrderRepository {
  final _orders = <int, ServiceOrder>{};
  var _nextId = 1;

  @override
  Future<int> create(ServiceOrder order) async {
    final id = _nextId++;
    _orders[id] = _withId(order, id);
    return id;
  }

  @override
  Future<void> update(ServiceOrder order) async {
    _orders[order.id!] = _withId(order, order.id!);
  }

  @override
  Future<ServiceOrder?> findById(int id) async => _orders[id];

  @override
  Future<List<ServiceOrder>> list({String query = ''}) async {
    final term = query.trim().toLowerCase();
    return _orders.values
        .where(
          (o) =>
              term.isEmpty ||
              o.customerName.toLowerCase().contains(term) ||
              o.orderNumber.contains(term),
        )
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<void> setPdfPath(int id, String path) async {}

  @override
  Future<void> delete(int id) async => _orders.remove(id);

  ServiceOrder _withId(ServiceOrder order, int id) {
    final now = DateTime(2026, 10, 25).toIso8601String();
    return ServiceOrder.fromMap(
      {...order.toMap(), 'id': id, 'created_at': now, 'updated_at': now},
      items: order.items,
    );
  }
}

class FakeSettingsRepository implements SettingsRepository {
  String? _responsibleName;

  @override
  Future<String> responsibleName({required String fallback}) async =>
      _responsibleName ?? fallback;

  @override
  Future<void> setResponsibleName(String name) async =>
      _responsibleName = name.trim();
}
