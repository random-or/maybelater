import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/models/screenshot.dart';
import 'package:maybelater/core/services/ocr_service.dart';
import 'package:maybelater/core/services/ocr_worker_service.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:maybelater/core/database/database_manager.dart';

class FakeOcrService extends OcrService {
  final Map<String, String> responses = {};
  final Set<String> shouldThrow = {};
  bool isDisposed = false;

  @override
  Future<String> recognizeTextFromAsset(String assetId) async {
    if (shouldThrow.contains(assetId)) {
      throw Exception('Fake OCR Exception');
    }
    return responses[assetId] ?? '';
  }

  @override
  void dispose() {
    isDisposed = true;
  }
}

void main() {
  late DatabaseManager dbManager;
  late ScreenshotDao screenshotDao;
  late FakeOcrService ocrService;
  late OcrWorkerService worker;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    await dbManager.initDatabase(pathOverride: inMemoryDatabasePath);
    await dbManager.clearAllData(); // Ensure clean state
    screenshotDao = ScreenshotDao(dbManager);
    ocrService = FakeOcrService();
    worker = OcrWorkerService(
      screenshotDao: screenshotDao,
      ocrService: ocrService,
    );
  });

  tearDown(() async {
    worker.dispose();
    await dbManager.close();
  });

  test('only eligible indexed screenshots are selected', () async {
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f1',
        originalUri: 'uri1',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'imported', // Eligible
      ),
    );
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f2',
        originalUri: 'uri2',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'pending', // Not eligible
      ),
    );
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f3',
        originalUri: 'uri3',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'completed', // Not eligible
      ),
    );

    ocrService.responses['uri1'] = 'Hello';

    worker.startProcessing();

    // Wait for stream to emit (which happens after processing finishes)
    await worker.progressStream.first;

    final all = await screenshotDao.getAll();

    final s1Result = all.firstWhere((s) => s.filepath == 'f1');
    expect(s1Result.processingStatus, 'completed');
    expect(s1Result.ocrText, 'Hello');

    final s2Result = all.firstWhere((s) => s.filepath == 'f2');
    expect(s2Result.processingStatus, 'pending');

    final s3Result = all.firstWhere((s) => s.filepath == 'f3');
    expect(s3Result.processingStatus, 'completed');
  });

  test('successful OCR persists text', () async {
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f1',
        originalUri: 'uri1',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'imported',
      ),
    );
    ocrService.responses['uri1'] = 'Detected text';

    worker.startProcessing();
    await worker.progressStream.first;

    final all = await screenshotDao.getAll();
    expect(all.first.processingStatus, 'completed');
    expect(all.first.ocrText, 'Detected text');
  });

  test('empty text is success', () async {
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f1',
        originalUri: 'uri1',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'imported',
      ),
    );
    ocrService.responses['uri1'] = '';

    worker.startProcessing();
    await worker.progressStream.first;

    final all = await screenshotDao.getAll();
    expect(all.first.processingStatus, 'completed');
    expect(all.first.ocrText, '');
  });

  test('one failure does not stop later screenshots', () async {
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f1',
        originalUri: 'uri1',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'imported',
      ),
    );
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f2',
        originalUri: 'uri2',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'imported',
      ),
    );

    ocrService.shouldThrow.add('uri1');
    ocrService.responses['uri2'] = 'Success2';

    worker.startProcessing();

    // Wait for the worker to finish the loop
    await worker.progressStream.where((_) => !worker.isProcessing).first;

    final all = await screenshotDao.getAll();
    final s1Result = all.firstWhere((s) => s.filepath == 'f1');
    final s2Result = all.firstWhere((s) => s.filepath == 'f2');

    expect(s1Result.processingStatus, 'ocr_failed');
    expect(s1Result.processingError, contains('Fake OCR Exception'));

    expect(s2Result.processingStatus, 'completed');
    expect(s2Result.ocrText, 'Success2');
  });

  test('failed OCR can be retried', () async {
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f1',
        originalUri: 'uri1',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'ocr_failed',
      ),
    );

    ocrService.responses['uri1'] = 'Retry Success';

    await worker.retryFailed();
    await worker.progressStream.where((_) => !worker.isProcessing).first;

    final all = await screenshotDao.getAll();
    expect(all.first.processingStatus, 'completed');
    expect(all.first.ocrText, 'Retry Success');
  });

  test('stale OCR jobs recover', () async {
    await screenshotDao.insert(
      Screenshot(
        filepath: 'f1',
        originalUri: 'uri1',
        createdAt: 1,
        importedAt: 1,
        updatedAt: 1,
        processingStatus: 'ocr_processing',
      ),
    );

    await screenshotDao.recoverStaleJobs();

    final all = await screenshotDao.getAll();
    expect(all.first.processingStatus, 'imported');
  });

  test('recognizer is properly disposed', () async {
    worker.dispose();
    expect(ocrService.isDisposed, true);
  });
}
