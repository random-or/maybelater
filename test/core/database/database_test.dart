import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/database/collection_dao.dart';
import 'package:maybelater/core/database/tag_dao.dart';
import 'package:maybelater/core/database/search_history_dao.dart';
import 'package:maybelater/core/models/screenshot.dart';
import 'package:maybelater/core/models/collection.dart';
import 'package:maybelater/core/models/tag.dart';
import 'package:maybelater/core/models/search_history.dart';

void main() {
  late DatabaseManager dbManager;
  late ScreenshotDao screenshotDao;
  late CollectionDao collectionDao;
  late TagDao tagDao;
  late SearchHistoryDao searchHistoryDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    // Use in-memory for fast independent tests, wait, instructions say "Do NOT create an in-memory replacement database",
    // but sqflite in-memory is standard for tests. To be safe, I'll use a local test file.
    await dbManager.initDatabase(pathOverride: 'test_db.sqlite');
    await dbManager.clearAllData();

    screenshotDao = ScreenshotDao(dbManager);
    collectionDao = CollectionDao(dbManager);
    tagDao = TagDao(dbManager);
    searchHistoryDao = SearchHistoryDao(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
    await databaseFactory.deleteDatabase('test_db.sqlite');
  });

  test('Fresh database creation and correct version', () async {
    final db = await dbManager.database;
    final version = await db.getVersion();
    expect(version, DatabaseManager.databaseVersion);
  });

  test('All required tables and columns exist', () async {
    final db = await dbManager.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final tableNames = tables.map((t) => t['name'] as String).toList();

    expect(
      tableNames,
      containsAll([
        'collections',
        'screenshots',
        'tags',
        'screenshot_tags',
        'search_history',
        'screenshots_fts',
      ]),
    );

    // Check required columns for screenshots
    final columns = await db.rawQuery("PRAGMA table_info('screenshots')");
    final colNames = columns.map((c) => c['name'] as String).toList();
    expect(
      colNames,
      containsAll([
        'id',
        'filepath',
        'ocr_text',
        'collection_id',
        'content_hash',
      ]),
    );
  });

  test('Required indexes exist', () async {
    final db = await dbManager.database;
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index'",
    );
    final indexNames = indexes.map((i) => i['name'] as String).toList();

    expect(
      indexNames,
      containsAll([
        'idx_screenshots_hash',
        'idx_screenshots_created',
        'idx_screenshots_collection',
        'idx_screenshots_deleted',
        'idx_screenshots_status',
      ]),
    );
  });

  test('Foreign keys are enforced', () async {
    final db = await dbManager.database;

    // Check PRAGMA foreign_keys
    final fk = await db.rawQuery("PRAGMA foreign_keys");
    expect(fk.first['foreign_keys'], 1);

    // Try inserting screenshot with invalid collection_id (should fail)
    final screenshot = Screenshot(
      filepath: '/path/to/test.png',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      collectionId: 999, // Invalid
    );

    expect(
      () => screenshotDao.insert(screenshot),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('Insert, read, update, delete a screenshot record', () async {
    // 1. Insert
    final screenshot = Screenshot(
      filepath: '/path/to/test1.png',
      ocrText: 'Hello World',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final id = await screenshotDao.insert(screenshot);
    expect(id, isNotNull);
    expect(id, isPositive);

    // 2. Read
    final readScreenshot = await screenshotDao.getById(id);
    expect(readScreenshot, isNotNull);
    expect(readScreenshot!.filepath, '/path/to/test1.png');
    expect(readScreenshot.ocrText, 'Hello World');

    // 3. Update
    final updatedScreenshot = readScreenshot.copyWith(ocrText: 'Updated Text');
    await screenshotDao.update(updatedScreenshot);

    final readAgain = await screenshotDao.getById(id);
    expect(readAgain!.ocrText, 'Updated Text');

    // 4. Delete (Trash)
    await screenshotDao.delete(id);
    final deletedRecord = await screenshotDao.getById(id);
    expect(deletedRecord!.isDeleted, true);
    expect(deletedRecord.deletedAt, isNotNull);

    // getAll should not return deleted records
    final all = await screenshotDao.getAll();
    expect(all, isEmpty);
  });

  test('Collection relationships work', () async {
    final collection = Collection(
      name: 'Receipts',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final collectionId = await collectionDao.insert(collection);

    final screenshot = Screenshot(
      filepath: '/path/to/receipt.png',
      collectionId: collectionId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final screenshotId = await screenshotDao.insert(screenshot);
    final savedScreenshot = await screenshotDao.getById(screenshotId);

    expect(savedScreenshot!.collectionId, collectionId);

    final savedCollection = await collectionDao.getById(collectionId);
    expect(savedCollection!.name, 'Receipts');
  });

  test('Tag records work', () async {
    final tag = Tag(name: 'invoice');
    final tagId = await tagDao.insert(tag);

    final screenshot = Screenshot(
      filepath: '/path/to/invoice.png',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final screenshotId = await screenshotDao.insert(screenshot);

    await tagDao.linkTagToScreenshot(screenshotId, tagId);

    final tags = await tagDao.getTagsForScreenshot(screenshotId);
    expect(tags.length, 1);
    expect(tags.first['name'], 'invoice');
  });

  test('Search-history records work', () async {
    final history = SearchHistory(
      query: 'test query',
      searchedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await searchHistoryDao.insert(history);

    final recent = await searchHistoryDao.getRecent(10);
    expect(recent.length, 1);
    expect(recent.first.query, 'test query');
  });

  test('FTS insert, update, delete synchronization', () async {
    // Insert
    final screenshot = Screenshot(
      filepath: '/path/fts_test.png',
      ocrText: 'fox jumps over',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final id = await screenshotDao.insert(screenshot);

    var ftsResults = await screenshotDao.searchFts('fox');
    expect(ftsResults.length, 1);

    // Update
    final updated = (await screenshotDao.getById(id))!
        .copyWith(ocrText: 'dog barks loudly');
    await screenshotDao.update(updated);

    ftsResults = await screenshotDao.searchFts('fox');
    expect(ftsResults.length, 0); // fox is gone
    ftsResults = await screenshotDao.searchFts('dog');
    expect(ftsResults.length, 1); // dog is found

    // Delete
    await screenshotDao.permanentDelete(id); // trigger requires permanent delete, but wait, normal logical delete doesn't remove from FTS unless we want it to.
    // Usually logical delete hides it from search UI, but let's test physical delete for FTS triggers.
    ftsResults = await screenshotDao.searchFts('dog');
    expect(ftsResults.length, 0);
  });

  test('FTS rebuild behavior', () async {
    final screenshot = Screenshot(
      filepath: '/path/fts_rebuild.png',
      ocrText: 'rebuild test',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await screenshotDao.insert(screenshot);

    var ftsResults = await screenshotDao.searchFts('rebuild');
    expect(ftsResults.length, 1);

    // Mess up FTS manually to test rebuild
    final db = await dbManager.database;
    await db.execute("DELETE FROM screenshots_fts");
    ftsResults = await screenshotDao.searchFts('rebuild');
    expect(ftsResults.length, 0); // Gone

    // Rebuild
    await dbManager.rebuildFts();
    ftsResults = await screenshotDao.searchFts('rebuild');
    expect(ftsResults.length, 1); // Restored!
  });

  test('Opening an existing database does not destroy existing data', () async {
    // 1. Close current DB
    await dbManager.close();

    // 2. Open new DB manager pointing to same file
    final manager2 = DatabaseManager();
    await manager2.initDatabase(pathOverride: 'test_db.sqlite');

    // Insert something
    final s1 = Screenshot(
      filepath: '/path/exist.png',
      createdAt: 123,
      importedAt: 123,
      updatedAt: 123,
    );
    final dao = ScreenshotDao(manager2);
    await dao.insert(s1);

    await manager2.close();

    // 3. Open third DB manager pointing to same file
    final manager3 = DatabaseManager();
    await manager3.initDatabase(pathOverride: 'test_db.sqlite');
    final dao3 = ScreenshotDao(manager3);

    final all = await dao3.getAll();
    expect(all.length, 1);
    expect(all.first.filepath, '/path/exist.png');

    await manager3.close();
  });
}
