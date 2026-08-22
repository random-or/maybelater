import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/database/search_dao.dart';
import 'package:maybelater/features/search/providers/search_provider.dart';

import '../helpers/mock_search_dao.dart';

import 'dart:async';

void main() {
  late ProviderContainer container;
  late MockSearchDao mockSearchDao;

  setUp(() {
    mockSearchDao = MockSearchDao();
    container = ProviderContainer(
      overrides: [searchDaoProvider.overrideWithValue(mockSearchDao)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state is idle and empty', () {
    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.idle);
    expect(state.query, '');
    expect(state.results, isEmpty);
  });

  test('Empty query resets state to idle', () {
    final notifier = container.read(searchProvider.notifier);
    notifier.setQuery('   ');

    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.idle);
    expect(state.query, '');
    expect(mockSearchDao.queriedTerms.isEmpty, true); // No search occurred
  });

  test('setQuery triggers loading state and debounces search', () async {
    final result = SearchResult(
      screenshotId: 1,
      snippet: 'test snippet',
      tags: '[]',
      createdAt: 0,
    );
    mockSearchDao.mockResults = [result];

    final notifier = container.read(searchProvider.notifier);

    // Set query
    notifier.setQuery('python');

    // Immediate state should be loading
    var state = container.read(searchProvider);
    expect(state.status, SearchStatus.loading);
    expect(state.query, 'python');
    expect(state.results, isEmpty);

    // Wait for debounce timer (300ms)
    await Future.delayed(const Duration(milliseconds: 350));

    // State should now have results
    state = container.read(searchProvider);
    expect(state.status, SearchStatus.results);
    expect(state.results.length, 1);
    expect(state.results.first.screenshotId, 1);

    // Verify DAO was called after debounce
    expect(mockSearchDao.queriedTerms.length, 1);
    expect(mockSearchDao.queriedTerms.first, 'python');
  });

  test('Debounce prevents multiple searches', () async {
    final notifier = container.read(searchProvider.notifier);

    notifier.setQuery('p');
    notifier.setQuery('py');
    notifier.setQuery('python');

    await Future.delayed(const Duration(milliseconds: 350));

    final state = container.read(searchProvider);
    expect(
      state.status,
      SearchStatus.empty,
    ); // since mockResults is null, returns []
    expect(state.query, 'python');
    expect(mockSearchDao.queriedTerms.length, 1); // Only called once
    expect(mockSearchDao.queriedTerms.first, 'python');
  });

  test('Empty results are handled correctly', () async {
    mockSearchDao.mockResults = [];
    final notifier = container.read(searchProvider.notifier);

    notifier.setQuery('nonexistent');
    await Future.delayed(const Duration(milliseconds: 350));

    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.empty);
    expect(state.results, isEmpty);
  });

  test('Error state is handled correctly', () async {
    mockSearchDao.mockException = Exception('Test search error');
    final notifier = container.read(searchProvider.notifier);

    notifier.setQuery('error');
    await Future.delayed(const Duration(milliseconds: 350));

    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.error);
    expect(state.error, contains('Test search error'));
  });

  test('Stale async queries do not overwrite newer queries', () async {
    final completerA = Completer<List<SearchResult>>();
    final completerB = Completer<List<SearchResult>>();

    mockSearchDao.onSearch = (query) {
      if (query == 'query A') {
        return completerA.future;
      } else if (query == 'query B') {
        return completerB.future;
      }
      return Future.value([]);
    };

    final notifier = container.read(searchProvider.notifier);

    // 1. Query A starts
    notifier.setQuery('query A');
    await Future.delayed(
      const Duration(milliseconds: 350),
    ); // let debounce pass

    // 3. Query B starts afterward
    notifier.setQuery('query B');
    await Future.delayed(
      const Duration(milliseconds: 350),
    ); // let debounce pass

    // 4. Query B completes first
    final resultB = [
      SearchResult(screenshotId: 2, snippet: 'B', tags: '[]', createdAt: 0),
    ];
    completerB.complete(resultB);

    // Wait for event loop
    await Future.delayed(const Duration(milliseconds: 50));

    // 5. B becomes the current result
    var state = container.read(searchProvider);
    expect(state.query, 'query B');
    expect(state.status, SearchStatus.results);
    expect(state.results.length, 1);
    expect(state.results.first.snippet, 'B');

    // 6. Query A completes afterward
    final resultA = [
      SearchResult(screenshotId: 1, snippet: 'A', tags: '[]', createdAt: 0),
    ];
    completerA.complete(resultA);

    // Wait for event loop
    await Future.delayed(const Duration(milliseconds: 50));

    // 7. A MUST NOT overwrite B's results
    state = container.read(searchProvider);
    expect(state.query, 'query B');
    expect(state.status, SearchStatus.results);
    expect(state.results.length, 1);
    expect(state.results.first.snippet, 'B'); // Should still be B
  });
}
