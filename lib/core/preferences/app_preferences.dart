import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../features/settings/data/settings_repository.dart';
import '../formatting/region_format.dart';

/// App language. [system] follows the phone.
enum LanguagePreference { system, portuguese, english }

/// Money, date and time format, independent of the language.
/// [system] follows the phone.
enum RegionPreference { system, brazil, unitedStates }

/// Language and regional format chosen in Settings, saved in the database.
/// Notifies listeners on change so the whole app switches immediately.
class AppPreferences extends ChangeNotifier {
  AppPreferences._(
    this._settings, {
    required LanguagePreference language,
    required RegionPreference region,
    Locale Function()? deviceLocale,
  })  : _language = language,
        _region = region,
        _deviceLocale =
            deviceLocale ?? (() => PlatformDispatcher.instance.locale);

  /// For tests: fixed values, nothing read from the database.
  @visibleForTesting
  AppPreferences.fixed(
    this._settings, {
    LanguagePreference language = LanguagePreference.portuguese,
    RegionPreference region = RegionPreference.brazil,
    Locale Function()? deviceLocale,
  })  : _language = language,
        _region = region,
        _deviceLocale = deviceLocale ?? (() => const Locale('pt', 'BR'));

  static const _languageKey = 'language';
  static const _regionKey = 'region';

  static const portuguese = Locale('pt', 'BR');
  static const english = Locale('en', 'US');
  static const supportedLocales = [portuguese, english];

  final SettingsRepository _settings;
  final Locale Function() _deviceLocale;
  LanguagePreference _language;
  RegionPreference _region;

  static Future<AppPreferences> load(SettingsRepository settings) async {
    return AppPreferences._(
      settings,
      language: _byName(
        LanguagePreference.values,
        await settings.preference(_languageKey),
        LanguagePreference.system,
      ),
      region: _byName(
        RegionPreference.values,
        await settings.preference(_regionKey),
        RegionPreference.system,
      ),
    );
  }

  LanguagePreference get language => _language;
  RegionPreference get region => _region;

  /// The language actually used: Portuguese for a Portuguese phone,
  /// English otherwise.
  Locale get locale => switch (_language) {
        LanguagePreference.portuguese => portuguese,
        LanguagePreference.english => english,
        LanguagePreference.system =>
          _deviceLocale().languageCode == 'pt' ? portuguese : english,
      };

  /// The format actually used: Brazilian for a phone set to Brazil (or to
  /// Portuguese), US otherwise.
  RegionFormat get format => switch (_region) {
        RegionPreference.brazil => RegionFormat.brazil,
        RegionPreference.unitedStates => RegionFormat.unitedStates,
        RegionPreference.system => _deviceIsBrazilian()
            ? RegionFormat.brazil
            : RegionFormat.unitedStates,
      };

  bool _deviceIsBrazilian() {
    final device = _deviceLocale();
    return device.countryCode == 'BR' ||
        (device.countryCode == null && device.languageCode == 'pt');
  }

  Future<void> setLanguage(LanguagePreference value) async {
    _language = value;
    notifyListeners();
    await _settings.setPreference(
      _languageKey,
      value == LanguagePreference.system ? null : value.name,
    );
  }

  Future<void> setRegion(RegionPreference value) async {
    _region = value;
    notifyListeners();
    await _settings.setPreference(
      _regionKey,
      value == RegionPreference.system ? null : value.name,
    );
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.where((value) => value.name == name).firstOrNull ?? fallback;
}

/// Makes [AppPreferences] available to every screen and rebuilds the
/// screens that read it when the language or format changes.
class PreferencesScope extends InheritedNotifier<AppPreferences> {
  const PreferencesScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);

  static AppPreferences of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PreferencesScope>()!
      .notifier!;
}

/// Shortcut for the regional format of the current screen.
extension RegionFormatContext on BuildContext {
  RegionFormat get format => PreferencesScope.of(this).format;
}
