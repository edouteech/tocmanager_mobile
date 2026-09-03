class Category {
  final int? id;
  final String name;
  final String? description;
  final int color;
  final int icon;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        color: map['color'] as int,
        icon: map['icon'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'color': color,
        'icon': icon,
        'created_at': createdAt.toIso8601String(),
      };

  Category copyWith({
    int? id,
    String? name,
    String? description,
    int? color,
    int? icon,
    DateTime? createdAt,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        createdAt: createdAt ?? this.createdAt,
      );
}
