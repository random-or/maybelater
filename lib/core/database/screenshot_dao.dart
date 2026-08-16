import 'package:sqflite/sqflite.dart';

import '../models/screenshot.dart';
import 'database_manager.dart';

class ScreenshotDao {
  final DatabaseManager _dbManager;

  ScreenshotDao(this._dbManager);

  Future<int> insert(Screenshot screenshot) async {
    final db = await _dbManager.database;
    return await db.insert(
      'screenshots',
      screenshot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Screenshot?> getById(int id) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Screenshot.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(Screenshot screenshot) async {
    final db = await _dbManager.database;
    return await db.update(
      'screenshots',
      screenshot.toMap(),
      where: 'id = ?',
      whereArgs: [screenshot.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbManager.database;
    // According to AD-007, users delete moves to trash. We implement logical delete or physical.
    // The requirement says "According to documented deletion model" which is "Trash before permanent delete".
    // "Delete the record according to the documented deletion model."
    // So this means setting is_deleted = 1 and deleted_at = now

    return await db.update(
      'screenshots',
      {'is_deleted': 1, 'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> permanentDelete(int id) async {
    final db = await _dbManager.database;
    return await db.delete('screenshots', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Screenshot>> getAll() async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where: 'is_deleted = 0',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Screenshot.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> searchFts(String query) async {
    final db = await _dbManager.database;
    // Phase 1 doesn't require full search implementation, but we need to verify FTS sync
    return await db.rawQuery(
      '''
      SELECT rowid, * FROM screenshots_fts
      WHERE screenshots_fts MATCH ?
    ''',
      [query],
    );
  }
}
