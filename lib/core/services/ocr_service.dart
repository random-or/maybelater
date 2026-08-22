import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';

import 'dart:io';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<String> recognizeTextFromAsset(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) {
      throw Exception('Asset no longer available in MediaStore');
    }

    final sourceFile = await asset.originFile ?? await asset.file;
    if (sourceFile == null) {
      throw Exception('Could not read source file from MediaStore');
    }

    return recognizeTextFromFile(sourceFile);
  }

  Future<String> recognizeTextFromFile(File file) async {
    final inputImage = InputImage.fromFile(file);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
