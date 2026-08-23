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

    // Invalidate so the detail screen fetches the new state
    ref.invalidate(screenshotDetailProvider(current.id!));
    // Invalidate gallery so the heart icon updates there too
    ref.invalidate(galleryProvider);
  }

  Future<void> delete(Screenshot current) async {
    final dao = ref.read(screenshotDaoProvider);
    await dao.delete(current.id!);

    // Invalidate list providers
    ref.invalidate(galleryProvider);
    ref.invalidate(searchProvider);
  }
}
