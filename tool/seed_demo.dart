// Fills the app with a demo company and a few weeks of service orders, then
// starts the app (with the startup update prompt turned off). Used for the
// README screenshots. All names, documents and phones are fictional.
//
// English (US formats), the default:
//   flutter run --flavor standard --dart-define-from-file=clients/default/config.json -t tool/seed_demo.dart
// Portuguese (Brazilian formats): add --dart-define=DEMO_LANGUAGE=pt
//
// Only seeds an empty database. To start over, clear the app data:
//   adb shell pm clear com.wandersonnoleto.service_order_app
// Never run it with a client flavor on that client's phone (same app id).
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:service_order_app/app/app.dart';
import 'package:service_order_app/app/app_dependencies.dart';
import 'package:service_order_app/core/config/client_config.dart';
import 'package:service_order_app/core/database/app_database.dart';
import 'package:service_order_app/core/preferences/app_preferences.dart';
import 'package:service_order_app/core/storage/logo_storage.dart';
import 'package:service_order_app/features/document/service_order_documents.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/service_order/data/service_order_repository.dart';
import 'package:service_order_app/features/settings/data/company_profile.dart';
import 'package:service_order_app/features/settings/data/settings_repository.dart';
import 'package:service_order_app/features/update/update_checker.dart';
import 'package:service_order_app/features/update/update_installer.dart';

typedef _Customer = ({
  String name,
  String document,
  String phone,
  String address,
  String city,
  String state,
  String zip,
});
typedef _Part = ({int quantity, String code, String name, int cents});

/// A kind of call, with the parts it usually takes.
typedef _Job = ({String service, List<_Part> parts});

/// Everything that depends on the demo language.
class _DemoData {
  const _DemoData({
    required this.language,
    required this.region,
    required this.company,
    required this.customers,
    required this.jobs,
    required this.notes,
    required this.laborSteps,
  });

  final LanguagePreference language;
  final RegionPreference region;
  final Map<CompanyField, String> company;
  final List<_Customer> customers;
  final List<_Job> jobs;
  final List<String> notes;

  /// Labor charged, in cents: one of these values.
  final List<int> laborSteps;
}

const _english = _DemoData(
  language: LanguagePreference.english,
  region: RegionPreference.unitedStates,
  company: {
    CompanyField.name: 'Bluepine Climate & Appliance',
    CompanyField.document: '84-2917365',
    CompanyField.phone: '(512) 555-0142',
    CompanyField.address: '2210 Ridgeview Dr, Suite 4',
    CompanyField.city: 'Austin',
    CompanyField.state: 'TX',
    CompanyField.responsible: 'Mike Carter',
  },
  customers: [
    (name: 'Lakeside Grill', document: '74-3158204', phone: '(512) 555-0187', address: '880 Lakeshore Blvd', city: 'Austin', state: 'TX', zip: '78741'),
    (name: 'Emily Johnson', document: '', phone: '(512) 555-0123', address: '417 Maple Hollow Ln', city: 'Round Rock', state: 'TX', zip: '78664'),
    (name: 'Cedar Park Dental', document: '61-4820937', phone: '(512) 555-0164', address: '1300 Discovery Blvd, Ste 210', city: 'Cedar Park', state: 'TX', zip: '78613'),
    (name: 'Robert Martinez', document: '', phone: '(737) 555-0119', address: '92 Willow Creek Dr', city: 'Pflugerville', state: 'TX', zip: '78660'),
    (name: 'Sunrise Bakery', document: '83-1069452', phone: '(512) 555-0198', address: '305 E 6th St', city: 'Austin', state: 'TX', zip: '78701'),
    (name: 'Hillcrest Apartments', document: '45-7713280', phone: '(512) 555-0135', address: '1550 Hillcrest Ave', city: 'Austin', state: 'TX', zip: '78723'),
    (name: 'Sarah Thompson', document: '', phone: '(737) 555-0171', address: '28 Bluebonnet Way', city: 'Georgetown', state: 'TX', zip: '78626'),
    (name: 'Green Leaf Market', document: '27-5594016', phone: '(512) 555-0109', address: '4021 S Congress Ave', city: 'Austin', state: 'TX', zip: '78745'),
    (name: 'David Nguyen', document: '', phone: '(512) 555-0156', address: '7 Oak Ridge Ct', city: 'Leander', state: 'TX', zip: '78641'),
    (name: 'Riverside Fitness', document: '92-3307185', phone: '(512) 555-0148', address: '2400 Riverside Dr', city: 'Austin', state: 'TX', zip: '78741'),
  ],
  jobs: [
    (
      service: 'AC not cooling. Replaced run capacitor and contactor; system cooling normally, 18 °F temperature split.',
      parts: [
        (quantity: 1, code: 'CAP-455', name: 'Dual run capacitor 45/5 µF', cents: 2850),
        (quantity: 1, code: 'CT-40A', name: 'Contactor 40 A, 24 V coil', cents: 3400),
      ],
    ),
    (
      service: 'Seasonal AC maintenance: cleaned condenser coil, checked refrigerant charge and replaced filters.',
      parts: [
        (quantity: 2, code: 'FLT-1625', name: 'Air filter 16x25x1, MERV 11', cents: 1490),
      ],
    ),
    (
      service: 'Found refrigerant leak at the service valve. Repaired, pressure tested with nitrogen and recharged.',
      parts: [
        (quantity: 1, code: 'CU-BRZ', name: 'Copper fittings and brazing', cents: 1800),
        (quantity: 4, code: 'R410A', name: 'Refrigerant R-410A (lb)', cents: 6500),
      ],
    ),
    (
      service: 'Condenser fan not spinning. Replaced fan motor and capacitor; checked amperage.',
      parts: [
        (quantity: 1, code: 'CFM-14', name: 'Condenser fan motor 1/4 HP', cents: 18900),
        (quantity: 1, code: 'CAP-455', name: 'Dual run capacitor 45/5 µF', cents: 2850),
      ],
    ),
    (
      service: 'Furnace not igniting. Replaced igniter, cleaned flame sensor and tested a full heating cycle.',
      parts: [
        (quantity: 1, code: 'IGN-HS', name: 'Hot surface igniter', cents: 4200),
      ],
    ),
    (
      service: 'Installed and configured a new Wi-Fi thermostat. Explained scheduling to the customer.',
      parts: [
        (quantity: 1, code: 'TST-WF', name: 'Wi-Fi programmable thermostat', cents: 11900),
      ],
    ),
    (
      service: 'Walk-in cooler not holding temperature. Replaced defrost timer and door gasket.',
      parts: [
        (quantity: 1, code: 'DT-8H', name: 'Defrost timer', cents: 3900),
        (quantity: 1, code: 'GSK-WC', name: 'Walk-in cooler door gasket', cents: 8600),
      ],
    ),
    (
      service: 'Washer not draining. Replaced drain pump and cleared the hose.',
      parts: [
        (quantity: 1, code: 'DP-WM', name: 'Washer drain pump', cents: 7800),
      ],
    ),
    (
      service: 'Weak airflow on all vents. Replaced blower motor and filter.',
      parts: [
        (quantity: 1, code: 'BLW-12', name: 'Blower motor 1/2 HP', cents: 24500),
        (quantity: 1, code: 'FLT-1625', name: 'Air filter 16x25x1, MERV 11', cents: 1490),
      ],
    ),
    (
      service: 'Water leaking from the indoor unit. Cleared the condensate drain line and treated the pan.',
      parts: [],
    ),
  ],
  notes: [
    '',
    '',
    'Recommended a maintenance plan every 6 months.',
    'Unit is 14 years old; customer will consider a replacement quote.',
    'Customer was not home; tenant authorized the service.',
    'Old parts handed to the customer.',
  ],
  laborSteps: [8500, 9500, 12000, 14500, 16500, 19500, 22000],
);

const _portuguese = _DemoData(
  language: LanguagePreference.portuguese,
  region: RegionPreference.brazil,
  company: {
    CompanyField.name: 'Pinheiro Climatização',
    CompanyField.document: '12.345.678/0001-90',
    CompanyField.phone: '(19) 98765-4321',
    CompanyField.address: 'Rua das Acácias, 250 - Centro',
    CompanyField.city: 'Campinas',
    CompanyField.state: 'SP',
    CompanyField.responsible: 'Rafael Souza',
  },
  customers: [
    (name: 'Restaurante Sabor da Serra', document: '23.456.789/0001-01', phone: '(19) 99123-4567', address: 'Av. Brasil, 1500', city: 'Campinas', state: 'SP', zip: '13070-000'),
    (name: 'Mariana Alves', document: '123.456.789-00', phone: '(19) 98234-5678', address: 'Rua dos Ipês, 42', city: 'Valinhos', state: 'SP', zip: '13270-000'),
    (name: 'Clínica Bem Estar', document: '34.567.890/0001-12', phone: '(19) 99345-6789', address: 'Rua Barão de Jaguara, 980, sala 12', city: 'Campinas', state: 'SP', zip: '13015-000'),
    (name: 'Carlos Eduardo Ramos', document: '234.567.890-11', phone: '(19) 98456-7890', address: 'Rua Ametista, 115', city: 'Hortolândia', state: 'SP', zip: '13184-000'),
    (name: 'Padaria Pão Dourado', document: '45.678.901/0001-23', phone: '(19) 99567-8901', address: 'Av. Andrade Neves, 320', city: 'Campinas', state: 'SP', zip: '13013-000'),
    (name: 'Condomínio Jardim das Flores', document: '56.789.012/0001-34', phone: '(19) 98678-9012', address: 'Rua das Hortênsias, 600', city: 'Sumaré', state: 'SP', zip: '13170-000'),
    (name: 'Fernanda Lima', document: '345.678.901-22', phone: '(19) 99789-0123', address: 'Rua Tiradentes, 77', city: 'Paulínia', state: 'SP', zip: '13140-000'),
    (name: 'Mercado Bom Preço', document: '67.890.123/0001-45', phone: '(19) 98890-1234', address: 'Av. John Boyd Dunlop, 2100', city: 'Campinas', state: 'SP', zip: '13060-000'),
  ],
  jobs: [
    (
      service: 'Ar não gelava. Troca do capacitor e da contatora; equipamento resfriando normalmente.',
      parts: [
        (quantity: 1, code: 'CAP-35', name: 'Capacitor 35 µF', cents: 4500),
        (quantity: 1, code: 'CT-25A', name: 'Contatora 25 A', cents: 8900),
      ],
    ),
    (
      service: 'Manutenção preventiva: limpeza da evaporadora e da condensadora, troca dos filtros.',
      parts: [
        (quantity: 2, code: 'FT-AR', name: 'Filtro de ar', cents: 3500),
      ],
    ),
    (
      service: 'Vazamento de gás na válvula de serviço. Reparo, teste de pressão com nitrogênio e recarga.',
      parts: [
        (quantity: 1, code: 'CU-SD', name: 'Conexões de cobre e solda', cents: 9000),
        (quantity: 2, code: 'R410A', name: 'Gás refrigerante R-410A (kg)', cents: 18000),
      ],
    ),
    (
      service: 'Ventilador da condensadora parado. Troca do motor e do capacitor, teste de corrente.',
      parts: [
        (quantity: 1, code: 'MV-CD', name: 'Motor ventilador da condensadora', cents: 32000),
        (quantity: 1, code: 'CAP-35', name: 'Capacitor 35 µF', cents: 4500),
      ],
    ),
    (
      service: 'Evaporadora sem ligar. Troca da placa eletrônica e configuração do controle.',
      parts: [
        (quantity: 1, code: 'PL-EL', name: 'Placa eletrônica da evaporadora', cents: 68000),
      ],
    ),
    (
      service: 'Câmara fria sem manter temperatura. Troca do sensor e da borracha da porta.',
      parts: [
        (quantity: 1, code: 'SN-TP', name: 'Sensor de temperatura', cents: 6500),
        (quantity: 1, code: 'BR-PT', name: 'Borracha de vedação da porta', cents: 14000),
      ],
    ),
    (
      service: 'Evaporadora pingando. Instalação de bomba de dreno e limpeza da bandeja.',
      parts: [
        (quantity: 1, code: 'BD-DR', name: 'Bomba de dreno', cents: 21000),
      ],
    ),
    (
      service: 'Instalação de split 12.000 BTUs com tubulação de 3 metros.',
      parts: [
        (quantity: 3, code: 'TB-CU', name: 'Tubulação de cobre 1/4" e 3/8" (m)', cents: 6500),
        (quantity: 1, code: 'SP-SU', name: 'Suporte da condensadora', cents: 7500),
      ],
    ),
  ],
  notes: [
    '',
    '',
    'Recomendada manutenção preventiva a cada 6 meses.',
    'Equipamento com mais de 10 anos; cliente vai avaliar a troca.',
    'Cliente ausente; serviço autorizado pelo zelador.',
    'Peças substituídas entregues ao cliente.',
  ],
  laborSteps: [15000, 18000, 22000, 25000, 30000, 35000, 45000],
);

/// How far back the history goes, and the first order number in it (the
/// company was already running before).
const _days = 24;
const _firstNumber = 137;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final data = const String.fromEnvironment('DEMO_LANGUAGE') == 'pt'
      ? _portuguese
      : _english;

  final database = await AppDatabase.open();
  final config = ClientConfig.fromEnvironment();
  final settings = SettingsRepository(database);
  final preferences = await AppPreferences.load(settings);
  final logos = LogoStorage();
  final dependencies = AppDependencies(
    config: config,
    orders: ServiceOrderRepository(database),
    settings: settings,
    documents: ServiceOrderDocuments(logos),
    logos: logos,
    updates: UpdateChecker(channel: config.channel),
    installer: UpdateInstaller(),
    preferences: preferences,
    // The demo has the pubspec version, so a published build would always
    // look newer. The manual check in Settings still works.
    checkUpdatesOnStartup: false,
  );

  final existing = await database.db.query('service_orders', limit: 1);
  if (existing.isEmpty) {
    await preferences.setLanguage(data.language);
    await preferences.setRegion(data.region);
    await settings.saveCompanyFields(
      dependencies.companyDefaults,
      data.company,
    );
    await _seedOrders(database, data);
  } else {
    debugPrint('seed_demo: database already has orders, nothing seeded');
  }

  runApp(ServiceOrderApp(dependencies: dependencies));
}

/// A working day's worth of calls on each weekday, numbered in the order
/// they were created, like a real history.
Future<void> _seedOrders(AppDatabase database, _DemoData data) async {
  final random = Random(7);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final times = <DateTime>[];
  for (var daysAgo = _days; daysAgo >= 0; daysAgo--) {
    final day = today.subtract(Duration(days: daysAgo));
    if (day.weekday == DateTime.sunday) continue;

    // Today and yesterday are always busy, so the first screen is full.
    if (daysAgo == 0) {
      // Earlier today, all before now.
      times.addAll([
        for (final minutes in [260, 130, 35])
          now.subtract(Duration(minutes: minutes)),
      ]);
      continue;
    }
    final count = switch (daysAgo) {
      1 => 2,
      _ when day.weekday == DateTime.saturday => 1,
      _ => 1 + random.nextInt(3),
    };
    final minutes = [
      for (var i = 0; i < count; i++) 8 * 60 + random.nextInt(9 * 60),
    ]..sort();
    times.addAll([for (final m in minutes) day.add(Duration(minutes: m))]);
  }

  final recent = <_Customer>[];
  for (final (index, createdAt) in times.indexed) {
    // A regular customer comes back often, everyone else at random (not
    // among the last few orders).
    var customer = data.customers.first;
    if (index % 5 != 0) {
      while (customer == data.customers.first || recent.contains(customer)) {
        customer = data.customers[random.nextInt(data.customers.length)];
      }
    }
    recent.add(customer);
    if (recent.length > 3) recent.removeAt(0);

    final job = data.jobs[random.nextInt(data.jobs.length)];
    final items = [
      for (final part in job.parts)
        ServiceOrderItem(
          quantity: part.quantity,
          code: part.code,
          description: part.name,
          unitPriceCents: part.cents,
        ),
    ];

    final calledAt = createdAt.subtract(Duration(days: 1 + random.nextInt(3)));
    final scheduledFor = DateTime(calledAt.year, calledAt.month, calledAt.day + 1);
    final repository = ServiceOrderRepository(database, clock: () => createdAt);
    await repository.create(
      ServiceOrder(
        orderNumber: (_firstNumber + index).toString().padLeft(4, '0'),
        responsibleName: data.company[CompanyField.responsible]!,
        customerName: customer.name,
        customerDocument: customer.document,
        customerAddress: customer.address,
        customerCity: customer.city,
        customerState: customer.state,
        customerContact: customer.phone,
        customerZip: customer.zip,
        invoiceNumber: random.nextInt(3) == 0 ? '${4210 + index}' : '',
        underWarranty: random.nextInt(4) == 0,
        calledAt: calledAt,
        scheduledFor: scheduledFor,
        scheduledTime: '${(8 + random.nextInt(9)).toString().padLeft(2, '0')}:'
            '${random.nextBool() ? '00' : '30'}',
        installedAt: random.nextInt(3) == 0 ? createdAt : null,
        servicesPerformed: job.service,
        notes: data.notes[random.nextInt(data.notes.length)],
        laborCents: data.laborSteps[random.nextInt(data.laborSteps.length)],
        equipmentOk: random.nextInt(8) != 0,
        items: items,
      ),
    );
  }
  debugPrint('seed_demo: created ${times.length} demo orders');
}
