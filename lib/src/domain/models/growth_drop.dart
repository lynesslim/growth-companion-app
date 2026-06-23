class GrowthDrop {
  final String id;
  final DateTime date;
  final String focusArea;
  final String bookTitle;
  final String bookAuthor;
  final String whatItsAbout;
  final List<String> lessons;
  final String summary;
  final String? coverUrl;
  final bool isRead;
  final bool isSaved;
  final String? giftedBy;
  final String? caseStudy;
  final List<String>? actionableInsights;

  const GrowthDrop({
    required this.id,
    required this.date,
    required this.focusArea,
    required this.bookTitle,
    required this.bookAuthor,
    required this.whatItsAbout,
    required this.lessons,
    required this.summary,
    this.coverUrl,
    this.isRead = false,
    this.isSaved = false,
    this.giftedBy,
    this.caseStudy,
    this.actionableInsights,
  });

  GrowthDrop copyWith({
    bool? isRead,
    bool? isSaved,
    String? caseStudy,
    List<String>? actionableInsights,
  }) =>
      GrowthDrop(
        id: id,
        date: date,
        focusArea: focusArea,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        whatItsAbout: whatItsAbout,
        lessons: lessons,
        summary: summary,
        coverUrl: coverUrl,
        isRead: isRead ?? this.isRead,
        isSaved: isSaved ?? this.isSaved,
        giftedBy: giftedBy,
        caseStudy: caseStudy ?? this.caseStudy,
        actionableInsights: actionableInsights ?? this.actionableInsights,
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
        'coverUrl': coverUrl,
        'isRead': isRead,
        'isSaved': isSaved,
        'giftedBy': giftedBy,
        if (caseStudy != null) 'caseStudy': caseStudy,
        if (actionableInsights != null) 'actionableInsights': actionableInsights,
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
        coverUrl: json['coverUrl'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        isSaved: json['isSaved'] as bool? ?? false,
        giftedBy: json['giftedBy'] as String?,
        caseStudy: json['caseStudy'] as String?,
        actionableInsights: json['actionableInsights'] != null
            ? (json['actionableInsights'] as List<dynamic>).cast<String>()
            : null,
      );
}
