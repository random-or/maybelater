import 'package:sqflite/sqflite.dart';

import '../models/search_history.dart';
import 'database_manager.dart';

class SearchHistoryDao {
  final DatabaseManager _dbManager;

  SearchHistoryDao(this._dbManager);

  Future<int> insert(SearchHistory history) async {
    final db = await _dbManager.database;
    return await db.insert(
      'search_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SearchHistory>> getRecent(int limit) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => SearchHistory.fromMap(maps[i]));
  }
}
