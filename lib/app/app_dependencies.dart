import '../core/config/client_config.dart';
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
  });

  final ClientConfig config;
  final ServiceOrderRepository orders;
  final SettingsRepository settings;
  final ServiceOrderDocuments documents;
}
