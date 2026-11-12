import 'package:flutter/services.dart';

/// Public folder on the phone (`Documents/ServiceOrders`) where every saved
/// order gets its PDF. The files stay when the app is uninstalled.
///
/// Android only (MainActivity / PdfFolderChannel.kt), Android 10 or newer.
class PdfFolder {
  const PdfFolder({
    this._channel = const MethodChannel('service_order_app/pdf_folder'),
  });

  final MethodChannel _channel;

  /// False on Android 9 and older (and off Android).
  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// "Documents/ServiceOrders", as shown in the Files app.
  Future<String> folder() async =>
      await _channel.invokeMethod<String>('folder') ?? '';

  /// Saves [bytes] as [fileName] and returns where it went (a content URI,
  /// to keep in the order). [replacing] is the order's previous file: it is
  /// overwritten and renamed instead of creating a copy. Null when the
  /// folder isn't supported on this phone.
  Future<String?> save(
    String fileName,
    Uint8List bytes, {
    String? replacing,
  }) async {
    if (!await isSupported()) return null;
    return _channel.invokeMethod<String>('save', {
      'name': fileName,
      'bytes': bytes,
      'replacing': replacing,
    });
  }

  /// Removes a file saved by [save]. Missing files are ignored.
  Future<void> delete(String uri) async {
    if (!await isSupported()) return;
    await _channel.invokeMethod<void>('delete', {'uri': uri});
  }

  /// Opens the folder in the Files app. False when no app can show it.
  Future<bool> open() async =>
      await _channel.invokeMethod<bool>('open') ?? false;
}
