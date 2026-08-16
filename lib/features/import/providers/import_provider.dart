import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/database/database_manager.dart';
import '../../../core/database/screenshot_dao.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/media_source_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/image_hash_service.dart';
import '../../../core/services/image_validator.dart';
import '../../../core/services/thumbnail_service.dart';

// --- Singleton service providers ---

final databaseManagerProvider = Provider<DatabaseManager>((ref) {
  return DatabaseManager();
});

final screenshotDaoProvider = Provider<ScreenshotDao>((ref) {
  return ScreenshotDao(ref.watch(databaseManagerProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final imageHashServiceProvider = Provider<ImageHashService>((ref) {
  return ImageHashService();
});

final imageValidatorProvider = Provider<ImageValidator>((ref) {
  return ImageValidator();
});

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService();
});

final mediaSourceServiceProvider = Provider<MediaSourceService>((ref) {
  return MediaSourceService();
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    screenshotDao: ref.watch(screenshotDaoProvider),
    storageService: ref.watch(storageServiceProvider),
    imageHashService: ref.watch(imageHashServiceProvider),
    imageValidator: ref.watch(imageValidatorProvider),
    thumbnailService: ref.watch(thumbnailServiceProvider),
  );
});

// --- Import state ---

/// The current import progress state
class ImportState {
  final PermissionState permissionState;
  final bool isDiscovering;
  final bool isImporting;
  final int discoveredCount;
  final ImportProgress progress;
  final String? error;

  const ImportState({
    this.permissionState = PermissionState.notDetermined,
    this.isDiscovering = false,
    this.isImporting = false,
    this.discoveredCount = 0,
    this.progress = const ImportProgress(),
    this.error,
  });

  ImportState copyWith({
    PermissionState? permissionState,
    bool? isDiscovering,
    bool? isImporting,
    int? discoveredCount,
    ImportProgress? progress,
    String? error,
  }) {
    return ImportState(
      permissionState: permissionState ?? this.permissionState,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      isImporting: isImporting ?? this.isImporting,
      discoveredCount: discoveredCount ?? this.discoveredCount,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

/// Manages the import workflow
class ImportNotifier extends Notifier<ImportState> {
  ImportService get _importService => ref.read(importServiceProvider);
  MediaSourceService get _mediaSourceService =>
      ref.read(mediaSourceServiceProvider);
  ScreenshotDao get _screenshotDao => ref.read(screenshotDaoProvider);

  StreamSubscription<ImportProgress>? _progressSubscription;

  @override
  ImportState build() {
    _listenToProgress();
    _recoverOnStartup();

    ref.onDispose(() {
      _progressSubscription?.cancel();
      _importService.dispose();
    });

    return const ImportState();
  }

  void _listenToProgress() {
    _progressSubscription = _importService.progressStream.listen((progress) {
      state = state.copyWith(
        progress: progress,
        isImporting: progress.isRunning,
      );
    });
  }

  Future<void> _recoverOnStartup() async {
    final recovered = await _importService.recoverStaleJobs();
    if (recovered > 0) {
      // There were stale jobs — resume processing
      await processQueue();
    }
  }

  /// Request media access permission
  Future<void> requestPermission() async {
    try {
      final result = await _mediaSourceService.requestPermission();
      state = state.copyWith(permissionState: result, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to request permission: $e');
    }
  }

  /// Check current permission state
  Future<void> checkPermission() async {
    try {
      final result = await _mediaSourceService.getPermissionState();
      state = state.copyWith(permissionState: result);
    } catch (e) {
      state = state.copyWith(error: 'Failed to check permission: $e');
    }
  }

  /// Discover screenshots from MediaStore and start importing
  Future<void> discoverAndImport() async {
    if (state.isDiscovering || state.isImporting) return;

    state = state.copyWith(isDiscovering: true, error: null);

    try {
      // Ensure permission
      final permission = await _mediaSourceService.requestPermission();
      state = state.copyWith(permissionState: permission);

      if (permission != PermissionState.authorized &&
          permission != PermissionState.limited) {
        state = state.copyWith(
          isDiscovering: false,
          error: 'Media access permission is required to discover screenshots.',
        );
        return;
      }

      // Discover all image assets in pages
      final allAssets = <AssetEntity>[];
      int page = 0;
      const pageSize = 100;

      while (true) {
        final assets = await _mediaSourceService.getAllImageAssets(
          page: page,
          pageSize: pageSize,
        );
        if (assets.isEmpty) break;
        allAssets.addAll(assets);
        page++;

        // Yield to event loop periodically
        await Future<void>.delayed(Duration.zero);
      }

      state = state.copyWith(
        isDiscovering: false,
        discoveredCount: allAssets.length,
      );

      if (allAssets.isEmpty) {
        state = state.copyWith(error: 'No images found on device.');
        return;
      }

      // Start the import
      await _importService.startImport(allAssets);
    } catch (e) {
      state = state.copyWith(
        isDiscovering: false,
        error: 'Discovery failed: $e',
      );
    }
  }

  /// Import selected assets (from a picker or subset)
  Future<void> importAssets(List<AssetEntity> assets) async {
    if (state.isImporting) return;
    if (assets.isEmpty) return;

    state = state.copyWith(error: null);

    try {
      await _importService.startImport(assets);
    } catch (e) {
      state = state.copyWith(error: 'Import failed: $e');
    }
  }

  /// Resume processing the queue (e.g. after recovery)
  Future<void> processQueue() async {
    if (_importService.isImporting) return;

    try {
      await _importService.processQueue();
    } catch (e) {
      state = state.copyWith(error: 'Processing failed: $e');
    }
  }

  /// Retry all failed imports
  Future<void> retryFailed() async {
    try {
      await _importService.retryFailed();
    } catch (e) {
      state = state.copyWith(error: 'Retry failed: $e');
    }
  }

  /// Cancel the current import
  void cancelImport() {
    _importService.cancelImport();
  }

  /// Refresh import counts from database
  Future<void> refreshCounts() async {
    try {
      final counts = await _screenshotDao.getImportCounts();
      final total = counts.values.fold<int>(0, (sum, v) => sum + v);
      state = state.copyWith(
        progress: ImportProgress(
          total: total,
          completed: counts['imported'] ?? 0,
          failed: counts['failed'] ?? 0,
          duplicates: counts['duplicate'] ?? 0,
          pending: (counts['pending'] ?? 0) + (counts['importing'] ?? 0),
          isRunning: _importService.isImporting,
        ),
      );
    } catch (e) {
      // Non-critical — don't overwrite state with error
    }
  }
}

final importNotifierProvider = NotifierProvider<ImportNotifier, ImportState>(
  ImportNotifier.new,
);
