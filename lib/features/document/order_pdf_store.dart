import 'dart:typed_data';

import '../../core/formatting/region_format.dart';
import '../../core/storage/pdf_folder.dart';
import '../../l10n/app_localizations.dart';
import '../service_order/data/service_order.dart';
import '../service_order/data/service_order_repository.dart';
import '../settings/data/company_profile.dart';
import 'service_order_documents.dart';

/// Keeps each order's PDF in the phone's [PdfFolder] up to date. The
/// order remembers its file (`pdf_path`), so saving again overwrites it.
class OrderPdfStore {
  OrderPdfStore({
    required this._folder,
    required this._orders,
    required this._documents,
  });

  final PdfFolder _folder;
  final ServiceOrderRepository _orders;
  final ServiceOrderDocuments _documents;

  /// Saves [pdf] as the file of [order] (already in the database).
  Future<void> store(
    ServiceOrder order,
    Uint8List pdf, {
    required String prefix,
  }) async {
    final uri = await _folder.save(
      '${fileBaseName(order, prefix: prefix)}.pdf',
      pdf,
      replacing: order.pdfPath,
    );
    if (uri != null && uri != order.pdfPath) {
      await _orders.setPdfPath(order.id!, uri);
    }
  }

  /// Deletes the file of an order that is being deleted.
  Future<void> remove(ServiceOrder order) async {
    if (order.pdfPath case final uri?) await _folder.delete(uri);
  }

  /// Builds and saves the PDF of every order again (after restoring a
  /// backup, or for orders saved before the folder existed). Returns how
  /// many were saved.
  Future<int> storeAll({
    required CompanyProfile company,
    required AppLocalizations l10n,
    required RegionFormat format,
    void Function(int done, int total)? onProgress,
  }) async {
    final orders = await _orders.list();
    for (final (index, order) in orders.indexed) {
      final pdf = await _documents.buildPdf(
        order,
        company,
        l10n: l10n,
        format: format,
      );
      await store(order, pdf, prefix: l10n.pdfFilePrefix);
      onProgress?.call(index + 1, orders.length);
    }
    return orders.length;
  }
}
