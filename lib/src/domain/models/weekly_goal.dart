class WeeklyGoal {
  final String id;
  final String userId;
  final String focusArea;
  final String intent;
  final String struggle;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;

  const WeeklyGoal({
    required this.id,
    required this.userId,
    required this.focusArea,
    this.intent = '',
    this.struggle = '',
    this.status = 'active',
    required this.startDate,
    this.endDate,
  });

  WeeklyGoal copyWith({
    String? id,
    String? userId,
    String? focusArea,
    String? intent,
    String? struggle,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      focusArea: focusArea ?? this.focusArea,
      intent: intent ?? this.intent,
      struggle: struggle ?? this.struggle,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'focusArea': focusArea,
        'intent': intent,
        'struggle': struggle,
        'status': status,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) => WeeklyGoal(
        id: json['id'] as String,
        userId: json['userId'] as String,
        focusArea: json['focusArea'] as String,
        intent: json['intent'] as String? ?? '',
        struggle: json['struggle'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
      );
}
