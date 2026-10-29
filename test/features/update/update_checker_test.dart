import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:service_order_app/features/update/app_version.dart';
import 'package:service_order_app/features/update/update_checker.dart';

Map<String, Object?> _release(
  String tag, {
  bool draft = false,
  bool withApk = true,
  String body = '',
}) =>
    {
      'tag_name': tag,
      'draft': draft,
      'body': body,
      'assets': [
        if (withApk)
          {
            'name': 'service-order-app-${tag.substring(1)}.apk',
            'browser_download_url': 'https://example.com/$tag.apk',
          },
        {'name': 'notes.txt', 'browser_download_url': 'https://example.com/x'},
      ],
    };

UpdateChecker _checker(
  List<Map<String, Object?>> releases, {
  String channel = '',
  int installedCode = 1000000,
  int status = 200,
}) {
  return UpdateChecker(
    channel: channel,
    client: MockClient(
      (request) async => http.Response(jsonEncode(releases), status),
    ),
    installedVersion: () async => (name: 'x', code: installedCode),
  );
}

void main() {
  group('AppVersion', () {
    test('parses generic and client tags', () {
      final generic = AppVersion.parseTag('v1.2.3', channel: '')!;
      expect(generic.code, 1020300);
      expect(generic.label, '1.2.3');

      final client = AppVersion.parseTag('v1.2.3-val.4', channel: 'val')!;
      expect(client.code, 1020304);
      expect(client.label, '1.2.3 (4)');
    });

    test('ignores tags of other channels', () {
      expect(AppVersion.parseTag('v1.2.3-val.4', channel: ''), isNull);
      expect(AppVersion.parseTag('v1.2.3', channel: 'val'), isNull);
      expect(AppVersion.parseTag('v1.2.3-abc.1', channel: 'val'), isNull);
      expect(AppVersion.parseTag('1.2.3', channel: ''), isNull);
    });

    test('codes keep growing across releases', () {
      final versions = ['v1.0.0', 'v1.0.1', 'v1.1.0', 'v2.0.0']
          .map((tag) => AppVersion.parseTag(tag, channel: '')!.code)
          .toList();
      expect(versions, orderedEquals([...versions]..sort()));
    });
  });

  group('UpdateChecker', () {
    test('returns the newest release of the channel', () async {
      final update = await _checker([
        _release('v1.0.1', body: 'Correções'),
        _release('v1.0.2', body: 'Novo layout'),
        _release('v9.0.0-val.1'),
      ]).check();

      expect(update!.tag, 'v1.0.2');
      expect(update.notes, 'Novo layout');
      expect(update.apkUrl.toString(), 'https://example.com/v1.0.2.apk');
    });

    test('client channel only sees its own builds', () async {
      final update = await _checker(
        [_release('v2.0.0'), _release('v1.0.0-val.2'), _release('v1.0.0-val.3')],
        channel: 'val',
        installedCode: 1000002,
      ).check();

      expect(update!.tag, 'v1.0.0-val.3');
    });

    test('null when the installed version is the newest', () async {
      final update = await _checker([_release('v1.0.0')]).check();
      expect(update, isNull);
    });

    test('skips drafts and releases without an APK', () async {
      final update = await _checker([
        _release('v1.0.5', draft: true),
        _release('v1.0.4', withApk: false),
        _release('v1.0.3'),
      ]).check();

      expect(update!.tag, 'v1.0.3');
    });

    test('throws when GitHub answers with an error', () async {
      expect(
        _checker([], status: 403).check(),
        throwsA(isA<UpdateCheckException>()),
      );
    });
  });
}
