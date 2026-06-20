import 'user.dart';

class Friend {
  final String id;
  final String userId1;
  final String userId2;
  final String status;
  final DateTime createdAt;
  final User? profile;

  const Friend({
    required this.id,
    required this.userId1,
    required this.userId2,
    this.status = 'accepted',
    required this.createdAt,
    this.profile,
  });

  factory Friend.fromJson(Map<String, dynamic> json, {User? profile}) {
    return Friend(
      id: json['id'] as String,
      userId1: json['user_id_1'] as String,
      userId2: json['user_id_2'] as String,
      status: json['status'] as String? ?? 'accepted',
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: profile,
    );
  }
}
