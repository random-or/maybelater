class Screenshot {
  final int? id;
  final String filepath;
  final String? thumbnailPath;
  final String? originalUri;
  final String filename;
  final String ocrText;
  final String aiLabels;
  final String manualTags;
  final int? collectionId;
  final String source;
  final int createdAt;
  final int importedAt;
  final int updatedAt;
  final int fileSize;
  final int width;
  final int height;
  final String? contentHash;
  final String processingStatus;
  final String processingError;
  final bool isDeleted;
  final int? deletedAt;
  final bool isFavorite;

  Screenshot({
    this.id,
    required this.filepath,
    this.thumbnailPath,
    this.originalUri,
    this.filename = '',
    this.ocrText = '',
    this.aiLabels = '[]',
    this.manualTags = '[]',
    this.collectionId,
    this.source = 'import',
    required this.createdAt,
    required this.importedAt,
    required this.updatedAt,
    this.fileSize = 0,
    this.width = 0,
    this.height = 0,
    this.contentHash,
    this.processingStatus = 'pending',
    this.processingError = '',
    this.isDeleted = false,
    this.deletedAt,
    this.isFavorite = false,
  });

  Screenshot copyWith({
    int? id,
    String? filepath,
    String? thumbnailPath,
    String? originalUri,
    String? filename,
    String? ocrText,
    String? aiLabels,
    String? manualTags,
    int? collectionId,
    String? source,
    int? createdAt,
    int? importedAt,
    int? updatedAt,
    int? fileSize,
    int? width,
    int? height,
    String? contentHash,
    String? processingStatus,
    String? processingError,
    bool? isDeleted,
    int? deletedAt,
    bool? isFavorite,
  }) {
    return Screenshot(
      id: id ?? this.id,
      filepath: filepath ?? this.filepath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      originalUri: originalUri ?? this.originalUri,
      filename: filename ?? this.filename,
      ocrText: ocrText ?? this.ocrText,
      aiLabels: aiLabels ?? this.aiLabels,
      manualTags: manualTags ?? this.manualTags,
      collectionId: collectionId ?? this.collectionId,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      importedAt: importedAt ?? this.importedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      contentHash: contentHash ?? this.contentHash,
      processingStatus: processingStatus ?? this.processingStatus,
      processingError: processingError ?? this.processingError,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'filepath': filepath,
      'thumbnail_path': thumbnailPath,
      'original_uri': originalUri,
      'filename': filename,
      'ocr_text': ocrText,
      'ai_labels': aiLabels,
      'manual_tags': manualTags,
      'collection_id': collectionId,
      'source': source,
      'created_at': createdAt,
      'imported_at': importedAt,
      'updated_at': updatedAt,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'content_hash': contentHash,
      'processing_status': processingStatus,
      'processing_error': processingError,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Screenshot.fromMap(Map<String, dynamic> map) {
    return Screenshot(
      id: map['id'] as int?,
      filepath: map['filepath'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      originalUri: map['original_uri'] as String?,
      filename: map['filename'] as String? ?? '',
      ocrText: map['ocr_text'] as String? ?? '',
      aiLabels: map['ai_labels'] as String? ?? '[]',
      manualTags: map['manual_tags'] as String? ?? '[]',
      collectionId: map['collection_id'] as int?,
      source: map['source'] as String? ?? 'import',
      createdAt: map['created_at'] as int,
      importedAt: map['imported_at'] as int,
      updatedAt: map['updated_at'] as int,
      fileSize: map['file_size'] as int? ?? 0,
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
      contentHash: map['content_hash'] as String?,
      processingStatus: map['processing_status'] as String? ?? 'pending',
      processingError: map['processing_error'] as String? ?? '',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] as int?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }
}
