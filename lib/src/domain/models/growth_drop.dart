class GrowthDrop {
  final String id;
  final DateTime date;
  final String focusArea;
  final List<String> recommendedBooks;
  final String bookTitle;
  final String bookAuthor;
  final String summary;
  final String whyThisBook;
  final String whatItsAbout;
  final List<String> lessons;
  final String firstChapter;
  final String dailyAction;
  final String dailyActionDuration;

  const GrowthDrop({
    required this.id,
    required this.date,
    required this.focusArea,
    required this.recommendedBooks,
    required this.bookTitle,
    required this.bookAuthor,
    required this.summary,
    required this.whyThisBook,
    required this.whatItsAbout,
    required this.lessons,
    required this.firstChapter,
    required this.dailyAction,
    required this.dailyActionDuration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'focusArea': focusArea,
        'recommendedBooks': recommendedBooks,
        'bookTitle': bookTitle,
        'bookAuthor': bookAuthor,
        'summary': summary,
        'whyThisBook': whyThisBook,
        'whatItsAbout': whatItsAbout,
        'lessons': lessons,
        'firstChapter': firstChapter,
        'dailyAction': dailyAction,
        'dailyActionDuration': dailyActionDuration,
      };

  factory GrowthDrop.fromJson(Map<String, dynamic> json) => GrowthDrop(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        focusArea: json['focusArea'] as String,
        recommendedBooks: (json['recommendedBooks'] as List<dynamic>).cast<String>(),
        bookTitle: json['bookTitle'] as String,
        bookAuthor: json['bookAuthor'] as String,
        summary: json['summary'] as String,
        whyThisBook: json['whyThisBook'] as String,
        whatItsAbout: json['whatItsAbout'] as String,
        lessons: (json['lessons'] as List<dynamic>).cast<String>(),
        firstChapter: json['firstChapter'] as String,
        dailyAction: json['dailyAction'] as String,
        dailyActionDuration: json['dailyActionDuration'] as String,
      );
}
