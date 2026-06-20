class User {
  final String id;
  final String name;
  final Map<String, String> onboardingProfile;
  final int currentXp;
  final int level;
  final int currentStreak;

  const User({
    required this.id,
    required this.name,
    this.onboardingProfile = const {},
    this.currentXp = 0,
    this.level = 1,
    this.currentStreak = 0,
  });

  User copyWith({
    String? id,
    String? name,
    Map<String, String>? onboardingProfile,
    int? currentXp,
    int? level,
    int? currentStreak,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      onboardingProfile: onboardingProfile ?? this.onboardingProfile,
      currentXp: currentXp ?? this.currentXp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'onboarding_profile': onboardingProfile,
        'current_xp': currentXp,
        'level': level,
        'current_streak': currentStreak,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Explorer',
        onboardingProfile: (json['onboarding_profile'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            const {},
        currentXp: (json['current_xp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          name == other.name &&
          currentXp == other.currentXp &&
          level == other.level &&
          currentStreak == other.currentStreak;

  @override
  int get hashCode => Object.hash(id, name, currentXp, level, currentStreak);
}
