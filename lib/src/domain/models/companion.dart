class Companion {
  final String id;
  final String name;
  final String type;
  final String description;
  final String assetPath;

  const Companion({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.assetPath,
  });

  Companion copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    String? assetPath,
  }) {
    return Companion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      assetPath: assetPath ?? this.assetPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'description': description,
        'assetPath': assetPath,
      };

  factory Companion.fromJson(Map<String, dynamic> json) => Companion(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        description: json['description'] as String,
        assetPath: json['assetPath'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Companion && id == other.id && name == other.name && type == other.type;

  @override
  int get hashCode => Object.hash(id, name, type);
}
