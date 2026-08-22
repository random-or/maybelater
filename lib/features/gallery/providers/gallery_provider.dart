import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot.dart';
import '../../import/providers/import_provider.dart';

enum GallerySortMode { newestFirst, oldestFirst }

class GalleryState {
  final List<Screenshot> screenshots;
  final bool isLoading;
  final bool hasMore;
  final GallerySortMode sortMode;
  final Set<int> selectedIds;
  final String? error;

  const GalleryState({
    this.screenshots = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.sortMode = GallerySortMode.newestFirst,
    this.selectedIds = const {},
    this.error,
  });

  GalleryState copyWith({
    List<Screenshot>? screenshots,
    bool? isLoading,
    bool? hasMore,
    GallerySortMode? sortMode,
    Set<int>? selectedIds,
    String? error,
    bool clearError = false,
  }) {
    return GalleryState(
      screenshots: screenshots ?? this.screenshots,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      sortMode: sortMode ?? this.sortMode,
      selectedIds: selectedIds ?? this.selectedIds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GalleryNotifier extends Notifier<GalleryState> {
  static const int pageSize = 50;
  bool _mounted = true;

  @override
  GalleryState build() {
    ref.onDispose(() {
      _mounted = false;
    });
    Future.microtask(() => loadNextPage());
    return const GalleryState();
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dao = ref.read(screenshotDaoProvider);

      int? lastCreatedAt;
      int? lastId;

      if (state.screenshots.isNotEmpty) {
        final last = state.screenshots.last;
        lastCreatedAt = last.createdAt;
        lastId = last.id;
      }

      final newScreenshots = await dao.getPaged(
        limit: pageSize,
        lastCreatedAt: lastCreatedAt,
        lastId: lastId,
        descending: state.sortMode == GallerySortMode.newestFirst,
      );

      if (!_mounted) return;

      state = state.copyWith(
        isLoading: false,
        screenshots: [...state.screenshots, ...newScreenshots],
        hasMore: newScreenshots.length == pageSize,
      );
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setSortMode(GallerySortMode mode) async {
    if (state.sortMode == mode) return;

    state = state.copyWith(
      sortMode: mode,
      screenshots: [],
      hasMore: true,
      selectedIds: {},
      clearError: true,
    );

    await loadNextPage();
  }

  void toggleSelection(int id) {
    final newSelection = Set<int>.from(state.selectedIds);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      newSelection.add(id);
    }
    state = state.copyWith(selectedIds: newSelection);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    try {
      final dao = ref.read(screenshotDaoProvider);
      await dao.toggleFavorite(id, isFavorite);

      if (!_mounted) return;
      final updatedList = state.screenshots.map((s) {
        if (s.id == id) {
          return s.copyWith(isFavorite: isFavorite);
        }
        return s;
      }).toList();

      state = state.copyWith(screenshots: updatedList);
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(error: 'Failed to update favorite: $e');
    }
  }

  Future<void> batchToggleFavorite(bool isFavorite) async {
    if (state.selectedIds.isEmpty) return;

    try {
      final dao = ref.read(screenshotDaoProvider);
      final idsList = state.selectedIds.toList();
      await dao.batchToggleFavorite(idsList, isFavorite);

      if (!_mounted) return;
      final updatedList = state.screenshots.map((s) {
        if (state.selectedIds.contains(s.id)) {
          return s.copyWith(isFavorite: isFavorite);
        }
        return s;
      }).toList();

      state = state.copyWith(screenshots: updatedList, selectedIds: {});
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(error: 'Failed to update favorites: $e');
    }
  }

  Future<void> batchDelete() async {
    if (state.selectedIds.isEmpty) return;

    try {
      final dao = ref.read(screenshotDaoProvider);
      final idsList = state.selectedIds.toList();
      await dao.batchDelete(idsList);

      if (!_mounted) return;
      final updatedList = state.screenshots
          .where((s) => !state.selectedIds.contains(s.id))
          .toList();

      state = state.copyWith(screenshots: updatedList, selectedIds: {});
    } catch (e) {
      if (!_mounted) return;
      state = state.copyWith(error: 'Failed to delete items: $e');
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(
      screenshots: [],
      hasMore: true,
      selectedIds: {},
      clearError: true,
    );
    await loadNextPage();
  }
}

final galleryProvider = NotifierProvider<GalleryNotifier, GalleryState>(
  GalleryNotifier.new,
);
