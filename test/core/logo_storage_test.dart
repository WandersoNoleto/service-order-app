import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:service_order_app/core/storage/logo_storage.dart';

void main() {
  late Directory base;
  late LogoStorage storage;
  late File source;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('logo_storage_test');
    storage = LogoStorage(baseDirectory: () async => base);
    source = File(p.join(base.path, 'gallery_photo.PNG'))
      ..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => base.delete(recursive: true));

  test('import copies the image into the app folder', () async {
    final name = await storage.import(source.path);

    expect(name, startsWith('logo_'));
    expect(name, endsWith('.png'));
    final stored = await storage.resolve(name);
    expect(stored, isNotNull);
    expect(stored!.readAsBytesSync(), [1, 2, 3]);
  });

  test('the logo survives the original photo being deleted', () async {
    final name = await storage.import(source.path);
    source.deleteSync();

    expect(await storage.resolve(name), isNotNull);
  });

  test('resolve returns null for no logo or a missing file', () async {
    expect(await storage.resolve(null), isNull);
    expect(await storage.resolve('logo_gone.png'), isNull);
  });

  test('deleteAllExcept keeps only the current logo', () async {
    final old = await storage.import(source.path);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final current = await storage.import(source.path);

    await storage.deleteAllExcept(current);

    expect(await storage.resolve(old), isNull);
    expect(await storage.resolve(current), isNotNull);
  });
}
