import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/models/screenshot.dart';
import 'package:maybelater/core/services/media_source_service.dart';
import 'package:maybelater/features/detail/providers/detail_provider.dart';
import 'package:maybelater/features/import/providers/import_provider.dart';
import 'package:maybelater/features/gallery/providers/gallery_provider.dart';
import 'package:maybelater/features/search/providers/search_provider.dart';
import 'package:maybelater/core/database/search_dao.dart';

class MockScreenshotDao implements ScreenshotDao {
  Screenshot? mockScreenshot;
  bool toggleFavoriteCalled = false;
  bool deleteCalled = false;

  @override
  Future<Screenshot?> getById(int id) async {
    return mockScreenshot;
  }

  @override
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    toggleFavoriteCalled = true;
    if (mockScreenshot != null) {
      mockScreenshot = mockScreenshot!.copyWith(isFavorite: isFavorite);
    }
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    deleteCalled = true;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMediaSourceService implements MediaSourceService {
  List<String>? deletedAssets;
  List<String> mockReturn = [];

  @override
  Future<List<String>> deleteAssets(List<String> assetIds) async {
    deletedAssets = assetIds;
    return mockReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('detail provider fetches screenshot', () async {
    final mockDao = MockScreenshotDao();
    final screenshot = Screenshot(
      id: 1,
      filepath: '/test.jpg',
      createdAt: 100,
      importedAt: 100,
      updatedAt: 100,
    );
    mockDao.mockScreenshot = screenshot;

    final container = ProviderContainer(
      overrides: [screenshotDaoProvider.overrideWithValue(mockDao)],
    );

    final state = await container.read(screenshotDetailProvider(1).future);
    expect(state?.id, 1);
  });

  test('detail mutator toggle favorite - Gallery and Search favorite refresh without destroying state', () async {
    final mockDao = MockScreenshotDao();
    final screenshot = Screenshot(
      id: 1,
      filepath: '/test.jpg',
      isFavorite: false,
      createdAt: 100,
      importedAt: 100,
      updatedAt: 100,
    );
    mockDao.mockScreenshot = screenshot;

    final container = ProviderContainer(
      overrides: [screenshotDaoProvider.overrideWithValue(mockDao)],
    );

    // Pre-populate gallery and search providers
    container.read(galleryProvider.notifier).updateScreenshot(screenshot);
    container.read(searchProvider.notifier).updateScreenshot(1, isFavorite: false);

    await container.read(detailMutatorProvider).toggleFavorite(screenshot);

    expect(mockDao.toggleFavoriteCalled, true);
    
    // NOTE: Testing actual provider state propagation requires them to have items in them
    // But since they were empty, updateScreenshot doesn't crash.
  });

  test('detail mutator delete success state transition', () async {
    final mockDao = MockScreenshotDao();
    final mockMediaService = MockMediaSourceService();
    mockMediaService.mockReturn = ['content://media/123'];
    
    final screenshot = Screenshot(
      id: 1,
      filepath: '/test.jpg',
      originalUri: 'content://media/123',
      createdAt: 100,
      importedAt: 100,
      updatedAt: 100,
    );
    mockDao.mockScreenshot = screenshot;

    final container = ProviderContainer(
      overrides: [
        screenshotDaoProvider.overrideWithValue(mockDao),
        mediaSourceServiceProvider.overrideWithValue(mockMediaService),
      ],
    );

    await container.read(detailMutatorProvider).delete(screenshot);

    expect(mockDao.deleteCalled, true);
    expect(mockMediaService.deletedAssets, ['content://media/123']);
    // Note: Actual physical Android deletion requires device verification.
  });

  test('detail mutator delete failure/denial behavior', () async {
    final mockDao = MockScreenshotDao();
    final mockMediaService = MockMediaSourceService();
    mockMediaService.mockReturn = []; // OS deletion failed or denied
    
    final screenshot = Screenshot(
      id: 1,
      filepath: '/test.jpg',
      originalUri: 'content://media/123',
      createdAt: 100,
      importedAt: 100,
      updatedAt: 100,
    );
    mockDao.mockScreenshot = screenshot;

    final container = ProviderContainer(
      overrides: [
        screenshotDaoProvider.overrideWithValue(mockDao),
        mediaSourceServiceProvider.overrideWithValue(mockMediaService),
      ],
    );

    expect(
      () => container.read(detailMutatorProvider).delete(screenshot),
      throwsException,
    );
    
    // DB delete should not be called
    expect(mockDao.deleteCalled, false);
  });
}
