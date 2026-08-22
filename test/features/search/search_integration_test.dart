import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/features/import/providers/import_provider.dart';
import 'package:maybelater/features/search/screens/search_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseManager dbManager;
  const String testDbPath = 'test_search_integration_db.sqlite';

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    await dbManager.initDatabase(pathOverride: testDbPath);
    await dbManager.clearAllData();
  });

  tearDown(() async {
    await dbManager.close();
    await databaseFactory.deleteDatabase(testDbPath);

    // Fallback deletion just in case
    final file = File(testDbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  testWidgets('Integration: Search flow from UI to Database and back', (
    WidgetTester tester,
  ) async {
    final db = await dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Prepare realistic FTS data using real db connection (runs in setup, wait for it)
    await tester.runAsync(() async {
      await db.insert('screenshots', {
        'filepath': '/path/integration_test',
        'ocr_text': 'This is a full integration test with SQLite.',
        'created_at': now,
        'imported_at': now,
        'updated_at': now,
      });
    });

    // 2. Build the app with real database provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseManagerProvider.overrideWithValue(dbManager)],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );

    // 3. Verify idle
    expect(find.text('Type to search your screenshots'), findsOneWidget);

    // 4. Enter query
    await tester.enterText(find.byType(TextField), 'integration test');
    await tester.pump();

    // 5. Wait for debounce (Fake clock)
    await tester.pump(const Duration(milliseconds: 350));

    // 6. Yield to real event loop to allow FFI database query to complete
    bool queryFinished = false;
    for (int i = 0; i < 50; i++) {
      // 50 * 50ms = 2.5s maximum wait
      // Give real asynchronous isolate (FFI) time to execute and return the result
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 50)),
      );

      // Pump to process any frames/microtasks that the FakeAsync zone caught
      await tester.pump(const Duration(milliseconds: 50));

      if (find.byType(Card).evaluate().isNotEmpty) {
        queryFinished = true;
        break;
      }
    }

    if (!queryFinished) {
      fail(
        'Test timed out waiting for FTS5 search to complete and render results. '
        'UI remains in loading/empty state.',
      );
    }

    // 7. Verify full flow completed and rendered correct data
    expect(find.byType(Card), findsOneWidget);

    // Check highlighted text is rendered from DB snippet
    final richTextFinder = find.descendant(
      of: find.byType(Card),
      matching: find.byWidgetPredicate(
        (widget) => widget is RichText && widget.maxLines == 3,
      ),
    );
    expect(richTextFinder, findsOneWidget);

    final richText = tester.widget<RichText>(richTextFinder);
    final textSpan = richText.text as TextSpan;

    // Verify the raw string doesn't have <mark> but does contain the words.
    expect(find.textContaining('<mark>'), findsNothing);
    expect(textSpan.toPlainText(), contains('integration test'));

    // 8. Cleanup widget tree to remove any lingering animations
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
