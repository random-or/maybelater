import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maybelater/features/gallery/screens/gallery_screen.dart';
import 'package:maybelater/features/gallery/providers/gallery_provider.dart';
import 'package:maybelater/core/models/screenshot.dart';

void main() {
  testWidgets('GalleryScreen shows loading initially', (tester) async {
    final state = const GalleryState(isLoading: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryProvider.overrideWith(() => _MockGalleryNotifier(state)),
        ],
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('GalleryScreen empty state', (tester) async {
    final state = const GalleryState(isLoading: false, screenshots: []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryProvider.overrideWith(() => _MockGalleryNotifier(state)),
        ],
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );

    expect(find.text('No screenshots found.'), findsOneWidget);
  });

  testWidgets('GalleryScreen missing thumbnail handling (null path)', (
    tester,
  ) async {
    final screenshot = Screenshot(
      id: 1,
      filepath: '/path/1',
      thumbnailPath: null, // missing path
      createdAt: 1000,
      importedAt: 1000,
      updatedAt: 1000,
    );

    final state = GalleryState(
      isLoading: false,
      hasMore: false,
      screenshots: [screenshot],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryProvider.overrideWith(() => _MockGalleryNotifier(state)),
        ],
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
  });

  testWidgets('GalleryScreen missing thumbnail handling (file not found)', (
    tester,
  ) async {
    final screenshot = Screenshot(
      id: 1,
      filepath: '/path/1',
      thumbnailPath: '/does_not_exist/thumb.jpg', // missing file
      createdAt: 1000,
      importedAt: 1000,
      updatedAt: 1000,
    );

    final state = GalleryState(
      isLoading: false,
      hasMore: false,
      screenshots: [screenshot],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryProvider.overrideWith(() => _MockGalleryNotifier(state)),
        ],
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });

  testWidgets('GalleryScreen multi-select toggles app bar', (tester) async {
    final screenshot = Screenshot(
      id: 1,
      filepath: '/path/1',
      thumbnailPath: null,
      createdAt: 1000,
      importedAt: 1000,
      updatedAt: 1000,
    );

    final state = GalleryState(
      isLoading: false,
      hasMore: false,
      screenshots: [screenshot],
      selectedIds: {1}, // one selected
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryProvider.overrideWith(() => _MockGalleryNotifier(state)),
        ],
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );

    expect(find.text('1 Selected'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}

class _MockGalleryNotifier extends GalleryNotifier {
  final GalleryState _initialState;

  _MockGalleryNotifier(this._initialState);

  @override
  GalleryState build() {
    return _initialState;
  }

  @override
  Future<void> loadNextPage() async {}
}
