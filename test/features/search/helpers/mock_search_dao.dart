import 'dart:async';

import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/core/database/search_dao.dart';

class MockSearchDao extends SearchDao {
  MockSearchDao() : super(DatabaseManager());

  List<SearchResult>? mockResults;
  Exception? mockException;
  Duration? delay;

  // Track queries to test debounce and async races
  final List<String> queriedTerms = [];

  // Custom response logic
  Future<List<SearchResult>> Function(String)? onSearch;

  @override
  Future<List<SearchResult>> search(String query) async {
    queriedTerms.add(query);

    if (delay != null) {
      await Future.delayed(delay!);
    }

    if (onSearch != null) {
      return await onSearch!(query);
    }

    if (mockException != null) {
      throw mockException!;
    }

    if (mockResults != null) {
      return mockResults!;
    }

    return [];
  }
}
