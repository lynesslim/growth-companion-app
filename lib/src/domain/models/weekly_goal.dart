class WeeklyGoal {
  final String id;
  final String userId;
  final String focusArea;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;

  const WeeklyGoal({
    required this.id,
    required this.userId,
    required this.focusArea,
    this.status = 'active',
    required this.startDate,
    this.endDate,
  });

  WeeklyGoal copyWith({
    String? id,
    String? userId,
    String? focusArea,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      focusArea: focusArea ?? this.focusArea,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'focusArea': focusArea,
        'status': status,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) => WeeklyGoal(
        id: json['id'] as String,
        userId: json['userId'] as String,
        focusArea: json['focusArea'] as String,
        status: json['status'] as String? ?? 'active',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
      );
}
