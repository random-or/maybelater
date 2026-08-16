class Tag {
  final int? id;
  final String name;
  final int usageCount;

  Tag({this.id, required this.name, this.usageCount = 0});

  Tag copyWith({int? id, String? name, int? usageCount}) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {if (id != null) 'id': id, 'name': name, 'usage_count': usageCount};
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      usageCount: map['usage_count'] as int,
    );
  }
}

class ScreenshotTag {
  final int screenshotId;
  final int tagId;

  ScreenshotTag({required this.screenshotId, required this.tagId});

  Map<String, dynamic> toMap() {
    return {'screenshot_id': screenshotId, 'tag_id': tagId};
  }

  factory ScreenshotTag.fromMap(Map<String, dynamic> map) {
    return ScreenshotTag(
      screenshotId: map['screenshot_id'] as int,
      tagId: map['tag_id'] as int,
    );
  }
}
