import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/services/user_service.dart';
import 'package:tristopher_app/providers/providers.dart';

/// Service for managing achievement logic
class AchievementService {
  final UserService _userService;
  
  AchievementService(this._userService);
  
  // Check for new achievements and return any that are earned
  Future<List<String>> checkForAchievements() async {
    return await _userService.checkAndUpdateAchievements();
  }
  
  // Get description for an achievement
  String getAchievementDescription(String achievementId) {
    switch (achievementId) {
      case '7_day_streak':
        return '7 Day Streak: Completed your goal for 7 consecutive days. Not completely awful.';
      case '30_day_streak':
        return "30 Day Streak: A month of consistency. Against all odds, you've kept at it.";
      case 'first_failure':
        return "First Failure: Welcome to reality. At least you're honest about it.";
      case '66_day_complete':
        return "66 Day Challenge Complete: You've reached the scientific threshold for habit formation. I'm... impressed?";
      default:
        return 'Achievement unlocked: $achievementId';
    }
  }
}

// Provider for the achievement service
final achievementServiceProvider = Provider<AchievementService>((ref) {
  final userService = ref.watch(userServiceProvider);
  return AchievementService(userService);
});

// Provider to trigger achievement checking
final checkAchievementsProvider = FutureProvider<List<String>>((ref) {
  final achievementService = ref.watch(achievementServiceProvider);
  return achievementService.checkForAchievements();
});
