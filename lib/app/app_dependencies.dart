import '../core/config/client_config.dart';
import '../core/preferences/app_preferences.dart';
import '../core/storage/logo_storage.dart';
import '../core/storage/pdf_folder.dart';
import '../features/backup/backup_service.dart';
import '../features/document/order_pdf_store.dart';
import '../features/document/service_order_documents.dart';
import '../features/service_order/data/service_order_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/update/update_checker.dart';
import '../features/update/update_installer.dart';
import '../l10n/app_localizations.dart';

/// Everything the screens need, created once in main.dart and passed down.
///
/// Tests build this with fake repositories.
class AppDependencies {
  const AppDependencies({
    required this.config,
    required this.orders,
    required this.settings,
    required this.documents,
    required this.logos,
    required this.updates,
    required this.installer,
    required this.preferences,
    required this.backup,
    this.pdfFolder = const PdfFolder(),
    this.checkUpdatesOnStartup = true,
  });

  /// Build defaults. Screens showing company data should read
  /// `settings.companyProfile(companyDefaults)` instead, which includes
  /// user edits and translates the example company.
  final ClientConfig config;
  final ServiceOrderRepository orders;
  final SettingsRepository settings;
  final ServiceOrderDocuments documents;
  final LogoStorage logos;
  final UpdateChecker updates;
  final UpdateInstaller installer;

  /// Language and regional format (Settings).
  final AppPreferences preferences;

  /// Export (and later restore) of all the app data.
  final BackupService backup;

  /// Public folder where every saved order gets its PDF.
  final PdfFolder pdfFolder;

  /// Whether to look for a new version when the app opens. The manual
  /// check in Settings works either way.
  final bool checkUpdatesOnStartup;

  /// Saves, replaces and deletes the orders' files in [pdfFolder].
  OrderPdfStore get pdfStore =>
      OrderPdfStore(folder: pdfFolder, orders: orders, documents: documents);

  /// Company defaults in the current app language (the generic app's
  /// example company is translated). Use this, not [config], with
  /// `settings.companyProfile(...)` and `settings.saveCompanyFields(...)`.
  ClientConfig get companyDefaults =>
      config.localized(lookupAppLocalizations(preferences.locale));
}
