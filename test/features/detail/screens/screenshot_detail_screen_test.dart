import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maybelater/features/detail/screens/screenshot_detail_screen.dart';
import 'package:maybelater/features/detail/providers/detail_provider.dart';
import 'package:maybelater/core/models/screenshot.dart';

void main() {
  testWidgets('DetailScreen shows loading initially', (tester) async {
    final completer = Completer<Screenshot?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotDetailProvider(1).overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: ScreenshotDetailScreen(id: 1)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('DetailScreen shows not found', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotDetailProvider(1).overrideWith((ref) => Future.value(null)),
        ],
        child: const MaterialApp(home: ScreenshotDetailScreen(id: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Screenshot not found.'), findsOneWidget);
  });

  testWidgets('DetailScreen displays OCR text', (tester) async {
    final screenshot = Screenshot(
      id: 1,
      filepath: '',
      thumbnailPath: null,
      ocrText: 'Test OCR Content',
      createdAt: 1000,
      importedAt: 1000,
      updatedAt: 1000,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotDetailProvider(1)
              .overrideWith((ref) => Future.value(screenshot)),
        ],
        child: const MaterialApp(home: ScreenshotDetailScreen(id: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Test OCR Content'), findsOneWidget);
  });

  testWidgets('DetailScreen missing media handling', (tester) async {
    final screenshot = Screenshot(
      id: 1,
      filepath: '/does_not_exist.jpg',
      thumbnailPath: null,
      ocrText: '',
      createdAt: 1000,
      importedAt: 1000,
      updatedAt: 1000,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotDetailProvider(1)
              .overrideWith((ref) => Future.value(screenshot)),
        ],
        child: const MaterialApp(home: ScreenshotDetailScreen(id: 1)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
