import 'package:flutter/painting.dart';

/// Branding and company data for the client this build belongs to.
///
/// Values are injected at build time from `clients/<folder>/config.json`
/// using `--dart-define-from-file`.
class ClientConfig {
  const ClientConfig({
    required this.channel,
    required this.companyName,
    required this.companyDocument,
    required this.companyPhone,
    required this.companyAddress,
    required this.companyCity,
    required this.companyState,
    required this.companyResponsible,
    required this.brandColor,
    required this.logoAsset,
  });

  factory ClientConfig.fromEnvironment() {
    const brandColorHex = String.fromEnvironment(
      'BRAND_COLOR',
      defaultValue: 'FF1B1B1B',
    );

    return ClientConfig(
      channel: const String.fromEnvironment('APP_CHANNEL'),
      companyName: const String.fromEnvironment('COMPANY_NAME'),
      companyDocument: const String.fromEnvironment('COMPANY_DOCUMENT'),
      companyPhone: const String.fromEnvironment('COMPANY_PHONE'),
      companyAddress: const String.fromEnvironment('COMPANY_ADDRESS'),
      companyCity: const String.fromEnvironment('COMPANY_CITY'),
      companyState: const String.fromEnvironment('COMPANY_STATE'),
      companyResponsible: const String.fromEnvironment('COMPANY_RESPONSIBLE'),
      brandColor: Color(int.parse(brandColorHex, radix: 16)),
      logoAsset: const String.fromEnvironment('LOGO_ASSET'),
    );
  }

  /// Release channel used by the auto-update ("" for the generic build).
  final String channel;
  final String companyName;
  final String companyDocument;
  final String companyPhone;
  final String companyAddress;
  final String companyCity;
  final String companyState;
  final String companyResponsible;
  final Color brandColor;
  final String logoAsset;

  /// False when the app was started without `--dart-define-from-file`.
  bool get isConfigured => companyName.isNotEmpty && logoAsset.isNotEmpty;
}
