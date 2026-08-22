import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/models/screenshot.dart';
import 'package:maybelater/features/gallery/screens/gallery_screen.dart';
import 'package:maybelater/features/import/providers/import_provider.dart';

void main() {
  late DatabaseManager dbManager;
  late ScreenshotDao screenshotDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    await dbManager.initDatabase(pathOverride: 'test_gallery_perf_db.sqlite');
    await dbManager.clearAllData();
    screenshotDao = ScreenshotDao(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
    await databaseFactory.deleteDatabase('test_gallery_perf_db.sqlite');
  });

  Future<void> seedScreenshots(int count) async {
    final list = <Screenshot>[];
    for (int i = 0; i < count; i++) {
      list.add(
        Screenshot(
          filepath: '/path/to/test$i.png',
          thumbnailPath: null, // intentionally null for speed
          createdAt: 1000 + i,
          importedAt: 1000,
          updatedAt: 1000,
        ),
      );
    }

    // Insert in batches of 500
    for (int i = 0; i < list.length; i += 500) {
      final end = (i + 500 < list.length) ? i + 500 : list.length;
      await screenshotDao.insertBatch(list.sublist(i, end));
    }
  }

  testWidgets('Gallery handles 2,000+ records smoothly with lazy loading', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seedScreenshots(2500);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseManagerProvider.overrideWithValue(dbManager),
          screenshotDaoProvider.overrideWithValue(screenshotDao),
        ],
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );

    // Initial load loop
    for (int i = 0; i < 50; i++) {
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byType(GridView).evaluate().isNotEmpty) {
        break;
      }
    }

    // Check that we see the GridView
    expect(find.byType(GridView), findsOneWidget);

    final scrollable = find.byType(Scrollable);
    expect(scrollable, findsOneWidget);

    // Scroll down to trigger next page load
    await tester.drag(scrollable, const Offset(0, -3000));
    await tester.pump();

    // Wait for next page to load
    for (int j = 0; j < 20; j++) {
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    // Ensure the app doesn't crash and GridView is still there
    expect(find.byType(GridView), findsOneWidget);

    // Unmount to cancel any active Tickers (CircularProgressIndicator)
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
