import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/features/import/providers/import_provider.dart';
import 'package:maybelater/features/search/screens/search_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseManager dbManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = DatabaseManager();
    await dbManager.initDatabase(pathOverride: inMemoryDatabasePath);
  });

  tearDown(() async {
    await dbManager.close();
  });

  testWidgets('Integration: Search flow from UI to Database and back', (
    WidgetTester tester,
  ) async {
    final db = await dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Prepare realistic FTS data
    await db.insert('screenshots', {
      'filepath': '/path/integration_test',
      'ocr_text': 'This is a full integration test with SQLite.',
      'created_at': now,
      'imported_at': now,
      'updated_at': now,
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

    // 5. Wait for debounce and database query
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // 6. Verify full flow completed and rendered correct data
    expect(find.byType(Card), findsOneWidget);

    // Check highlighted text is rendered from DB snippet
    // Text should be "This is a full <mark>integration</mark> <mark>test</mark> with SQLite."
    // which gets parsed into text spans
    final richTextFinder = find.descendant(
      of: find.byType(Card),
      matching: find.byWidgetPredicate(
        (widget) => widget is RichText && widget.maxLines == 3,
      ),
    );
    expect(richTextFinder, findsOneWidget);

    final richText = tester.widget<RichText>(richTextFinder);
    final textSpan = richText.text as TextSpan;

    // We expect some parts to be highlighted. We'll just verify the raw string doesn't have <mark>
    // but does contain the words.
    expect(find.textContaining('<mark>'), findsNothing);
    expect(textSpan.toPlainText(), contains('integration test'));
  });
}
