import 'package:intl/intl.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final DateTime createdAt;
  String? goalTitle;
  List<int>? goalDaysOfWeek;
  double? currentStakeAmount;
  String? antiCharityChoice;
  int streakCount;
  int longestStreak;
  bool? lastCompletionStatus;
  DateTime? lastCheckinDate;
  DateTime? enrollmentDate;
  Map<String, DateTime>? achievements;
  Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    required this.createdAt,
    this.goalTitle,
    this.goalDaysOfWeek,
    this.currentStakeAmount,
    this.antiCharityChoice,
    this.streakCount = 0,
    this.longestStreak = 0,
    this.lastCompletionStatus,
    this.lastCheckinDate,
    this.enrollmentDate,
    this.achievements,
    this.preferences,
  });

  // Create an empty user
  factory UserModel.empty(String uid) {
    return UserModel(
      uid: uid,
      createdAt: DateTime.now(),
      streakCount: 0,
      longestStreak: 0,
      achievements: {},
      preferences: {'notificationsEnabled': true},
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'goalTitle': goalTitle,
      'goalDaysOfWeek': goalDaysOfWeek,
      'currentStakeAmount': currentStakeAmount,
      'antiCharityChoice': antiCharityChoice,
      'streakCount': streakCount,
      'longestStreak': longestStreak,
      'lastCompletionStatus': lastCompletionStatus,
      'lastCheckinDate': lastCheckinDate?.millisecondsSinceEpoch,
      'enrollmentDate': enrollmentDate?.millisecondsSinceEpoch,
      'achievements': achievements?.map((key, value) => MapEntry(key, value.millisecondsSinceEpoch)),
      'preferences': preferences,
    };
  }

  // Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      goalTitle: map['goalTitle'],
      goalDaysOfWeek: map['goalDaysOfWeek'] != null 
          ? List<int>.from(map['goalDaysOfWeek'])
          : null,
      currentStakeAmount: map['currentStakeAmount'],
      antiCharityChoice: map['antiCharityChoice'],
      streakCount: map['streakCount'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastCompletionStatus: map['lastCompletionStatus'],
      lastCheckinDate: map['lastCheckinDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastCheckinDate'])
          : null,
      enrollmentDate: map['enrollmentDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['enrollmentDate'])
          : null,
      achievements: map['achievements'] != null 
          ? (map['achievements'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, DateTime.fromMillisecondsSinceEpoch(value)))
          : {},
      preferences: map['preferences'],
    );
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    String? goalTitle,
    List<int>? goalDaysOfWeek,
    double? currentStakeAmount,
    String? antiCharityChoice,
    int? streakCount,
    int? longestStreak,
    bool? lastCompletionStatus,
    DateTime? lastCheckinDate,
    DateTime? enrollmentDate,
    Map<String, DateTime>? achievements,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      goalTitle: goalTitle ?? this.goalTitle,
      goalDaysOfWeek: goalDaysOfWeek ?? this.goalDaysOfWeek,
      currentStakeAmount: currentStakeAmount ?? this.currentStakeAmount,
      antiCharityChoice: antiCharityChoice ?? this.antiCharityChoice,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletionStatus: lastCompletionStatus ?? this.lastCompletionStatus,
      lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      achievements: achievements ?? this.achievements,
      preferences: preferences ?? this.preferences,
    );
  }

  // Check if user has completed onboarding
  bool get hasCompletedOnboarding {
    return displayName != null && 
           goalTitle != null && 
           antiCharityChoice != null &&
           currentStakeAmount != null;
  }

  // Format stake amount as currency
  String get formattedStakeAmount {
    if (currentStakeAmount == null) return '\$0';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(currentStakeAmount);
  }

  // Check if user needs to check in today
  bool get needsDailyCheckin {
    if (lastCheckinDate == null) return true;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheck = DateTime(
      lastCheckinDate!.year, 
      lastCheckinDate!.month, 
      lastCheckinDate!.day
    );
    
    return today.isAfter(lastCheck);
  }
}
