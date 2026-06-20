class GrowthDrop {
  final String id;
  final DateTime date;
  final String focusArea;
  final String bookTitle;
  final String bookAuthor;
  final String whatItsAbout;
  final List<String> lessons;
  final String summary;
  final bool isRead;
  final String? giftedBy;

  const GrowthDrop({
    required this.id,
    required this.date,
    required this.focusArea,
    required this.bookTitle,
    required this.bookAuthor,
    required this.whatItsAbout,
    required this.lessons,
    required this.summary,
    this.isRead = false,
    this.giftedBy,
  });

  GrowthDrop copyWith({bool? isRead}) => GrowthDrop(
        id: id,
        date: date,
        focusArea: focusArea,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        whatItsAbout: whatItsAbout,
        lessons: lessons,
        summary: summary,
        isRead: isRead ?? this.isRead,
        giftedBy: giftedBy,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'focusArea': focusArea,
        'bookTitle': bookTitle,
        'bookAuthor': bookAuthor,
        'whatItsAbout': whatItsAbout,
        'lessons': lessons,
        'summary': summary,
        'isRead': isRead,
        'giftedBy': giftedBy,
      };

  factory GrowthDrop.fromJson(Map<String, dynamic> json) => GrowthDrop(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        focusArea: json['focusArea'] as String,
        bookTitle: json['bookTitle'] as String,
        bookAuthor: json['bookAuthor'] as String,
        whatItsAbout: json['whatItsAbout'] as String,
        lessons: (json['lessons'] as List<dynamic>).cast<String>(),
        summary: json['summary'] as String,
        isRead: json['isRead'] as bool? ?? false,
        giftedBy: json['giftedBy'] as String?,
      );
}
