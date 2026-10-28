import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import 'package:service_order_app/app/app_dependencies.dart';
import 'package:service_order_app/core/config/client_config.dart';
import 'package:service_order_app/core/storage/logo_storage.dart';
import 'package:service_order_app/features/document/service_order_documents.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/service_order/data/service_order_repository.dart';
import 'package:service_order_app/features/settings/data/company_profile.dart';
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
    documents: FakeServiceOrderDocuments(),
    logos: FakeLogoStorage(),
  );
}

/// Records actions instead of building PDFs or calling Android plugins.
class FakeServiceOrderDocuments implements ServiceOrderDocuments {
  final sharedPdfs = <ServiceOrder>[];
  final sharedImages = <ServiceOrder>[];
  final printed = <ServiceOrder>[];

  /// Company profile used for each PDF built.
  final builtFor = <CompanyProfile>[];

  @override
  Future<Uint8List> buildPdf(ServiceOrder order, CompanyProfile company) async {
    builtFor.add(company);
    return Uint8List(0);
  }

  @override
  Future<List<Uint8List>> renderPages(Uint8List pdf) async => [];

  @override
  Future<void> sharePdf(ServiceOrder order, Uint8List pdf) async =>
      sharedPdfs.add(order);

  @override
  Future<void> shareImages(ServiceOrder order, List<Uint8List> pages) async =>
      sharedImages.add(order);

  @override
  Future<void> printPdf(ServiceOrder order, Uint8List pdf) async =>
      printed.add(order);
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
  final _overrides = <CompanyField, String>{};
  String? _logoFile;

  @override
  Future<CompanyProfile> companyProfile(ClientConfig defaults) async =>
      CompanyProfile(
        defaults: defaults,
        overrides: Map.of(_overrides),
        customLogoFile: _logoFile,
      );

  @override
  Future<void> saveCompanyFields(
    ClientConfig defaults,
    Map<CompanyField, String> values,
  ) async {
    final profile = CompanyProfile(defaults: defaults);
    for (final MapEntry(key: field, value: raw) in values.entries) {
      final value = raw.trim();
      if (value == profile.defaultValue(field)) {
        _overrides.remove(field);
      } else {
        _overrides[field] = value;
      }
    }
  }

  @override
  Future<void> setCustomLogoFile(String? fileName) async => _logoFile = fileName;

  @override
  Future<void> resetCompany() async {
    _overrides.clear();
    _logoFile = null;
  }
}

/// Pretends the user picked [nextPick]; never touches the file system.
class FakeLogoStorage implements LogoStorage {
  String? nextPick;

  @override
  Future<String?> pickAndImport() async => nextPick;

  @override
  Future<String> import(String sourcePath) async => sourcePath;

  @override
  Future<File?> resolve(String? fileName) async => null;

  @override
  Future<void> deleteAllExcept(String? keep) async {}
}
