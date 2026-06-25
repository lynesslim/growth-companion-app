class User {
  final String id;
  final String name;
  final Map<String, String> onboardingProfile;
  final int currentXp;
  final int level;
  final int currentStreak;
  final DateTime? lastDropDate;
  final bool isAdmin;
  final int booksRead;
  final bool hasCompletedTutorial;

  const User({
    required this.id,
    required this.name,
    this.onboardingProfile = const {},
    this.currentXp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.lastDropDate,
    this.isAdmin = false,
    this.booksRead = 0,
    this.hasCompletedTutorial = false,
  });

  User copyWith({
    String? id,
    String? name,
    Map<String, String>? onboardingProfile,
    int? currentXp,
    int? level,
    int? currentStreak,
    DateTime? lastDropDate,
    bool? isAdmin,
    int? booksRead,
    bool? hasCompletedTutorial,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      onboardingProfile: onboardingProfile ?? this.onboardingProfile,
      currentXp: currentXp ?? this.currentXp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      lastDropDate: lastDropDate ?? this.lastDropDate,
      isAdmin: isAdmin ?? this.isAdmin,
      booksRead: booksRead ?? this.booksRead,
      hasCompletedTutorial: hasCompletedTutorial ?? this.hasCompletedTutorial,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'onboarding_profile': onboardingProfile,
        'current_xp': currentXp,
        'level': level,
        'current_streak': currentStreak,
        'last_active_date': lastDropDate?.toIso8601String().split('T')[0],
        'is_admin': isAdmin,
        'books_read': booksRead,
        'has_completed_tutorial': hasCompletedTutorial,
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
        lastDropDate: json['last_active_date'] != null
            ? DateTime.parse(json['last_active_date'] as String)
            : null,
        isAdmin: (json['is_admin'] as bool?) ?? false,
        booksRead: (json['books_read'] as num?)?.toInt() ?? 0,
        hasCompletedTutorial: (json['has_completed_tutorial'] as bool?) ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          name == other.name &&
          currentXp == other.currentXp &&
          level == other.level &&
          currentStreak == other.currentStreak &&
          isAdmin == other.isAdmin &&
          booksRead == other.booksRead &&
          hasCompletedTutorial == other.hasCompletedTutorial;

  @override
  int get hashCode => Object.hash(id, name, currentXp, level, currentStreak, isAdmin, booksRead, hasCompletedTutorial);
}
