import 'growth_drop.dart';
import 'user.dart';

class SocialDrop {
  final String id;
  final String senderId;
  final String recipientId;
  final DateTime dropDate;
  final GrowthDrop bookData;
  final bool isOpened;
  final DateTime createdAt;
  final User? senderProfile;

  const SocialDrop({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.dropDate,
    required this.bookData,
    this.isOpened = false,
    required this.createdAt,
    this.senderProfile,
  });

  factory SocialDrop.fromJson(Map<String, dynamic> json, {User? senderProfile}) {
    final bookDataJson = json['book_data'] as Map<String, dynamic>;
    final bookData = GrowthDrop.fromJson({
      'id': json['id'],
      'user_id': json['recipient_id'],
      'drop_date': json['drop_date'],
      'focus_area': 'Social Drop',
      'book_title': bookDataJson['bookTitle'] ?? '',
      'book_author': bookDataJson['bookAuthor'] ?? '',
      'what_its_about': bookDataJson['whatItsAbout'] ?? '',
      'lessons': bookDataJson['lessons'] ?? [],
      'summary': bookDataJson['summary'] ?? '',
      'is_read': json['is_opened'] ?? false,
      'giftedBy': senderProfile?.name,
    });

    return SocialDrop(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      dropDate: DateTime.parse(json['drop_date'] as String),
      bookData: bookData,
      isOpened: json['is_opened'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderProfile: senderProfile,
    );
  }
}
