import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:service_order_app/core/config/client_config.dart';
import 'package:service_order_app/core/database/app_database.dart';
import 'package:service_order_app/features/settings/data/company_profile.dart';
import 'package:service_order_app/features/settings/data/settings_repository.dart';

const _defaults = ClientConfig(
  channel: 'val',
  companyName: 'AC Serviços',
  companyDocument: '35.183.961/0001-63',
  companyPhone: '(99) 98456-4555',
  companyAddress: 'Rua Sá Sobrinho, 26 - Centro',
  companyCity: 'São João dos Patos',
  companyState: 'MA',
  companyResponsible: 'Valdejane',
  brandColor: Color(0xFF1F5FBF),
  logoAsset: 'clients/private/val/branding/logo.jpeg',
);

void main() {
  late AppDatabase database;
  late SettingsRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = SettingsRepository(database);
  });

  tearDown(() => database.close());

  test('without edits, the profile is the build config', () async {
    final profile = await repository.companyProfile(_defaults);

    expect(profile.companyName, 'AC Serviços');
    expect(profile.companyPhone, '(99) 98456-4555');
    expect(profile.responsibleName, 'Valdejane');
    expect(profile.overrides, isEmpty);
    expect(profile.hasCustomLogo, isFalse);
  });

  test('edited fields override the defaults, the rest keep following them',
      () async {
    await repository.saveCompanyFields(_defaults, {
      CompanyField.phone: ' (99) 99999-0000 ',
      CompanyField.responsible: 'Valdejane Souza',
    });

    final profile = await repository.companyProfile(_defaults);
    expect(profile.companyPhone, '(99) 99999-0000');
    expect(profile.responsibleName, 'Valdejane Souza');
    expect(profile.isCustomized(CompanyField.phone), isTrue);
    expect(profile.companyName, 'AC Serviços');
    expect(profile.isCustomized(CompanyField.name), isFalse);
  });

  test('saving the default value removes the override', () async {
    await repository.saveCompanyFields(_defaults, {CompanyField.city: 'Floriano'});
    await repository.saveCompanyFields(
      _defaults,
      {CompanyField.city: 'São João dos Patos'},
    );

    final profile = await repository.companyProfile(_defaults);
    expect(profile.isCustomized(CompanyField.city), isFalse);
  });

  test('a field can be intentionally cleared', () async {
    await repository.saveCompanyFields(_defaults, {CompanyField.document: ''});

    final profile = await repository.companyProfile(_defaults);
    expect(profile.companyDocument, '');
    expect(profile.isCustomized(CompanyField.document), isTrue);
  });

  test('responsible name saved by the previous version is kept', () async {
    await database.db.insert('app_settings', {
      'key': 'responsible_name',
      'value': 'Valdejane Silva',
    });

    final profile = await repository.companyProfile(_defaults);
    expect(profile.responsibleName, 'Valdejane Silva');
  });

  test('custom logo is stored and can be removed', () async {
    await repository.setCustomLogoFile('logo_123.png');
    expect((await repository.companyProfile(_defaults)).customLogoFile, 'logo_123.png');

    await repository.setCustomLogoFile(null);
    expect((await repository.companyProfile(_defaults)).hasCustomLogo, isFalse);
  });

  test('reset restores every field and the logo', () async {
    await repository.saveCompanyFields(_defaults, {
      CompanyField.name: 'Outra',
      CompanyField.responsible: 'Fulano',
    });
    await repository.setCustomLogoFile('logo_123.png');

    await repository.resetCompany();

    final profile = await repository.companyProfile(_defaults);
    expect(profile.overrides, isEmpty);
    expect(profile.hasCustomLogo, isFalse);
  });
}
