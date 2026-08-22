import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/core/database/search_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseManager dbManager;
  late SearchDao searchDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    // Force a fresh in-memory database for testing
    await dbManager.initDatabase(pathOverride: inMemoryDatabasePath);
    searchDao = SearchDao(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
  });

  test('normalizeQuery sanitizes inputs correctly', () {
    expect(searchDao.normalizeQuery('python error'), '"python"* AND "error"*');
    expect(
      searchDao.normalizeQuery('  multiple   spaces  '),
      '"multiple"* AND "spaces"*',
    );
    expect(
      searchDao.normalizeQuery('punctu.ation!@#'),
      '"punctu"* AND "ation"*',
    );
    expect(
      searchDao.normalizeQuery('"quotes" & apostrophe\'s'),
      '"quotes"* AND "apostrophe"* AND "s"*',
    );
    expect(searchDao.normalizeQuery(''), '');
    expect(searchDao.normalizeQuery('   '), '');
    expect(
      searchDao.normalizeQuery('OR NOT AND'),
      '"OR"* AND "NOT"* AND "AND"*',
    ); // FTS keywords should be treated as literal prefix terms
  });

  test('search returns results with snippets and ranks correctly', () async {
    final db = await dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert mock screenshots
    await db.insert('screenshots', {
      'filepath': '/path/1',
      'ocr_text': 'There was a python error in the code.',
      'created_at': now,
      'imported_at': now,
      'updated_at': now,
    });

    await db.insert('screenshots', {
      'filepath': '/path/2',
      'ocr_text': 'A large snake, specifically a python, was found.',
      'created_at': now - 1000,
      'imported_at': now - 1000,
      'updated_at': now - 1000,
    });

    await db.insert('screenshots', {
      'filepath': '/path/3',
      'ocr_text': 'I saw an error in the logs.',
      'created_at': now - 2000,
      'imported_at': now - 2000,
      'updated_at': now - 2000,
    });

    // Tag match
    await db.insert('screenshots', {
      'filepath': '/path/4',
      'ocr_text': 'Unrelated text',
      'manual_tags': '["python", "error"]',
      'created_at': now - 3000,
      'imported_at': now - 3000,
      'updated_at': now - 3000,
    });

    final results = await searchDao.search('python error');

    // Should match path/1 (both words in OCR) and path/4 (both words in tags).
    // Path 2 only has python, path 3 only has error. With AND queries, they shouldn't match.
    expect(results.length, 2);

    // Ranking: path/1 (OCR match) should rank higher than path/4 (Tag match)
    // Wait, bm25 weights are 10.0 for OCR, 5.0 for tags.
    // Wait, negative values mean smaller is better, but higher weight means larger negative value?
    // SQLite docs: "The bm25() function returns a value that is the negative of the BM25 score".
    // So a higher score becomes a more negative number, which comes first in ASC order.

    expect(results[0].screenshotId, 1); // OCR match
    expect(results[1].screenshotId, 4); // Tag match

    expect(results[0].snippet, contains('<mark>python</mark>'));
    expect(results[0].snippet, contains('<mark>error</mark>'));
  });

  test('FTS rebuild mechanism works', () async {
    final db = await dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert directly bypassing triggers if possible? No, we insert normally, then we'll delete from FTS directly
    await db.insert('screenshots', {
      'filepath': '/path/rebuild',
      'ocr_text': 'rebuild testing text',
      'created_at': now,
      'imported_at': now,
      'updated_at': now,
    });

    var results = await searchDao.search('rebuild');
    expect(results.length, 1);

    // Delete FTS index manually
    await db.execute('DELETE FROM screenshots_fts');

    results = await searchDao.search('rebuild');
    expect(results.length, 0);

    // Call rebuild
    await dbManager.rebuildFts();

    results = await searchDao.search('rebuild');
    expect(results.length, 1);
  });
}
