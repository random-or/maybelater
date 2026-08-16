class Collection {
  final int? id;
  final String name;
  final String description;
  final String color;
  final String icon;
  final int createdAt;
  final int updatedAt;

  Collection({
    this.id,
    required this.name,
    this.description = '',
    this.color = '#7C3AED',
    this.icon = 'folder',
    required this.createdAt,
    required this.updatedAt,
  });

  Collection copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    int? createdAt,
    int? updatedAt,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      color: map['color'] as String,
      icon: map['icon'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
