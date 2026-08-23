import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/screenshot.dart';
import '../providers/detail_provider.dart';

class ScreenshotDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const ScreenshotDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ScreenshotDetailScreen> createState() =>
      _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState
    extends ConsumerState<ScreenshotDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(screenshotDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        actions: state.when(
          data: (screenshot) {
            if (screenshot == null) return [];
            return [
              IconButton(
                icon: Icon(
                  screenshot.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: screenshot.isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  ref.read(detailMutatorProvider).toggleFavorite(screenshot);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareScreenshot(screenshot),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteScreenshot(screenshot),
              ),
            ];
          },
          loading: () => [],
          error: (_, _) => [],
        ),
      ),
      body: state.when(
        data: (screenshot) {
          if (screenshot == null) {
            return const Center(child: Text('Screenshot not found.'));
          }
          return _buildContent(screenshot);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(Screenshot screenshot) {
    return Column(
      children: [
        Expanded(flex: 2, child: _buildImageViewer(screenshot)),
        Expanded(flex: 1, child: _buildDetailsPanel(screenshot)),
      ],
    );
  }

  Widget _buildImageViewer(Screenshot screenshot) {
    File? imageFile;
    if (screenshot.filepath.isNotEmpty) {
      final file = File(screenshot.filepath);
      if (file.existsSync()) {
        imageFile = file;
      }
    }

    if (imageFile == null && (screenshot.thumbnailPath?.isNotEmpty ?? false)) {
      final thumb = File(screenshot.thumbnailPath!);
      if (thumb.existsSync()) {
        imageFile = thumb;
      }
    }

    if (imageFile == null) {
      return const Center(
        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
      );
    }

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Center(child: Image.file(imageFile, fit: BoxFit.contain)),
    );
  }

  Widget _buildDetailsPanel(Screenshot screenshot) {
    return Container(
      color: const Color(0xFF111118),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OCR Text',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (screenshot.ocrText.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: screenshot.ocrText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: screenshot.ocrText.isEmpty
                  ? const Text(
                      'No OCR text available.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : SelectableText(
                      screenshot.ocrText,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tags: ${screenshot.manualTags.isEmpty || screenshot.manualTags == '[]' ? 'None' : screenshot.manualTags}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  'Collection: ${screenshot.collectionId == null ? 'None' : 'ID: ${screenshot.collectionId}'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareScreenshot(Screenshot screenshot) {
    final path = screenshot.filepath.isNotEmpty
        ? screenshot.filepath
        : screenshot.thumbnailPath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No media available to share.')),
      );
      return;
    }

    final file = File(path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media file not found on device.')),
      );
      return;
    }

    SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Screenshot from MaybeLater'),
    );
  }

  Future<void> _deleteScreenshot(Screenshot screenshot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Screenshot?'),
        content: const Text('This will move the screenshot to trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(detailMutatorProvider).delete(screenshot);
      if (mounted) {
        context.pop();
      }
    }
  }
}
