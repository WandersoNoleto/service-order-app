import '../core/config/client_config.dart';
import '../core/storage/logo_storage.dart';
import '../features/document/service_order_documents.dart';
import '../features/service_order/data/service_order_repository.dart';
import '../features/settings/data/settings_repository.dart';

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
  });

  /// Build defaults. Screens showing company data should read
  /// `settings.companyProfile(config)` instead, which includes user edits.
  final ClientConfig config;
  final ServiceOrderRepository orders;
  final SettingsRepository settings;
  final ServiceOrderDocuments documents;
  final LogoStorage logos;
}
