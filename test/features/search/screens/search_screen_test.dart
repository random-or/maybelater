import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maybelater/core/database/search_dao.dart';
import 'package:maybelater/features/search/providers/search_provider.dart';
import 'package:maybelater/features/search/screens/search_screen.dart';

import '../helpers/mock_search_dao.dart';

void main() {
  late MockSearchDao mockSearchDao;

  setUp(() {
    mockSearchDao = MockSearchDao();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [searchDaoProvider.overrideWithValue(mockSearchDao)],
      child: const MaterialApp(home: SearchScreen()),
    );
  }

  testWidgets('SearchScreen shows idle state initially', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('Type to search your screenshots'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('SearchScreen shows loading indicator while searching', (
    WidgetTester tester,
  ) async {
    mockSearchDao.delay = const Duration(
      seconds: 1,
    ); // Induce loading state long enough

    await tester.pumpWidget(createTestWidget());
    await tester.enterText(find.byType(TextField), 'query');

    // UI should show loading immediately when query is entered
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Cleanup
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('SearchScreen shows empty state when no results', (
    WidgetTester tester,
  ) async {
    mockSearchDao.mockResults = [];

    await tester.pumpWidget(createTestWidget());
    await tester.enterText(find.byType(TextField), 'missingquery');

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('SearchScreen shows results with realistic SearchResult', (
    WidgetTester tester,
  ) async {
    mockSearchDao.mockResults = [
      SearchResult(
        screenshotId: 1,
        snippet: 'A normal snippet',
        tags: '[]',
        createdAt: 0,
      ),
    ];

    await tester.pumpWidget(createTestWidget());
    await tester.enterText(find.byType(TextField), 'query');

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Expect the card to render
    expect(find.byType(Card), findsOneWidget);
    // Expect the text snippet to be shown
    expect(find.text('A normal snippet', findRichText: true), findsOneWidget);
  });

  testWidgets('SearchScreen renders highlighted text spans properly', (
    WidgetTester tester,
  ) async {
    mockSearchDao.mockResults = [
      SearchResult(
        screenshotId: 1,
        snippet: 'There was a <mark>python</mark> error.',
        tags: '[]',
        createdAt: 0,
      ),
    ];

    await tester.pumpWidget(createTestWidget());
    await tester.enterText(find.byType(TextField), 'python');

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Find the RichText widget for the snippet (it has maxLines: 3)
    final richTextFinder = find.descendant(
      of: find.byType(Card),
      matching: find.byWidgetPredicate(
        (widget) => widget is RichText && widget.maxLines == 3,
      ),
    );
    expect(richTextFinder, findsOneWidget);

    final richText = tester.widget<RichText>(richTextFinder);
    final TextSpan textSpan = richText.text as TextSpan;

    // The snippet should have been parsed into three parts:
    // 1. "There was a "
    // 2. "python" (highlighted)
    // 3. " error."
    expect(textSpan.children, isNotNull);
    expect(textSpan.children!.length, 3);

    expect((textSpan.children![0] as TextSpan).text, 'There was a ');

    final highlightedSpan = textSpan.children![1] as TextSpan;
    expect(highlightedSpan.text, 'python');
    expect(highlightedSpan.style!.fontWeight, FontWeight.bold);

    expect((textSpan.children![2] as TextSpan).text, ' error.');

    // Ensure raw `<mark>` tags are not displayed
    expect(find.textContaining('<mark>'), findsNothing);
  });

  testWidgets('SearchScreen handles missing or invalid thumbnails safely', (
    WidgetTester tester,
  ) async {
    mockSearchDao.mockResults = [
      SearchResult(
        screenshotId: 1,
        thumbnailPath: null, // Missing thumbnail
        snippet: 'Missing thumbnail snippet',
        tags: '[]',
        createdAt: 0,
      ),
      SearchResult(
        screenshotId: 2,
        thumbnailPath: '/invalid/path/does_not_exist.jpg', // Invalid thumbnail
        snippet: 'Invalid thumbnail snippet',
        tags: '[]',
        createdAt: 0,
      ),
    ];

    await tester.pumpWidget(createTestWidget());
    await tester.enterText(find.byType(TextField), 'query');

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify it rendered both results
    expect(find.byType(Card), findsNWidgets(2));

    // Verify fallback icons
    expect(find.byIcon(Icons.image_not_supported), findsOneWidget); // for null
    expect(find.byIcon(Icons.broken_image), findsOneWidget); // for invalid path
  });

  testWidgets('SearchScreen displays error UI when DAO throws', (
    WidgetTester tester,
  ) async {
    mockSearchDao.mockException = Exception('Database failure');

    await tester.pumpWidget(createTestWidget());
    await tester.enterText(find.byType(TextField), 'fail');

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Error: Exception: Database failure'),
      findsOneWidget,
    );
  });

  testWidgets('Clear button resets search to idle state', (
    WidgetTester tester,
  ) async {
    mockSearchDao.mockResults = [];
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.byType(TextField), 'python');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Clear the input
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump(); // No debounce delay when clearing

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, '');

    expect(find.text('Type to search your screenshots'), findsOneWidget);
  });
}
