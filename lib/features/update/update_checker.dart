import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.dart';

/// The app running on the phone: versionName ("1.0.0") and versionCode.
typedef InstalledVersion = ({String name, int code});

/// A newer release of this app's channel, ready to download.
class AvailableUpdate {
  const AvailableUpdate({
    required this.version,
    required this.tag,
    required this.notes,
    required this.apkUrl,
  });

  final AppVersion version;
  final String tag;
  final String notes;
  final Uri apkUrl;
}

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Looks for a newer release on GitHub Releases.
///
/// Only tags of this build's [channel] are considered (see [AppVersion]),
/// so the generic app never picks a client build and vice versa. The
/// repository is public, so no token is needed (and none must ever ship
/// inside the APK).
class UpdateChecker {
  UpdateChecker({
    required this.channel,
    http.Client? client,
    Future<InstalledVersion> Function()? installedVersion,
  })  : _client = client ?? http.Client(),
        _installedVersion = installedVersion ?? _readInstalledVersion;

  static const repository = 'WandersoNoleto/service-order-app';

  final String channel;
  final http.Client _client;
  final Future<InstalledVersion> Function() _installedVersion;

  Future<InstalledVersion> installedVersion() => _installedVersion();

  /// The newest release of [channel] if it is newer than the installed app,
  /// otherwise null. Throws [UpdateCheckException] when GitHub can't be read.
  Future<AvailableUpdate?> check() async {
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.https('api.github.com', '/repos/$repository/releases', {
              'per_page': '30',
            }),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 15));
    } on Exception catch (error) {
      throw UpdateCheckException('Sem conexão com o servidor de atualizações ($error)');
    }

    if (response.statusCode != 200) {
      throw UpdateCheckException(
        'Servidor de atualizações respondeu ${response.statusCode}',
      );
    }

    final releases = jsonDecode(response.body) as List<dynamic>;
    AvailableUpdate? newest;

    for (final release in releases.cast<Map<String, dynamic>>()) {
      if (release['draft'] == true) continue;

      final tag = release['tag_name'] as String? ?? '';
      final version = AppVersion.parseTag(tag, channel: channel);
      if (version == null) continue;

      final apk = (release['assets'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .where((asset) => (asset['name'] as String? ?? '').endsWith('.apk'))
          .firstOrNull;
      if (apk == null) continue;

      if (newest == null || version.code > newest.version.code) {
        newest = AvailableUpdate(
          version: version,
          tag: tag,
          notes: (release['body'] as String? ?? '').trim(),
          apkUrl: Uri.parse(apk['browser_download_url'] as String),
        );
      }
    }

    if (newest == null) return null;
    final installed = await _installedVersion();
    return newest.version.code > installed.code ? newest : null;
  }

  static Future<InstalledVersion> _readInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    return (name: info.version, code: int.tryParse(info.buildNumber) ?? 0);
  }
}
