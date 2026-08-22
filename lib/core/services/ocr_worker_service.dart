import 'dart:async';

import '../database/screenshot_dao.dart';
import 'ocr_service.dart';

class OcrWorkerService {
  final ScreenshotDao screenshotDao;
  final OcrService ocrService;

  final StreamController<void> _progressController =
      StreamController<void>.broadcast();
  bool _isProcessing = false;
  bool _isCancelled = false;

  OcrWorkerService({required this.screenshotDao, required this.ocrService});

  Stream<void> get progressStream => _progressController.stream;
  bool get isProcessing => _isProcessing;

  void startProcessing() {
    if (_isProcessing) return;
    _isCancelled = false;
    _processQueue();
  }

  Future<void> _processQueue() async {
    _isProcessing = true;

    while (!_isCancelled) {
      final candidates = await screenshotDao.getByStatus('imported', limit: 1);

      if (candidates.isEmpty) {
        _isProcessing = false;
        break;
      }

      final screenshot = candidates.first;
      if (screenshot.id == null) break;

      try {
        await screenshotDao.updateProcessingStatus(
          screenshot.id!,
          'ocr_processing',
        );

        if (screenshot.originalUri == null) {
          await screenshotDao.updateProcessingStatus(
            screenshot.id!,
            'ocr_failed',
            error: 'Asset URI is missing',
          );
          continue;
        }

        final recognizedText = await ocrService.recognizeTextFromAsset(
          screenshot.originalUri!,
        );
        await screenshotDao.updateOcrText(screenshot.id!, recognizedText);
      } catch (e, stack) {
        try {
          await screenshotDao.updateProcessingStatus(
            screenshot.id!,
            'ocr_failed',
            error: '$e\n$stack',
          );
        } catch (_) {}
      }

      if (!_progressController.isClosed) {
        _progressController.add(null);
      }
      await Future<void>.delayed(Duration.zero);
    }

    _isProcessing = false;
    if (!_progressController.isClosed) {
      _progressController.add(null);
    }
  }

  Future<void> retryFailed() async {
    if (_isProcessing) return;

    final failedScreenshots = await screenshotDao.getByStatus('ocr_failed');
    for (final s in failedScreenshots) {
      if (s.id != null) {
        await screenshotDao.updateProcessingStatus(s.id!, 'imported');
      }
    }

    startProcessing();
  }

  void cancelProcessing() {
    _isCancelled = true;
  }

  void dispose() {
    _isCancelled = true;
    _progressController.close();
    ocrService.dispose();
  }
}
