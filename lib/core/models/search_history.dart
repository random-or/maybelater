class SearchHistory {
  final int? id;
  final String query;
  final int searchedAt;

  SearchHistory({this.id, required this.query, required this.searchedAt});

  SearchHistory copyWith({int? id, String? query, int? searchedAt}) {
    return SearchHistory(
      id: id ?? this.id,
      query: query ?? this.query,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'query': query,
      'searched_at': searchedAt,
    };
  }

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map['id'] as int?,
      query: map['query'] as String,
      searchedAt: map['searched_at'] as int,
    );
  }
}
