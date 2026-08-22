import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/search_dao.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).setQuery('');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(searchProvider.notifier).setQuery(value);
          },
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.status == SearchStatus.idle) {
      return const Center(
        child: Text(
          'Type to search your screenshots',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (state.status == SearchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SearchStatus.error) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (state.status == SearchStatus.empty) {
      return const Center(
        child: Text('No results found.', style: TextStyle(color: Colors.grey)),
      );
    }

    // Results state
    return ListView.separated(
      itemCount: state.results.length,
      padding: const EdgeInsets.all(8),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final result = state.results[index];
        return _SearchResultCard(result: result);
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF1E1E2E)),
      ),
      color: const Color(0xFF111118),
      child: InkWell(
        onTap: () {
          // Phase 7: Open detail
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(width: 100, height: 100, child: _buildThumbnail()),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.snippet.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            color: Color(0xFF94A3B8), // textSecondary
                            height: 1.4,
                          ),
                          children: _buildSnippetSpans(result.snippet),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const Text(
                        'No text snippet available',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Metadata row
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(result.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (result.thumbnailPath == null || result.thumbnailPath!.isEmpty) {
      return Container(
        color: const Color(0xFF1E1E2E),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    final file = File(result.thumbnailPath!);
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
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF1E1E2E),
          child: const Center(child: Icon(Icons.error, color: Colors.grey)),
        );
      },
    );
  }

  List<TextSpan> _buildSnippetSpans(String snippet) {
    final spans = <TextSpan>[];
    const markStart = '<mark>';
    const markEnd = '</mark>';

    int currentIndex = 0;

    while (true) {
      final startIndex = snippet.indexOf(markStart, currentIndex);
      if (startIndex == -1) {
        spans.add(TextSpan(text: snippet.substring(currentIndex)));
        break;
      }

      if (startIndex > currentIndex) {
        spans.add(TextSpan(text: snippet.substring(currentIndex, startIndex)));
      }

      final endIndex = snippet.indexOf(markEnd, startIndex + markStart.length);
      if (endIndex == -1) {
        spans.add(TextSpan(text: snippet.substring(startIndex)));
        break;
      }

      spans.add(
        TextSpan(
          text: snippet.substring(startIndex + markStart.length, endIndex),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE2E8F0), // textPrimary
            backgroundColor: Color(0x337C3AED), // accentGlow
          ),
        ),
      );

      currentIndex = endIndex + markEnd.length;
    }

    return spans;
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
