import 'package:maybelater/core/database/database_manager.dart';

class SearchResult {
  final int screenshotId;
  final String? thumbnailPath;
  final String snippet;
  final int? collectionId;
  final String tags;
  final int createdAt;

  SearchResult({
    required this.screenshotId,
    this.thumbnailPath,
    required this.snippet,
    this.collectionId,
    required this.tags,
    required this.createdAt,
  });
}

class SearchDao {
  final DatabaseManager _dbManager;

  SearchDao(this._dbManager);

  String normalizeQuery(String query) {
    // Remove FTS5 control characters and punctuation to prevent syntax errors
    final sanitized = query.replaceAll(
      RegExp(r'[^\p{L}\p{N}\s]', unicode: true),
      ' ',
    );
    final terms = sanitized
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return '';

    // Parameterized FTS queries still require proper FTS syntax in the string.
    // We require all terms to be present as a prefix match at minimum.
    return terms.map((t) => '"$t"*').join(' AND ');
  }

  Future<List<SearchResult>> search(String query) async {
    final normalized = normalizeQuery(query);
    if (normalized.isEmpty) return [];

    final db = await _dbManager.database;

    // We join screenshots_fts with screenshots
    // snippet(fts, column_index, start_match, end_match, ellipsis, max_tokens)
    // We use bm25 for ranking. Weights: ocr_text=10.0, ai_labels=1.0, manual_tags=5.0
    // Negative weights because SQLite bm25 returns negative values (more negative = better) in some versions,
    // wait, actually standard FTS5 bm25 returns positive values? No, FTS5 bm25() returns negative values. "The value returned is the negative of the BM25 score." So ORDER BY bm25() ASC is correct.

    final sql = '''
      SELECT 
        s.id,
        s.thumbnail_path,
        s.collection_id,
        s.manual_tags,
        s.created_at,
        s.ocr_text,
        snippet(screenshots_fts, -1, '<mark>', '</mark>', '...', 15) as ocr_snippet
      FROM screenshots_fts fts
      JOIN screenshots s ON fts.rowid = s.id
      WHERE screenshots_fts MATCH ?
      ORDER BY bm25(screenshots_fts, 10.0, 1.0, 5.0) ASC, s.created_at DESC
      LIMIT 200
    ''';

    final queryRaw = query.trim().toLowerCase();
    final results = await db.rawQuery(sql, [normalized]);

    final searchResults = results.map((row) {
      String snippetStr = (row['ocr_snippet'] as String?) ?? '';
      final ocrText = (row['ocr_text'] as String?)?.toLowerCase() ?? '';

      int rankScore = 0;
      if (ocrText == queryRaw) {
        rankScore = 2; // exact
      } else if (ocrText.contains(queryRaw)) {
        rankScore = 1; // phrase
      }

      return _RankedResult(
        result: SearchResult(
          screenshotId: row['id'] as int,
          thumbnailPath: row['thumbnail_path'] as String?,
          snippet: snippetStr,
          collectionId: row['collection_id'] as int?,
          tags: row['manual_tags'] as String? ?? '[]',
          createdAt: row['created_at'] as int,
        ),
        rankScore: rankScore,
      );
    }).toList();

    // Sort stably: highest rankScore first, keeping original BM25 order for ties
    searchResults.sort((a, b) => b.rankScore.compareTo(a.rankScore));

    return searchResults.take(100).map((e) => e.result).toList();
  }
}

class _RankedResult {
  final SearchResult result;
  final int rankScore;
  _RankedResult({required this.result, required this.rankScore});
}
