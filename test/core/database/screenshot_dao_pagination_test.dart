import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/models/screenshot.dart';

void main() {
  late DatabaseManager dbManager;
  late ScreenshotDao screenshotDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    await dbManager.initDatabase(pathOverride: 'test_pagination_db.sqlite');
    await dbManager.clearAllData();
    screenshotDao = ScreenshotDao(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
    await databaseFactory.deleteDatabase('test_pagination_db.sqlite');
  });

  Future<void> seedScreenshots(int count) async {
    final list = <Screenshot>[];
    for (int i = 0; i < count; i++) {
      list.add(
        Screenshot(
          filepath: '/path/to/test$i.png',
          createdAt: 1000 + i, // ascending created_at
          importedAt: 1000,
          updatedAt: 1000,
        ),
      );
    }
    await screenshotDao.insertBatch(list);
  }

  test('getPaged returns limit correctly', () async {
    await seedScreenshots(10);
    final page1 = await screenshotDao.getPaged(limit: 5, descending: true);
    expect(page1.length, 5);
  });

  test('getPaged pagination descending with tiebreak', () async {
    // Insert with SAME created_at to test tiebreaker
    final list = <Screenshot>[];
    for (int i = 0; i < 5; i++) {
      list.add(
        Screenshot(
          filepath: '/path/to/test$i.png',
          createdAt: 2000,
          importedAt: 1000,
          updatedAt: 1000,
        ),
      );
    }
    await screenshotDao.insertBatch(list);

    final all = await screenshotDao.getAll();
    expect(all.length, 5);

    // Sort manually by created_at DESC, id DESC to get expected order
    all.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      if (c != 0) return c;
      return b.id!.compareTo(a.id!);
    });

    // Fetch first 2
    final page1 = await screenshotDao.getPaged(limit: 2, descending: true);
    expect(page1.length, 2);
    expect(page1[0].id, all[0].id);
    expect(page1[1].id, all[1].id);

    // Fetch next 2
    final page2 = await screenshotDao.getPaged(
      limit: 2,
      lastCreatedAt: page1.last.createdAt,
      lastId: page1.last.id,
      descending: true,
    );
    expect(page2.length, 2);
    expect(page2[0].id, all[2].id);
    expect(page2[1].id, all[3].id);

    // Fetch last 1
    final page3 = await screenshotDao.getPaged(
      limit: 2,
      lastCreatedAt: page2.last.createdAt,
      lastId: page2.last.id,
      descending: true,
    );
    expect(page3.length, 1);
    expect(page3[0].id, all[4].id);
  });

  test('getPaged pagination ascending with tiebreak', () async {
    final list = <Screenshot>[];
    for (int i = 0; i < 5; i++) {
      list.add(
        Screenshot(
          filepath: '/path/to/asc$i.png',
          createdAt: 3000,
          importedAt: 1000,
          updatedAt: 1000,
        ),
      );
    }
    await screenshotDao.insertBatch(list);

    final all = await screenshotDao.getAll();
    all.sort((a, b) {
      final c = a.createdAt.compareTo(b.createdAt);
      if (c != 0) return c;
      return a.id!.compareTo(b.id!);
    });

    final page1 = await screenshotDao.getPaged(limit: 2, descending: false);
    expect(page1.length, 2);
    expect(page1[0].id, all[0].id);
    expect(page1[1].id, all[1].id);

    final page2 = await screenshotDao.getPaged(
      limit: 2,
      lastCreatedAt: page1.last.createdAt,
      lastId: page1.last.id,
      descending: false,
    );
    expect(page2.length, 2);
    expect(page2[0].id, all[2].id);
    expect(page2[1].id, all[3].id);
  });

  test('batchDelete soft deletes correctly', () async {
    await seedScreenshots(5);
    final all = await screenshotDao.getAll();
    expect(all.length, 5);

    final idsToDelete = [all[0].id!, all[2].id!];
    final count = await screenshotDao.batchDelete(idsToDelete);
    expect(count, 2);

    final remaining = await screenshotDao.getAll();
    expect(remaining.length, 3);

    final s1 = await screenshotDao.getById(idsToDelete[0]);
    expect(s1!.isDeleted, true);
    expect(s1.deletedAt, isNotNull);
  });

  test('toggleFavorite works', () async {
    await seedScreenshots(1);
    final all = await screenshotDao.getAll();
    final id = all[0].id!;

    await screenshotDao.toggleFavorite(id, true);
    var updated = await screenshotDao.getById(id);
    expect(updated!.isFavorite, true);

    await screenshotDao.toggleFavorite(id, false);
    updated = await screenshotDao.getById(id);
    expect(updated!.isFavorite, false);
  });

  test('batchToggleFavorite works', () async {
    await seedScreenshots(3);
    final all = await screenshotDao.getAll();
    final ids = all.map((e) => e.id!).toList();

    await screenshotDao.batchToggleFavorite(ids, true);
    for (var id in ids) {
      final s = await screenshotDao.getById(id);
      expect(s!.isFavorite, true);
    }
  });
}
