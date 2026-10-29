import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps the logo the user picked in the app.
///
/// The picked image is **copied** into the app's private folder. Only the
/// file name is stored in the database, so deleting the photo from the
/// gallery (or moving it) never breaks the logo.
class LogoStorage {
  LogoStorage({Future<Directory> Function()? baseDirectory, ImagePicker? picker})
      : _baseDirectory = baseDirectory ?? getApplicationSupportDirectory,
        _picker = picker ?? ImagePicker();

  final Future<Directory> Function() _baseDirectory;
  final ImagePicker _picker;

  /// Large photos are scaled down on import to keep every PDF light.
  static const maxSide = 800.0;

  /// Opens the system photo picker and imports the chosen image.
  /// Returns the stored file name, or null if the user cancelled.
  Future<String?> pickAndImport() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 90,
    );
    if (picked == null) return null;
    return import(picked.path);
  }

  /// Copies [sourcePath] into the app folder and returns its new file name.
  /// Every import gets a new name, so a cached PDF logo is never stale.
  Future<String> import(String sourcePath) async {
    final extension = p.extension(sourcePath).toLowerCase();
    final name = 'logo_${DateTime.now().millisecondsSinceEpoch}$extension';
    await File(sourcePath).copy(p.join((await _directory()).path, name));
    return name;
  }

  /// The stored logo, or null when [fileName] is null or the file is gone.
  Future<File?> resolve(String? fileName) async {
    if (fileName == null) return null;
    final file = File(p.join((await _directory()).path, fileName));
    return await file.exists() ? file : null;
  }

  /// Deletes old logos, keeping only [keep] (none when null).
  Future<void> deleteAllExcept(String? keep) async {
    await for (final entity in (await _directory()).list()) {
      if (entity is File && p.basename(entity.path) != keep) {
        await entity.delete();
      }
    }
  }

  Future<Directory> _directory() async {
    final dir = Directory(p.join((await _baseDirectory()).path, 'branding'));
    await dir.create(recursive: true);
    return dir;
  }
}
