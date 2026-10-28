import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/storage/logo_storage.dart';
import '../service_order/data/service_order.dart';
import '../settings/data/company_profile.dart';
import 'pdf_assets.dart';
import 'service_order_pdf.dart';

/// Turns a saved order into files: PDF, page images, share and print.
///
/// Files are always generated from the database, so nothing here is
/// permanent: shared files go to the app's temporary folder.
class ServiceOrderDocuments {
  ServiceOrderDocuments(this._logos);

  final LogoStorage _logos;

  /// Fonts never change, so they are loaded once.
  PdfAssets? _fonts;

  /// Resolution of the page images (preview and "share as image").
  static const imageDpi = 200.0;

  /// Uses the company data as it is now (edited values or build defaults).
  /// A custom logo that went missing falls back to the bundled one.
  Future<Uint8List> buildPdf(ServiceOrder order, CompanyProfile company) async {
    _fonts ??= await PdfAssets.loadFonts();
    final logo = await PdfAssets.loadLogo(
      customFile: await _logos.resolve(company.customLogoFile),
      fallbackAsset: company.defaultLogoAsset,
    );

    return buildServiceOrderPdf(
      order: order,
      company: company,
      assets: _fonts!.withLogo(logo),
    );
  }

  /// One PNG per page.
  Future<List<Uint8List>> renderPages(Uint8List pdf) async {
    final pages = <Uint8List>[];
    await for (final page in Printing.raster(pdf, dpi: imageDpi)) {
      pages.add(await page.toPng());
    }
    return pages;
  }

  Future<void> sharePdf(ServiceOrder order, Uint8List pdf) async {
    final file = await _writeTemp('${fileBaseName(order)}.pdf', pdf);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
    );
  }

  Future<void> shareImages(ServiceOrder order, List<Uint8List> pages) async {
    final base = fileBaseName(order);
    final files = <XFile>[];
    for (final (index, png) in pages.indexed) {
      final name = pages.length == 1 ? '$base.png' : '${base}_${index + 1}.png';
      final file = await _writeTemp(name, png);
      files.add(XFile(file.path, mimeType: 'image/png'));
    }
    await SharePlus.instance.share(ShareParams(files: files));
  }

  /// Opens the Android print dialog.
  Future<void> printPdf(ServiceOrder order, Uint8List pdf) {
    return Printing.layoutPdf(
      onLayout: (_) async => pdf,
      name: fileBaseName(order),
      format: PdfPageFormat.a4,
    );
  }

  Future<File> _writeTemp(String name, Uint8List bytes) async {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
    await dir.create(recursive: true);
    return File(p.join(dir.path, name)).writeAsBytes(bytes, flush: true);
  }
}

/// "OS_0001_Clinica_Sorriso" — ASCII only, safe for any app receiving it.
String fileBaseName(ServiceOrder order) {
  final number = order.orderNumber.isNotEmpty ? order.orderNumber : '${order.id}';
  final parts = ['OS', number, if (order.customerName.isNotEmpty) order.customerName];
  return _slug(parts.join('_'));
}

String _slug(String text) {
  const accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  final buffer = StringBuffer();
  for (final char in text.split('')) {
    final lower = char.toLowerCase();
    final plain = accents[lower];
    if (plain != null) {
      buffer.write(char == lower ? plain : plain.toUpperCase());
    } else if (RegExp(r'[A-Za-z0-9]').hasMatch(char)) {
      buffer.write(char);
    } else {
      buffer.write('_');
    }
  }

  final slug = buffer
      .toString()
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return slug.length > 60 ? slug.substring(0, 60) : slug;
}
