import 'package:flutter/painting.dart';

import '../../../core/config/client_config.dart';

/// Company data the user can edit in the app.
enum CompanyField { name, document, phone, address, city, state, responsible }

/// Company data as shown in the app and on the PDF: what the user edited,
/// falling back to the build defaults from `clients/<folder>/config.json`.
///
/// Changes apply to every order, old and new, except the responsible name,
/// which each order keeps as a snapshot.
class CompanyProfile {
  const CompanyProfile({
    required this.defaults,
    this.overrides = const {},
    this.customLogoFile,
  });

  /// Factory defaults from the build.
  final ClientConfig defaults;

  /// Only the fields the user changed.
  final Map<CompanyField, String> overrides;

  /// File name of a logo picked in the app (inside the app's private
  /// folder). Null means the flavor's bundled logo is used.
  final String? customLogoFile;

  String value(CompanyField field) => overrides[field] ?? defaultValue(field);

  String defaultValue(CompanyField field) => switch (field) {
        CompanyField.name => defaults.companyName,
        CompanyField.document => defaults.companyDocument,
        CompanyField.phone => defaults.companyPhone,
        CompanyField.address => defaults.companyAddress,
        CompanyField.city => defaults.companyCity,
        CompanyField.state => defaults.companyState,
        CompanyField.responsible => defaults.companyResponsible,
      };

  bool isCustomized(CompanyField field) => overrides.containsKey(field);

  bool get hasCustomLogo => customLogoFile != null;

  String get companyName => value(CompanyField.name);
  String get companyDocument => value(CompanyField.document);
  String get companyPhone => value(CompanyField.phone);
  String get companyAddress => value(CompanyField.address);
  String get companyCity => value(CompanyField.city);
  String get companyState => value(CompanyField.state);
  String get responsibleName => value(CompanyField.responsible);

  /// Not editable in the app.
  Color get brandColor => defaults.brandColor;

  /// The flavor's logo, used when there is no custom one (or it went missing).
  String get defaultLogoAsset => defaults.logoAsset;
}
