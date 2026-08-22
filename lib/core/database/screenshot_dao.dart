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

  Future<void> insertBatch(List<Screenshot> screenshots) async {
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final s in screenshots) {
        batch.insert(
          'screenshots',
          s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
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

  /// Find a screenshot by its content hash (for duplicate detection)
  Future<Screenshot?> getByContentHash(String contentHash) async {
    final db = await _dbManager.database;
    final maps = await db.query(
      'screenshots',
      where: 'content_hash = ? AND is_deleted = 0',
      whereArgs: [contentHash],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Screenshot.fromMap(maps.first);
    }
    return null;
  }

  /// Get all screenshots with a specific processing status
  Future<List<Screenshot>> getByStatus(String status, {int? limit}) async {
    final db = await _dbManager.database;
    final maps = await db.query(
      'screenshots',
      where: 'processing_status = ? AND is_deleted = 0',
      whereArgs: [status],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Screenshot.fromMap(maps[i]));
  }

  /// Count screenshots by processing status
  Future<int> countByStatus(String status) async {
    final db = await _dbManager.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM screenshots WHERE processing_status = ? AND is_deleted = 0',
      [status],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Reset stale 'importing' jobs back to 'pending' for crash recovery
  /// and 'ocr_processing' jobs back to 'imported'
  Future<int> recoverStaleJobs() async {
    final db = await _dbManager.database;
    int recovered = 0;
    recovered += await db.update(
      'screenshots',
      {
        'processing_status': 'pending',
        'processing_error': '',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'processing_status = ?',
      whereArgs: ['importing'],
    );
    recovered += await db.update(
      'screenshots',
      {
        'processing_status': 'imported',
        'processing_error': '',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'processing_status = ?',
      whereArgs: ['ocr_processing'],
    );
    return recovered;
  }

  /// Update OCR text and mark as completed
  Future<int> updateOcrText(int id, String text) async {
    final db = await _dbManager.database;
    return await db.update(
      'screenshots',
      {
        'ocr_text': text,
        'processing_status': 'completed',
        'processing_error': '',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update only the processing status and error for a screenshot
  Future<int> updateProcessingStatus(
    int id,
    String status, {
    String error = '',
  }) async {
    final db = await _dbManager.database;
    return await db.update(
      'screenshots',
      {
        'processing_status': status,
        'processing_error': error,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update import-related fields after successful processing
  Future<int> updateImportFields(
    int id, {
    required String filepath,
    required String thumbnailPath,
    required String contentHash,
    required int fileSize,
    required int width,
    required int height,
  }) async {
    final db = await _dbManager.database;
    return await db.update(
      'screenshots',
      {
        'filepath': filepath,
        'thumbnail_path': thumbnailPath,
        'content_hash': contentHash,
        'file_size': fileSize,
        'width': width,
        'height': height,
        'processing_status': 'imported',
        'processing_error': '',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total import progress counts
  Future<Map<String, int>> getImportCounts() async {
    final db = await _dbManager.database;
    final result = await db.rawQuery('''
      SELECT processing_status, COUNT(*) as count
      FROM screenshots
      WHERE is_deleted = 0
      GROUP BY processing_status
    ''');
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['processing_status'] as String] = row['count'] as int;
    }
    return counts;
  }

  /// Get screenshots with cursor-based pagination
  Future<List<Screenshot>> getPaged({
    required int limit,
    int? lastCreatedAt,
    int? lastId,
    bool descending = true,
  }) async {
    final db = await _dbManager.database;

    String whereClause = 'is_deleted = 0';
    List<Object> whereArgs = [];

    if (lastCreatedAt != null && lastId != null) {
      if (descending) {
        whereClause += ' AND (created_at < ? OR (created_at = ? AND id < ?))';
      } else {
        whereClause += ' AND (created_at > ? OR (created_at = ? AND id > ?))';
      }
      whereArgs.addAll([lastCreatedAt, lastCreatedAt, lastId]);
    }

    final String order = descending ? 'DESC' : 'ASC';

    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at $order, id $order',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Screenshot.fromMap(maps[i]));
  }

  /// Toggle favorite status
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _dbManager.database;
    return await db.update(
      'screenshots',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle favorite status for multiple screenshots
  Future<int> batchToggleFavorite(List<int> ids, bool isFavorite) async {
    if (ids.isEmpty) return 0;
    final db = await _dbManager.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.update(
      'screenshots',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Batch soft delete
  Future<int> batchDelete(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await _dbManager.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.update(
      'screenshots',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
}
