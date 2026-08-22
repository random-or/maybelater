import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/services/import_service.dart';
import 'package:maybelater/core/services/ocr_worker_service.dart';
import 'package:maybelater/features/import/providers/import_provider.dart';

class MockScreenshotDao implements ScreenshotDao {
  Map<String, int> mockCounts = {};

  @override
  Future<Map<String, int>> getImportCounts() async {
    return mockCounts;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockImportService implements ImportService {
  bool mockIsImporting = false;

  @override
  bool get isImporting => mockIsImporting;

  @override
  Stream<ImportProgress> get progressStream => const Stream.empty();

  @override
  Future<int> recoverStaleJobs() async => 0;

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockOcrWorkerService implements OcrWorkerService {
  @override
  bool get isProcessing => false;

  @override
  Stream<void> get progressStream => const Stream.empty();

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('refreshCounts maps all OCR states correctly so processed count remains > 0', () async {
    final mockDao = MockScreenshotDao();
    final mockImportService = MockImportService();
    final mockOcrWorker = MockOcrWorkerService();

    final container = ProviderContainer(
      overrides: [
        screenshotDaoProvider.overrideWithValue(mockDao),
        importServiceProvider.overrideWithValue(mockImportService),
        ocrWorkerServiceProvider.overrideWithValue(mockOcrWorker),
      ],
    );

    // Mock an active import where items are at various stages
    mockDao.mockCounts = {
      'pending': 100,
      'importing': 10,
      'imported': 200, // Indexed, waiting for OCR
      'ocr_processing': 5, // OCR running
      'completed': 300, // OCR done
      'ocr_failed': 2, // OCR failed
      'failed': 8, // Indexing failed
      'duplicate': 14, // Duplicates
    };

    final notifier = container.read(importNotifierProvider.notifier);
    await notifier.refreshCounts();

    final progress = container.read(importNotifierProvider).progress;

    // Total should be the sum of all states: 100+10+200+5+300+2+8+14 = 639
    expect(progress.total, 639);

    // Indexed should map directly to 'imported' (200)
    expect(progress.indexed, 200);

    // OCR states should map directly
    expect(progress.ocrProcessing, 5);
    expect(progress.ocrCompleted, 300);
    expect(progress.ocrFailed, 2);

    // Processed total should be the sum of indexed, ocr_processing, ocr_completed, ocr_failed, failed, duplicates
    // i.e., everything except pending and importing.
    // 200 + 5 + 300 + 2 + 8 + 14 = 529
    final processed =
        progress.indexed +
        progress.ocrProcessing +
        progress.ocrCompleted +
        progress.ocrFailed +
        progress.failed +
        progress.duplicates;
    expect(processed, 529);

    // And pending should be pending + importing (100 + 10 = 110)
    expect(progress.pending, 110);

    // total = processed + pending
    expect(processed + progress.pending, progress.total);
  });
}
