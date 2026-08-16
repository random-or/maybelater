import 'package:sqflite/sqflite.dart';

import '../models/tag.dart';
import 'database_manager.dart';

class TagDao {
  final DatabaseManager _dbManager;

  TagDao(this._dbManager);

  Future<int> insert(Tag tag) async {
    final db = await _dbManager.database;
    return await db.insert(
      'tags',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Tag?> getByName(String name) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return Tag.fromMap(maps.first);
    }
    return null;
  }

  Future<void> linkTagToScreenshot(int screenshotId, int tagId) async {
    final db = await _dbManager.database;
    await db.insert('screenshot_tags', {
      'screenshot_id': screenshotId,
      'tag_id': tagId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getTagsForScreenshot(
    int screenshotId,
  ) async {
    final db = await _dbManager.database;
    return await db.rawQuery(
      '''
      SELECT t.* FROM tags t
      JOIN screenshot_tags st ON t.id = st.tag_id
      WHERE st.screenshot_id = ?
    ''',
      [screenshotId],
    );
  }
}
