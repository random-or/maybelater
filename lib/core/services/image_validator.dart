import 'dart:io';

import 'package:path/path.dart' as p;

class ImageValidationResult {
  final bool isValid;
  final String? error;

  const ImageValidationResult({required this.isValid, this.error});
}

class ImageValidator {
  static const int _maxFileSize = 50 * 1024 * 1024; // 50MB

  Future<ImageValidationResult> validateImage(String filePath) async {
    final file = File(filePath);

    // 1. Check if file exists
    if (!await file.exists()) {
      return const ImageValidationResult(
        isValid: false,
        error: 'File does not exist',
      );
    }

    // 2. Check file size > 0
    final length = await file.length();
    if (length <= 0) {
      return const ImageValidationResult(
        isValid: false,
        error: 'File is empty',
      );
    }

    // 3. Check file size < max
    if (length > _maxFileSize) {
      return const ImageValidationResult(
        isValid: false,
        error: 'File size exceeds maximum limit of 50MB',
      );
    }

    // 4. Check extension
    final ext = p.extension(filePath).toLowerCase();
    final validExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.bmp'];
    if (!validExtensions.contains(ext)) {
      return const ImageValidationResult(
        isValid: false,
        error: 'Unsupported file extension',
      );
    }

    // 5. Check magic numbers
    final headerBytes = await file.openRead(0, 12).first;
    if (!_hasValidMagicNumber(headerBytes, ext)) {
      return const ImageValidationResult(
        isValid: false,
        error: 'Invalid file header signature',
      );
    }

    return const ImageValidationResult(isValid: true);
  }

  bool _hasValidMagicNumber(List<int> bytes, String extension) {
    if (bytes.isEmpty) return false;

    // PNG: 89 50 4E 47
    if (extension == '.png') {
      if (bytes.length >= 4) {
        return bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47;
      }
    }

    // JPEG: FF D8 FF
    if (extension == '.jpg' || extension == '.jpeg') {
      if (bytes.length >= 3) {
        return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      }
    }

    // WEBP: RIFF...WEBP
    if (extension == '.webp') {
      if (bytes.length >= 12) {
        final isRiff =
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46;
        final isWebp =
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50;
        return isRiff && isWebp;
      }
    }

    // BMP: BM (42 4D)
    if (extension == '.bmp') {
      if (bytes.length >= 2) {
        return bytes[0] == 0x42 && bytes[1] == 0x4D;
      }
    }

    return false;
  }
}
