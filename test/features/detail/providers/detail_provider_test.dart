import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/models/screenshot.dart';
import 'package:maybelater/features/detail/providers/detail_provider.dart';
import 'package:maybelater/features/import/providers/import_provider.dart';

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

    // Wait for the provider to complete
    final state = await container.read(screenshotDetailProvider(1).future);

    expect(state?.id, 1);
    expect(state?.filepath, '/test.jpg');
  });

  test('detail mutator toggle favorite', () async {
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

    // Toggle favorite
    await container.read(detailMutatorProvider).toggleFavorite(screenshot);

    expect(mockDao.toggleFavoriteCalled, true);
  });

  test('detail mutator delete', () async {
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

    // Delete
    await container.read(detailMutatorProvider).delete(screenshot);

    expect(mockDao.deleteCalled, true);
  });
}
