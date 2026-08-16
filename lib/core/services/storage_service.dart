import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final _random = Random();

  Future<Directory> getThumbnailDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'thumbnails'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String generateFileName(String extension) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(100000);
    // Ensure the extension has a leading dot
    final ext = extension.startsWith('.') ? extension : '.$extension';
    return '${timestamp}_$randomSuffix$ext';
  }

  Future<void> deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<int> getAvailableSpaceBytes() async {
    // TODO: Implement actual available space check
    // For now, return a large enough number to not block basic testing.
    return 1024 * 1024 * 1024 * 10; // 10 GB
  }
}
