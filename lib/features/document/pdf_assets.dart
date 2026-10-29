import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Fonts and logo used by the PDF.
class PdfAssets {
  const PdfAssets({required this.regular, required this.bold, this.logo});

  static const regularFontAsset = 'assets/fonts/LiberationSans-Regular.ttf';
  static const boldFontAsset = 'assets/fonts/LiberationSans-Bold.ttf';

  final pw.Font regular;
  final pw.Font bold;

  /// Null when there is no logo at all; the header then shows the name.
  final pw.ImageProvider? logo;

  PdfAssets withLogo(pw.ImageProvider? logo) =>
      PdfAssets(regular: regular, bold: bold, logo: logo);

  static Future<PdfAssets> loadFonts({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    return PdfAssets(
      regular: pw.Font.ttf(await assets.load(regularFontAsset)),
      bold: pw.Font.ttf(await assets.load(boldFontAsset)),
    );
  }

  /// The logo picked in the app ([customFile]) when it exists, otherwise
  /// the flavor's bundled logo ([fallbackAsset]).
  static Future<pw.ImageProvider?> loadLogo({
    File? customFile,
    required String fallbackAsset,
    AssetBundle? bundle,
  }) async {
    if (customFile != null) {
      try {
        return pw.MemoryImage(await customFile.readAsBytes());
      } on FileSystemException {
        // Fall through to the bundled logo.
      }
    }

    if (fallbackAsset.isEmpty) return null;
    try {
      final data = await (bundle ?? rootBundle).load(fallbackAsset);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // A missing asset throws a FlutterError, not an Exception.
      return null;
    }
  }
}
