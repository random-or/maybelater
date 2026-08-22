import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:maybelater/core/database/database_manager.dart';
import 'package:maybelater/core/database/screenshot_dao.dart';
import 'package:maybelater/core/models/screenshot.dart';
import 'package:maybelater/features/gallery/providers/gallery_provider.dart';
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
    await dbManager.initDatabase(
      pathOverride: 'test_gallery_provider_db.sqlite',
    );
    await dbManager.clearAllData();
    screenshotDao = ScreenshotDao(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
    await databaseFactory.deleteDatabase('test_gallery_provider_db.sqlite');
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        databaseManagerProvider.overrideWithValue(dbManager),
        screenshotDaoProvider.overrideWithValue(screenshotDao),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> seedScreenshots(int count) async {
    final list = <Screenshot>[];
    for (int i = 0; i < count; i++) {
      list.add(
        Screenshot(
          filepath: '/path/to/test$i.png',
          createdAt: 1000 + i,
          importedAt: 1000,
          updatedAt: 1000,
        ),
      );
    }
    await screenshotDao.insertBatch(list);
  }

  Future<void> waitForState(
    ProviderContainer container,
    bool Function(GalleryState) condition,
  ) async {
    for (int i = 0; i < 50; i++) {
      if (condition(container.read(galleryProvider))) return;
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  test('GalleryNotifier loads first page on init', () async {
    await seedScreenshots(10);
    final container = createContainer();
    container.read(galleryProvider.notifier);

    await waitForState(
      container,
      (s) => !s.isLoading && s.screenshots.isNotEmpty,
    );

    final state = container.read(galleryProvider);
    expect(state.isLoading, false);
    expect(state.screenshots.length, 10);
    expect(state.hasMore, false);
  });

  test('GalleryNotifier loadNextPage appends items', () async {
    await seedScreenshots(110);
    final container = createContainer();
    final notifier = container.read(galleryProvider.notifier);

    await waitForState(
      container,
      (s) => !s.isLoading && s.screenshots.isNotEmpty,
    );

    var state = container.read(galleryProvider);
    expect(state.screenshots.length, 50);
    expect(state.hasMore, true);

    await notifier.loadNextPage();
    await waitForState(
      container,
      (s) => !s.isLoading && s.screenshots.length == 100,
    );
    state = container.read(galleryProvider);
    expect(state.screenshots.length, 100);
    expect(state.hasMore, true);

    await notifier.loadNextPage();
    await waitForState(
      container,
      (s) => !s.isLoading && s.screenshots.length == 110,
    );
    state = container.read(galleryProvider);
    expect(state.screenshots.length, 110);
    expect(state.hasMore, false);
  });

  test('GalleryNotifier setSortMode resets and reloads', () async {
    await seedScreenshots(10);
    final container = createContainer();
    final notifier = container.read(galleryProvider.notifier);

    await waitForState(
      container,
      (s) => !s.isLoading && s.screenshots.isNotEmpty,
    );

    var state = container.read(galleryProvider);
    expect(state.sortMode, GallerySortMode.newestFirst);
    final firstIdDesc = state.screenshots.first.id;

    await notifier.setSortMode(GallerySortMode.oldestFirst);
    await waitForState(
      container,
      (s) =>
          !s.isLoading &&
          s.sortMode == GallerySortMode.oldestFirst &&
          s.screenshots.isNotEmpty,
    );

    state = container.read(galleryProvider);
    expect(state.sortMode, GallerySortMode.oldestFirst);
    expect(state.screenshots.length, 10);
    expect(state.screenshots.first.id, isNot(firstIdDesc));
  });

  test('GalleryNotifier toggleSelection and clearSelection', () async {
    final container = createContainer();
    final notifier = container.read(galleryProvider.notifier);

    notifier.toggleSelection(1);
    notifier.toggleSelection(2);

    var state = container.read(galleryProvider);
    expect(state.selectedIds, {1, 2});

    notifier.toggleSelection(1);
    state = container.read(galleryProvider);
    expect(state.selectedIds, {2});

    notifier.clearSelection();
    state = container.read(galleryProvider);
    expect(state.selectedIds, isEmpty);
  });

  test(
    'GalleryNotifier batchDelete removes selected and clears selection',
    () async {
      await seedScreenshots(5);
      final container = createContainer();
      final notifier = container.read(galleryProvider.notifier);

      await waitForState(
        container,
        (s) => !s.isLoading && s.screenshots.isNotEmpty,
      );

      var state = container.read(galleryProvider);
      final idsToDelete = [state.screenshots[0].id!, state.screenshots[1].id!];

      notifier.toggleSelection(idsToDelete[0]);
      notifier.toggleSelection(idsToDelete[1]);

      await notifier.batchDelete();
      await Future.delayed(const Duration(milliseconds: 50));

      state = container.read(galleryProvider);
      expect(state.screenshots.length, 3);
      expect(state.selectedIds, isEmpty);

      final dbAll = await screenshotDao.getAll();
      expect(dbAll.length, 3);
    },
  );

  test('GalleryNotifier batchToggleFavorite updates selected', () async {
    await seedScreenshots(3);
    final container = createContainer();
    final notifier = container.read(galleryProvider.notifier);

    await waitForState(
      container,
      (s) => !s.isLoading && s.screenshots.isNotEmpty,
    );

    var state = container.read(galleryProvider);
    final idsToFav = [state.screenshots[0].id!, state.screenshots[2].id!];

    notifier.toggleSelection(idsToFav[0]);
    notifier.toggleSelection(idsToFav[1]);

    await notifier.batchToggleFavorite(true);
    await Future.delayed(const Duration(milliseconds: 50));

    state = container.read(galleryProvider);
    expect(state.selectedIds, isEmpty);
    expect(state.screenshots[0].isFavorite, true);
    expect(state.screenshots[1].isFavorite, false);
    expect(state.screenshots[2].isFavorite, true);

    final s0 = await screenshotDao.getById(idsToFav[0]);
    expect(s0!.isFavorite, true);
  });
}
