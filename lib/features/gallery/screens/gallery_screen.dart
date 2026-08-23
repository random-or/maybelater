import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/gallery_provider.dart';
import '../../../core/models/screenshot.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(galleryProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(galleryProvider);
    final isSelectionMode = state.selectedIds.isNotEmpty;

    return Scaffold(
      appBar: isSelectionMode
          ? _buildSelectionAppBar(state)
          : _buildNormalAppBar(state),
      body: _buildBody(state),
    );
  }

  AppBar _buildNormalAppBar(GalleryState state) {
    return AppBar(
      title: const Text('Library'),
      actions: [
        PopupMenuButton<GallerySortMode>(
          icon: const Icon(Icons.sort),
          onSelected: (mode) {
            ref.read(galleryProvider.notifier).setSortMode(mode);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: GallerySortMode.newestFirst,
              child: Text('Newest First'),
            ),
            const PopupMenuItem(
              value: GallerySortMode.oldestFirst,
              child: Text('Oldest First'),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.push('/settings');
          },
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar(GalleryState state) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => ref.read(galleryProvider.notifier).clearSelection(),
      ),
      title: Text('${state.selectedIds.length} Selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () {
            ref.read(galleryProvider.notifier).batchToggleFavorite(true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            ref.read(galleryProvider.notifier).batchToggleFavorite(false);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            ref.read(galleryProvider.notifier).batchDelete();
          },
        ),
      ],
    );
  }

  Widget _buildBody(GalleryState state) {
    if (state.error != null && state.screenshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}'),
            ElevatedButton(
              onPressed: () => ref.read(galleryProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.screenshots.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.screenshots.isEmpty) {
      return const Center(child: Text('No screenshots found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(galleryProvider.notifier).refresh(),
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: state.screenshots.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.screenshots.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final screenshot = state.screenshots[index];
          final isSelected = state.selectedIds.contains(screenshot.id);

          return _GalleryItem(
            screenshot: screenshot,
            isSelected: isSelected,
            isSelectionMode: state.selectedIds.isNotEmpty,
            onTap: () {
              if (state.selectedIds.isNotEmpty) {
                ref
                    .read(galleryProvider.notifier)
                    .toggleSelection(screenshot.id!);
              } else {
                context.push('/detail/${screenshot.id}');
              }
            },
            onLongPress: () {
              ref
                  .read(galleryProvider.notifier)
                  .toggleSelection(screenshot.id!);
            },
            onFavoriteToggle: () {
              ref
                  .read(galleryProvider.notifier)
                  .toggleFavorite(screenshot.id!, !screenshot.isFavorite);
            },
          );
        },
      ),
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final Screenshot screenshot;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavoriteToggle;

  const _GalleryItem({
    required this.screenshot,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnail(),
          if (isSelected)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Icon(Icons.check_circle, color: Colors.white, size: 32),
              ),
            ),
          if (!isSelected && isSelectionMode) Container(color: Colors.black26),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onFavoriteToggle,
              child: Icon(
                screenshot.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: screenshot.isFavorite ? Colors.red : Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (screenshot.thumbnailPath == null || screenshot.thumbnailPath!.isEmpty) {
      return Container(
        color: const Color(0xFF1E1E2E),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    final file = File(screenshot.thumbnailPath!);
    if (!file.existsSync()) {
      return Container(
        color: const Color(0xFF1E1E2E),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: 300, // Bound decoded image size
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF1E1E2E),
          child: const Center(child: Icon(Icons.error, color: Colors.grey)),
        );
      },
    );
  }
}
