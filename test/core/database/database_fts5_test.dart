import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:maybelater/core/database/database_manager.dart';

void main() {
  late DatabaseManager dbManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    await dbManager.initDatabase(pathOverride: 'test_fts5_db.sqlite');
    await dbManager.clearAllData();
  });

  tearDown(() async {
    await dbManager.clearAllData();
    await dbManager.close();
  });

  test('FTS5 table creation and triggers work correctly', () async {
    final db = await dbManager.database;

    // 1. Insert a screenshot
    final id = await db.insert('screenshots', {
      'filepath': '/path/test1.jpg',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'imported_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'ocr_text': 'hello world fts5',
      'ai_labels': '[]',
      'manual_tags': '[]',
    });

    // 2. Verify FTS5 insert trigger
    final resultAfterInsert = await db.rawQuery(
      'SELECT rowid FROM screenshots_fts WHERE screenshots_fts MATCH ?',
      ['hello'],
    );
    expect(resultAfterInsert.length, 1);
    expect(resultAfterInsert.first['rowid'], id);

    // 3. Verify FTS5 update trigger
    await db.update(
      'screenshots',
      {'ocr_text': 'goodbye world fts5'},
      where: 'id = ?',
      whereArgs: [id],
    );

    final resultOldSearch = await db.rawQuery(
      'SELECT rowid FROM screenshots_fts WHERE screenshots_fts MATCH ?',
      ['hello'],
    );
    expect(resultOldSearch.isEmpty, true);

    final resultNewSearch = await db.rawQuery(
      'SELECT rowid FROM screenshots_fts WHERE screenshots_fts MATCH ?',
      ['goodbye'],
    );
    expect(resultNewSearch.length, 1);
    expect(resultNewSearch.first['rowid'], id);

    // 4. Verify rebuildFts()
    await db.execute('DELETE FROM screenshots_fts');

    final resultAfterDeleteFts = await db.rawQuery(
      'SELECT rowid FROM screenshots_fts WHERE screenshots_fts MATCH ?',
      ['goodbye'],
    );
    expect(resultAfterDeleteFts.isEmpty, true);

    await dbManager.rebuildFts();

    final resultAfterRebuild = await db.rawQuery(
      'SELECT rowid FROM screenshots_fts WHERE screenshots_fts MATCH ?',
      ['goodbye'],
    );
    expect(resultAfterRebuild.length, 1);
    expect(resultAfterRebuild.first['rowid'], id);

    // 5. Verify FTS5 delete trigger
    await db.delete('screenshots', where: 'id = ?', whereArgs: [id]);

    final resultAfterDelete = await db.rawQuery(
      'SELECT rowid FROM screenshots_fts WHERE screenshots_fts MATCH ?',
      ['goodbye'],
    );
    expect(resultAfterDelete.isEmpty, true);
  });
}
