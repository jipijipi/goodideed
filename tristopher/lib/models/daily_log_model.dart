class DailyLogModel {
  final DateTime date;
  final bool completed;
  final double? stakeAmount;
  final bool stakeLost;

  DailyLogModel({
    required this.date,
    required this.completed,
    this.stakeAmount,
    this.stakeLost = false,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'completed': completed,
      'stakeAmount': stakeAmount,
      'stakeLost': stakeLost,
    };
  }

  // Create from Map
  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      completed: map['completed'],
      stakeAmount: map['stakeAmount'],
      stakeLost: map['stakeLost'] ?? false,
    );
  }

  // Get formatted date string (YYYY-MM-DD)
  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
