import 'package:sqflite/sqflite.dart';

import '../models/collection.dart';
import 'database_manager.dart';

class CollectionDao {
  final DatabaseManager _dbManager;

  CollectionDao(this._dbManager);

  Future<int> insert(Collection collection) async {
    final db = await _dbManager.database;
    return await db.insert(
      'collections',
      collection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Collection?> getById(int id) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Collection.fromMap(maps.first);
    }
    return null;
  }
}
