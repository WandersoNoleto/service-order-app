import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/config/client_config.dart';

/// Fonts and logo used by the PDF, loaded once from the app bundle.
class PdfAssets {
  const PdfAssets({required this.regular, required this.bold, this.logo});

  static const regularFontAsset = 'assets/fonts/LiberationSans-Regular.ttf';
  static const boldFontAsset = 'assets/fonts/LiberationSans-Bold.ttf';

  final pw.Font regular;
  final pw.Font bold;

  /// Null when the client has no logo; the header then shows the company name.
  final pw.ImageProvider? logo;

  static Future<PdfAssets> load(ClientConfig config, {AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;

    pw.ImageProvider? logo;
    if (config.logoAsset.isNotEmpty) {
      try {
        final data = await assets.load(config.logoAsset);
        logo = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        // A missing asset throws a FlutterError, not an Exception.
        logo = null;
      }
    }

    return PdfAssets(
      regular: pw.Font.ttf(await assets.load(regularFontAsset)),
      bold: pw.Font.ttf(await assets.load(boldFontAsset)),
      logo: logo,
    );
  }
}
