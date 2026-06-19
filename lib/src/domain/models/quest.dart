class Quest {
  final String id;
  final String title;
  final int xpReward;
  final bool isCompleted;
  final String type;
  final String description;
  final String xpCategory;
  final String duration;
  final DateTime? completedAt;

  const Quest({
    required this.id,
    required this.title,
    this.xpReward = 10,
    this.isCompleted = false,
    required this.type,
    required this.description,
    required this.xpCategory,
    required this.duration,
    this.completedAt,
  });

  Quest copyWith({
    String? id,
    String? title,
    int? xpReward,
    bool? isCompleted,
    String? type,
    String? description,
    String? xpCategory,
    String? duration,
    DateTime? completedAt,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      description: description ?? this.description,
      xpCategory: xpCategory ?? this.xpCategory,
      duration: duration ?? this.duration,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'xpReward': xpReward,
        'isCompleted': isCompleted,
        'type': type,
        'description': description,
        'xpCategory': xpCategory,
        'duration': duration,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        title: json['title'] as String,
        xpReward: (json['xpReward'] as num?)?.toInt() ?? 10,
        isCompleted: json['isCompleted'] as bool? ?? false,
        type: json['type'] as String,
        description: json['description'] as String,
        xpCategory: json['xpCategory'] as String,
        duration: json['duration'] as String,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quest &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, title, isCompleted, type);
}
