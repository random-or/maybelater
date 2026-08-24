import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/services/import_service.dart';
import 'package:maybelater/core/services/ocr_worker_service.dart';
import 'package:maybelater/features/gallery/providers/gallery_provider.dart';
import 'package:maybelater/features/import/providers/import_provider.dart';

class FakeScreenshotDao implements ScreenshotDao {
  @override
  Future<Map<String, int>> getImportCounts() async => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeImportService implements ImportService {
  bool _isImporting = false;
  final StreamController<ImportProgress> _progressController =
      StreamController<ImportProgress>.broadcast();

  @override
  bool get isImporting => _isImporting;

  @override
  Stream<ImportProgress> get progressStream => _progressController.stream;

  void emitProgress(bool running) {
    _isImporting = running;
    _progressController.add(ImportProgress(isRunning: running));
  }

  @override
  Future<int> recoverStaleJobs() async => 0;

  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOcrWorkerService implements OcrWorkerService {
  bool _isProcessing = false;
  final StreamController<void> _progressController =
      StreamController<void>.broadcast();

  @override
  bool get isProcessing => _isProcessing;

  @override
  Stream<void> get progressStream => _progressController.stream;

  void emitProgress(bool running) {
    _isProcessing = running;
    _progressController.add(null);
  }

  @override
  void startProcessing() {}

  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGalleryNotifier extends GalleryNotifier {
  int reloadCount = 0;

  @override
  GalleryState build() {
    return const GalleryState();
  }

  @override
  Future<void> reloadCurrent() async {
    reloadCount++;
  }
}

void main() {
  Future<void> pumpEvents() async {
    await Future.microtask(() {});
    await Future.microtask(() {});
    await Future.microtask(() {});
  }

  test('Gallery refreshes only exactly once per transition to idle', () async {
    final fakeDao = FakeScreenshotDao();
    final fakeImportService = FakeImportService();
    final fakeOcrService = FakeOcrWorkerService();
    final fakeGalleryNotifier = FakeGalleryNotifier();

    final container = ProviderContainer(
      overrides: [
        screenshotDaoProvider.overrideWithValue(fakeDao),
        importServiceProvider.overrideWithValue(fakeImportService),
        ocrWorkerServiceProvider.overrideWithValue(fakeOcrService),
        galleryProvider.overrideWith(() => fakeGalleryNotifier),
      ],
    );

    // Initial idle
    final importState = container.read(importNotifierProvider);
    expect(importState.isImporting, isFalse);
    expect(fakeGalleryNotifier.reloadCount, equals(0));

    // First RUNNING state
    fakeImportService.emitProgress(true);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isTrue);
    expect(fakeGalleryNotifier.reloadCount, equals(0));

    // Both running
    fakeOcrService.emitProgress(true);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isTrue);
    expect(fakeGalleryNotifier.reloadCount, equals(0));

    // Import complete, OCR still running
    fakeImportService.emitProgress(false);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isTrue);
    expect(fakeGalleryNotifier.reloadCount, equals(0));

    // First RUNNING -> IDLE
    fakeOcrService.emitProgress(false);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isFalse);
    expect(fakeGalleryNotifier.reloadCount, equals(1));

    // Additional idle events
    fakeImportService.emitProgress(false);
    await pumpEvents();
    fakeOcrService.emitProgress(false);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isFalse);
    expect(fakeGalleryNotifier.reloadCount, equals(1)); // Should NOT increment

    // Second RUNNING state
    fakeImportService.emitProgress(true);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isTrue);
    expect(fakeGalleryNotifier.reloadCount, equals(1)); // Still 1

    fakeOcrService.emitProgress(true);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isTrue);
    expect(fakeGalleryNotifier.reloadCount, equals(1)); // Still 1

    // Second RUNNING -> IDLE
    fakeImportService.emitProgress(false);
    await pumpEvents();
    fakeOcrService.emitProgress(false);
    await pumpEvents();
    expect(container.read(importNotifierProvider).isImporting, isFalse);
    expect(
      fakeGalleryNotifier.reloadCount,
      equals(2),
    ); // Incremented once for second cycle
  });
}
