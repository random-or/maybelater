import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ThumbnailService {
  Future<File?> generateThumbnail(
    String sourcePath,
    String thumbnailPath,
  ) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        thumbnailPath,
        minWidth: 300,
        minHeight: 300,
        quality: 75,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      // Do not throw on failure, let caller handle null
      return null;
    }
  }
}
