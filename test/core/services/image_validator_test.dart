import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/services/image_validator.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ImageValidator', () {
    late ImageValidator validator;
    late Directory tempDir;

    setUp(() {
      validator = ImageValidator();
      tempDir = Directory.systemTemp.createTempSync('image_validator_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('returns invalid for non-existent file', () async {
      final result = await validator.validateImage('non_existent.jpg');
      expect(result.isValid, isFalse);
      expect(result.error, 'File does not exist');
    });

    test('returns invalid for empty file', () async {
      final file = File(p.join(tempDir.path, 'empty.jpg'))..createSync();
      final result = await validator.validateImage(file.path);
      expect(result.isValid, isFalse);
      expect(result.error, 'File is empty');
    });

    test('returns invalid for unsupported extension', () async {
      final file = File(p.join(tempDir.path, 'test.txt'))..writeAsStringSync('not an image');
      final result = await validator.validateImage(file.path);
      expect(result.isValid, isFalse);
      expect(result.error, 'Unsupported file extension');
    });

    test('returns invalid for wrong magic number', () async {
      final file = File(p.join(tempDir.path, 'fake.jpg'))..writeAsStringSync('123456789012345');
      final result = await validator.validateImage(file.path);
      expect(result.isValid, isFalse);
      expect(result.error, 'Invalid file header signature');
    });

    test('returns valid for correct PNG magic number', () async {
      final file = File(p.join(tempDir.path, 'test.png'));
      // Write PNG magic numbers: 89 50 4E 47
      file.writeAsBytesSync([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
      
      final result = await validator.validateImage(file.path);
      expect(result.isValid, isTrue);
    });
  });
}
