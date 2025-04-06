import 'package:tristopher_app/models/user_model.dart';
import 'package:tristopher_app/services/user_service.dart';

/// Service for handling the app's onboarding flow
class OnboardingService {
  final UserService _userService;
  
  OnboardingService(this._userService);
  
  // Check if user needs onboarding
  Future<bool> needsOnboarding() async {
    final user = await _userService.getCurrentUser();
    
    // If no user, onboarding is needed
    if (user == null) return true;
    
    // If user exists but hasn't completed onboarding, it's needed
    return !user.hasCompletedOnboarding;
  }
  
  // Get the onboarding stage based on the user's current state
  Future<OnboardingStage> getCurrentOnboardingStage() async {
    final user = await _userService.getCurrentUser();
    
    if (user == null) {
      return OnboardingStage.introduction;
    }
    
    if (user.displayName == null) {
      return OnboardingStage.displayName;
    }
    
    if (user.goalTitle == null) {
      return OnboardingStage.goalTitle;
    }
    
    if (user.antiCharityChoice == null || user.currentStakeAmount == null) {
      return OnboardingStage.stake;
    }
    
    return OnboardingStage.complete;
  }
  
  // Update user's display name
  Future<UserModel> setDisplayName(String displayName) async {
    final user = await _userService.getCurrentUser();
    
    if (user == null) {
      final newUser = await _userService.createUser('local_user');
      final updatedUser = newUser.copyWith(displayName: displayName);
      return await _userService.updateUser(updatedUser);
    } else {
      final updatedUser = user.copyWith(displayName: displayName);
      return await _userService.updateUser(updatedUser);
    }
  }
  
  // Update user's goal title
  Future<UserModel> setGoalTitle(String goalTitle) async {
    final user = await _userService.getCurrentUser();
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    final updatedUser = user.copyWith(goalTitle: goalTitle);
    return await _userService.updateUser(updatedUser);
  }
  
  // Update user's goal days of week
  Future<UserModel> setGoalDaysOfWeek(List<int> daysOfWeek) async {
    final user = await _userService.getCurrentUser();
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    final updatedUser = user.copyWith(goalDaysOfWeek: daysOfWeek);
    return await _userService.updateUser(updatedUser);
  }
  
  // Update user's stake information
  Future<UserModel> setStakeInformation(double amount, String antiCharityChoice) async {
    final user = await _userService.getCurrentUser();
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    final updatedUser = user.copyWith(
      currentStakeAmount: amount,
      antiCharityChoice: antiCharityChoice,
    );
    
    return await _userService.updateUser(updatedUser);
  }
  
  // Enroll user in 66-day challenge
  Future<UserModel> enroll66DayChallenge() async {
    final user = await _userService.getCurrentUser();
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    final updatedUser = user.copyWith(
      enrollmentDate: DateTime.now(),
    );
    
    return await _userService.updateUser(updatedUser);
  }
}

/// Enum representing the stages of the onboarding process
enum OnboardingStage {
  introduction,
  displayName,
  goalTitle,
  stake,
  challenge,
  complete,
}
