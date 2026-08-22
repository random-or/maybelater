import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/core/database/search_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:math';

void main() {
  late DatabaseManager dbManager;
  late SearchDao searchDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    await dbManager.initDatabase(pathOverride: inMemoryDatabasePath);
    searchDao = SearchDao(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
  });

  test('10k dataset performance test', () async {
    final db = await dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Generate 10k records
    var batch = db.batch();
    final random = Random(42);

    // Some keywords we want to search for
    final targets = ['python', 'error', 'oauth', 'flutter', 'dart', 'database'];

    for (int i = 0; i < 10000; i++) {
      // Add target words randomly
      String text = 'This is mock text for record $i. ';
      if (random.nextDouble() < 0.1) {
        text += '${targets[random.nextInt(targets.length)]} ';
        text += '${targets[random.nextInt(targets.length)]} ';
      }
      // Add some more random padding
      for (int j = 0; j < 5; j++) {
        text += 'randomWord${random.nextInt(100)} ';
      }

      batch.insert('screenshots', {
        'filepath': '/mock/path/$i',
        'ocr_text': text,
        'created_at': now - i, // Ensure varied dates
        'imported_at': now - i,
        'updated_at': now - i,
      });

      if (i % 500 == 0 && i > 0) {
        await batch.commit(noResult: true);
        batch = db.batch();
      }
    }
    // Commit any remaining
    await batch.commit(noResult: true);

    // Measure actual elapsed query time
    final stopwatch = Stopwatch()..start();
    await searchDao.search('python error');
    stopwatch.stop();

    // Verify it is under 100ms
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
}
