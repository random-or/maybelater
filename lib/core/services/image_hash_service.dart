import 'dart:io';

import 'package:crypto/crypto.dart';

class ImageHashService {
  Future<String> computeFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException("File does not exist", filePath);
    }

    // Read the file as a stream for memory efficiency
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;

    return digest.toString().toLowerCase();
  }
}
