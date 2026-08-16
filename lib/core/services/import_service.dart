import 'dart:async';

import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;

import '../database/screenshot_dao.dart';
import '../models/screenshot.dart';
import 'storage_service.dart';
import 'image_hash_service.dart';
import 'image_validator.dart';
import 'thumbnail_service.dart';

class ImportProgress {
  final int total;
  final int completed;
  final int failed;
  final int duplicates;
  final int pending;
  final bool isRunning;
  final String? currentFile;
  final String? lastError;

  const ImportProgress({
    this.total = 0,
    this.completed = 0,
    this.failed = 0,
    this.duplicates = 0,
    this.pending = 0,
    this.isRunning = false,
    this.currentFile,
    this.lastError,
  });
}

class ImportService {
  final ScreenshotDao screenshotDao;
  final StorageService storageService;
  final ImageHashService imageHashService;
  final ImageValidator imageValidator;
  final ThumbnailService thumbnailService;

  final StreamController<ImportProgress> _progressController =
      StreamController<ImportProgress>.broadcast();
  bool _isImporting = false;
  bool _isCancelled = false;

  ImportService({
    required this.screenshotDao,
    required this.storageService,
    required this.imageHashService,
    required this.imageValidator,
    required this.thumbnailService,
  });

  Stream<ImportProgress> get progressStream => _progressController.stream;
  bool get isImporting => _isImporting;

  /// Create pending records for discovered assets and start processing.
  Future<void> startImport(List<AssetEntity> assets) async {
    if (_isImporting) return;
    _isCancelled = false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final screenshotDir = await storageService.getScreenshotDirectory();

    for (final asset in assets) {
      // Determine file extension from the asset title
      final assetTitle = asset.title ?? 'screenshot_${asset.id}.jpg';
      final ext = p.extension(assetTitle).isNotEmpty
          ? p.extension(assetTitle)
          : '.jpg';
      final fileName = storageService.generateFileName(ext);
      final targetPath = p.join(screenshotDir.path, fileName);

      final screenshot = Screenshot(
        filepath: targetPath,
        originalUri: asset.id,
        filename: assetTitle,
        createdAt: asset.createDateTime.millisecondsSinceEpoch,
        updatedAt: now,
        importedAt: now,
        width: asset.width,
        height: asset.height,
        source: 'import',
        processingStatus: 'pending',
      );

      await screenshotDao.insert(screenshot);
      // Yield to event loop periodically
      await Future<void>.delayed(Duration.zero);
    }

    _startProcessing();
  }

  void _startProcessing() {
    if (_isImporting) return;
    _isImporting = true;
    _isCancelled = false;
    processQueue();
  }

  /// Main processing loop. Picks pending items one at a time.
  Future<void> processQueue() async {
    _isImporting = true;

    while (!_isCancelled) {
      final pendingScreenshots = await screenshotDao.getByStatus(
        'pending',
        limit: 1,
      );

      if (pendingScreenshots.isEmpty) {
        _isImporting = false;
        await _emitProgress(isRunning: false);
        break;
      }

      final screenshot = pendingScreenshots.first;
      if (screenshot.id == null) continue;

      try {
        // Mark as importing
        await screenshotDao.updateProcessingStatus(screenshot.id!, 'importing');
        await _emitProgress(isRunning: true, currentFile: screenshot.filename);

        if (screenshot.originalUri == null) {
          await screenshotDao.updateProcessingStatus(
            screenshot.id!,
            'failed',
            error: 'Asset URI is missing',
          );
          continue;
        }

        // Retrieve the original file via photo_manager
        final asset = await AssetEntity.fromId(screenshot.originalUri!);
        if (asset == null) {
          await screenshotDao.updateProcessingStatus(
            screenshot.id!,
            'failed',
            error: 'Asset no longer available in MediaStore',
          );
          continue;
        }

        final sourceFile = await asset.file;
        if (sourceFile == null) {
          await screenshotDao.updateProcessingStatus(
            screenshot.id!,
            'failed',
            error: 'Could not read source file',
          );
          continue;
        }

        // Copy to app-managed storage
        final targetFile = await storageService.copyFileToAppStorage(
          sourceFile,
          screenshot.filepath,
        );

        // Validate the copied file
        final validation = await imageValidator.validateImage(targetFile.path);
        if (!validation.isValid) {
          await storageService.deleteFileIfExists(targetFile.path);
          await screenshotDao.updateProcessingStatus(
            screenshot.id!,
            'failed',
            error: validation.error ?? 'Invalid image file',
          );
          continue;
        }

        // Compute content hash for dedup
        final contentHash = await imageHashService.computeFileHash(
          targetFile.path,
        );
        final existing = await screenshotDao.getByContentHash(contentHash);

        if (existing != null) {
          await storageService.deleteFileIfExists(targetFile.path);
          await screenshotDao.updateProcessingStatus(
            screenshot.id!,
            'duplicate',
            error: 'Matches existing screenshot #${existing.id}',
          );
          continue;
        }

        // Generate thumbnail
        final thumbDir = await storageService.getThumbnailDirectory();
        final thumbFileName = storageService.generateFileName('.jpg');
        final thumbPath = p.join(thumbDir.path, thumbFileName);
        final thumbFile = await thumbnailService.generateThumbnail(
          targetFile.path,
          thumbPath,
        );

        final fileSize = await targetFile.length();

        // Update with all import fields
        await screenshotDao.updateImportFields(
          screenshot.id!,
          filepath: targetFile.path,
          thumbnailPath: thumbFile?.path ?? '',
          contentHash: contentHash,
          fileSize: fileSize,
          width: screenshot.width,
          height: screenshot.height,
        );
      } catch (e) {
        // One failed screenshot must never stop the whole import
        await screenshotDao.updateProcessingStatus(
          screenshot.id!,
          'failed',
          error: e.toString(),
        );
      }

      // Yield to event loop between items
      await Future<void>.delayed(Duration.zero);
    }

    _isImporting = false;
  }

  /// Reset all failed items to pending and restart processing.
  Future<void> retryFailed() async {
    if (_isImporting) return;

    final failedScreenshots = await screenshotDao.getByStatus('failed');
    for (final s in failedScreenshots) {
      if (s.id != null) {
        await screenshotDao.updateProcessingStatus(s.id!, 'pending');
      }
    }

    _startProcessing();
  }

  /// Stop processing after current item completes.
  void cancelImport() {
    _isCancelled = true;
    _isImporting = false;
    _emitProgress(isRunning: false);
  }

  /// On app startup, reset stale 'importing' to 'pending'.
  Future<int> recoverStaleJobs() async {
    return await screenshotDao.recoverStaleJobs();
  }

  Future<void> _emitProgress({
    required bool isRunning,
    String? currentFile,
    String? lastError,
  }) async {
    final counts = await screenshotDao.getImportCounts();

    final completed = counts['imported'] ?? 0;
    final failed = counts['failed'] ?? 0;
    final duplicates = counts['duplicate'] ?? 0;
    final pending = counts['pending'] ?? 0;
    final importing = counts['importing'] ?? 0;

    final total = completed + failed + duplicates + pending + importing;

    _progressController.add(
      ImportProgress(
        total: total,
        completed: completed,
        failed: failed,
        duplicates: duplicates,
        pending: pending + importing,
        isRunning: isRunning,
        currentFile: currentFile,
        lastError: lastError,
      ),
    );
  }

  void dispose() {
    _isCancelled = true;
    _progressController.close();
  }
}
