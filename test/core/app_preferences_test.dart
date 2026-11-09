import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/core/formatting/region_format.dart';
import 'package:service_order_app/core/preferences/app_preferences.dart';

import '../fakes.dart';

void main() {
  AppPreferences preferences({
    LanguagePreference language = LanguagePreference.system,
    RegionPreference region = RegionPreference.system,
    Locale device = const Locale('pt', 'BR'),
  }) =>
      AppPreferences.fixed(
        FakeSettingsRepository(),
        language: language,
        region: region,
        deviceLocale: () => device,
      );

  test('automatic language follows the phone', () {
    expect(preferences().locale, AppPreferences.portuguese);
    expect(
      preferences(device: const Locale('es', 'ES')).locale,
      AppPreferences.english,
    );
  });

  test('automatic format follows the phone country', () {
    expect(preferences().format, RegionFormat.brazil);
    expect(
      preferences(device: const Locale('en', 'US')).format,
      RegionFormat.unitedStates,
    );
    // English phone in Brazil keeps Brazilian formats.
    expect(
      preferences(device: const Locale('en', 'BR')).format,
      RegionFormat.brazil,
    );
  });

  test('language and format can be combined freely', () {
    final p = preferences(
      language: LanguagePreference.english,
      region: RegionPreference.brazil,
    );
    expect(p.locale, AppPreferences.english);
    expect(p.format, RegionFormat.brazil);
  });

  test('choices are saved and reloaded', () async {
    final settings = FakeSettingsRepository();
    final p = await AppPreferences.load(settings);

    var notified = 0;
    p.addListener(() => notified++);
    await p.setLanguage(LanguagePreference.english);
    await p.setRegion(RegionPreference.unitedStates);
    expect(notified, 2);

    final reloaded = await AppPreferences.load(settings);
    expect(reloaded.language, LanguagePreference.english);
    expect(reloaded.region, RegionPreference.unitedStates);

    // Back to automatic removes the saved value.
    await reloaded.setLanguage(LanguagePreference.system);
    expect(await settings.preference('language'), isNull);
  });
}
