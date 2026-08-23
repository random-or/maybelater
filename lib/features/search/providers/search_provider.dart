import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/search_dao.dart';
import '../../import/providers/import_provider.dart';

final searchDaoProvider = Provider<SearchDao>((ref) {
  return SearchDao(ref.watch(databaseManagerProvider));
});

enum SearchStatus { idle, loading, results, empty, error }

class SearchState {
  final SearchStatus status;
  final List<SearchResult> results;
  final String query;
  final String? error;

  const SearchState({
    this.status = SearchStatus.idle,
    this.results = const [],
    this.query = '',
    this.error,
  });

  SearchState copyWith({
    SearchStatus? status,
    List<SearchResult>? results,
    String? query,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;
  bool _mounted = true;

  @override
  SearchState build() {
    ref.onDispose(() {
      _mounted = false;
      _debounceTimer?.cancel();
    });
    return const SearchState();
  }

  void setQuery(String query) {
    if (query == state.query && state.status != SearchStatus.idle) return;

    if (query.trim().isEmpty) {
      _debounceTimer?.cancel();
      state = const SearchState();
      return;
    }

    state = state.copyWith(
      query: query,
      status: SearchStatus.loading,
      clearError: true,
    );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void removeScreenshot(int id) {
    final updatedList = state.results
        .where((r) => r.screenshotId != id)
        .toList();
    if (updatedList.length != state.results.length) {
      state = state.copyWith(results: updatedList);
    }
  }

  void updateScreenshot(int id, {bool? isFavorite}) {
    final index = state.results.indexWhere((r) => r.screenshotId == id);
    if (index != -1) {
      final updatedList = List<SearchResult>.from(state.results);
      final current = updatedList[index];
      updatedList[index] = current.copyWith(
        isFavorite: isFavorite ?? current.isFavorite,
      );
      state = state.copyWith(results: updatedList);
    }
  }

  Future<void> _performSearch(String query) async {
    if (!_mounted) return;

    final dao = ref.read(searchDaoProvider);
    try {
      final results = await dao.search(query);
      if (!_mounted) return;

      // Prevent stale results from overwriting newer queries
      if (query != state.query) return;

      if (results.isEmpty) {
        state = state.copyWith(status: SearchStatus.empty, results: []);
      } else {
        state = state.copyWith(status: SearchStatus.results, results: results);
      }
    } catch (e) {
      if (!_mounted) return;

      if (query != state.query) return;

      state = state.copyWith(status: SearchStatus.error, error: e.toString());
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
