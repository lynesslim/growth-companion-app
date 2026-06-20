class SocialStreak {
  final String id;
  final String userId1;
  final String userId2;
  final int currentStreak;
  final DateTime? lastSharedDate1;
  final DateTime? lastSharedDate2;

  const SocialStreak({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.currentStreak,
    this.lastSharedDate1,
    this.lastSharedDate2,
  });

  factory SocialStreak.fromJson(Map<String, dynamic> json) {
    return SocialStreak(
      id: json['id'] as String,
      userId1: json['user_id_1'] as String,
      userId2: json['user_id_2'] as String,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      lastSharedDate1: json['last_shared_date_1'] != null 
          ? DateTime.parse(json['last_shared_date_1'] as String) 
          : null,
      lastSharedDate2: json['last_shared_date_2'] != null 
          ? DateTime.parse(json['last_shared_date_2'] as String) 
          : null,
    );
  }
}
