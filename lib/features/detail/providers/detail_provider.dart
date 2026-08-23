import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/screenshot.dart';
import '../../import/providers/import_provider.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../../search/providers/search_provider.dart';

final screenshotDetailProvider = FutureProvider.autoDispose
    .family<Screenshot?, int>((ref, id) {
      final dao = ref.watch(screenshotDaoProvider);
      return dao.getById(id);
    });

final detailMutatorProvider = Provider<DetailMutator>((ref) {
  return DetailMutator(ref);
});

class DetailMutator {
  final Ref ref;

  DetailMutator(this.ref);

  Future<void> toggleFavorite(Screenshot current) async {
    final dao = ref.read(screenshotDaoProvider);
    final newFavoriteState = !current.isFavorite;

    await dao.toggleFavorite(current.id!, newFavoriteState);

    ref.invalidate(screenshotDetailProvider(current.id!));

    ref
        .read(galleryProvider.notifier)
        .updateScreenshot(current.copyWith(isFavorite: newFavoriteState));

    ref
        .read(searchProvider.notifier)
        .updateScreenshot(current.id!, isFavorite: newFavoriteState);
  }

  Future<void> delete(Screenshot current) async {
    if (current.originalUri != null && current.originalUri!.isNotEmpty) {
      final mediaService = ref.read(mediaSourceServiceProvider);
      final deletedIds = await mediaService.deleteAssets([
        current.originalUri!,
      ]);

      // If the asset wasn't deleted (e.g. user denied the dialog or error), abort DB deletion
      if (!deletedIds.contains(current.originalUri)) {
        throw Exception('OS-level deletion was denied or failed.');
      }
    }

    final dao = ref.read(screenshotDaoProvider);
    await dao.delete(current.id!);

    // Targeted removal instead of destructive invalidation
    ref.read(galleryProvider.notifier).removeScreenshot(current.id!);
    ref.read(searchProvider.notifier).removeScreenshot(current.id!);
  }
}
