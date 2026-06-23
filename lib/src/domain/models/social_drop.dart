import 'growth_drop.dart';
import 'user.dart';

class SocialDrop {
  final String id;
  final String senderId;
  final String recipientId;
  final DateTime dropDate;
  final GrowthDrop? bookData;
  final bool isOpened;
  final DateTime createdAt;
  final User? senderProfile;

  const SocialDrop({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.dropDate,
    this.bookData,
    this.isOpened = false,
    required this.createdAt,
    this.senderProfile,
  });

  factory SocialDrop.fromJson(Map<String, dynamic> json, {User? senderProfile}) {
    GrowthDrop? parsedBookData;
    if (json['book_data'] != null && (json['book_data'] as Map).isNotEmpty && json['book_data']['bookTitle'] != null) {
      final bookDataJson = json['book_data'] as Map<String, dynamic>;
      parsedBookData = GrowthDrop.fromJson({
        'id': json['id'],
        'date': json['drop_date'],
        'focusArea': 'Social Drop',
        'bookTitle': bookDataJson['bookTitle'] ?? '',
        'bookAuthor': bookDataJson['bookAuthor'] ?? '',
        'whatItsAbout': bookDataJson['whatItsAbout'] ?? '',
        'lessons': bookDataJson['lessons'] ?? [],
        'summary': bookDataJson['summary'] ?? '',
        'coverUrl': bookDataJson['coverUrl'] as String?,
        'caseStudy': bookDataJson['caseStudy'] as String?,
        'actionableInsights': bookDataJson['actionableInsights'] != null
            ? (bookDataJson['actionableInsights'] as List<dynamic>).cast<String>()
            : null,
        'isRead': json['is_opened'] ?? false,
        'giftedBy': senderProfile?.name,
      });
    }

    return SocialDrop(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      dropDate: DateTime.parse(json['drop_date'] as String),
      bookData: parsedBookData,
      isOpened: json['is_opened'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderProfile: senderProfile,
    );
  }
}
