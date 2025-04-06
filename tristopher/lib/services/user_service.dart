import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tristopher_app/models/user_model.dart';
import 'package:tristopher_app/models/daily_log_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user data
/// Note: In a real app, this would use Firebase or another backend
/// For this demo, we'll use SharedPreferences to persist data
class UserService {
  static const String _userKey = 'user_data';
  static const String _logsKey = 'daily_logs';
  
  // Get the current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      
      if (userString != null) {
        final userData = json.decode(userString) as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
  
  // Create a new user
  Future<UserModel> createUser(String userId) async {
    try {
      final user = UserModel.empty(userId);
      await _saveUser(user);
      return user;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }
  
  // Update user data
  Future<UserModel> updateUser(UserModel user) async {
    try {
      await _saveUser(user);
      return user;
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }
  
  // Helper to save user data
  Future<void> _saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userMap = user.toMap();
      await prefs.setString(_userKey, json.encode(userMap));
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }
  
  // Log daily completion
  Future<void> logDailyCompletion(String userId, bool completed) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Create new log
      final log = DailyLogModel(
        date: today,
        completed: completed,
        stakeAmount: user.currentStakeAmount,
        stakeLost: !completed && user.currentStakeAmount != null && user.currentStakeAmount! > 0,
      );
      
      // Update user with completion status
      UserModel updatedUser = user.copyWith(
        lastCompletionStatus: completed,
        lastCheckinDate: now,
      );
      
      // Update streak count
      if (completed) {
        updatedUser = updatedUser.copyWith(streakCount: user.streakCount + 1);
        
        // Update longest streak if needed
        if (updatedUser.streakCount > user.longestStreak) {
          updatedUser = updatedUser.copyWith(longestStreak: updatedUser.streakCount);
        }
      } else {
        // Reset streak on failure
        updatedUser = updatedUser.copyWith(streakCount: 0);
      }
      
      // Save updated user
      await _saveUser(updatedUser);
      
      // Save the log
      await _saveDailyLog(log);
    } catch (e) {
      debugPrint('Error logging daily completion: $e');
      rethrow;
    }
  }
  
  // Save a daily log
  Future<void> _saveDailyLog(DailyLogModel log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing logs
      final logsString = prefs.getString(_logsKey) ?? '{}';
      final logsMap = json.decode(logsString) as Map<String, dynamic>;
      
      // Add new log
      final dateKey = log.formattedDate;
      logsMap[dateKey] = log.toMap();
      
      // Save updated logs
      await prefs.setString(_logsKey, json.encode(logsMap));
    } catch (e) {
      debugPrint('Error saving daily log: $e');
      rethrow;
    }
  }
  
  // Get completion history for current month or last N days
  Future<List<bool>> getCompletionHistory({int days = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString(_logsKey) ?? '{}';
      final logsMap = json.decode(logsString) as Map<String, dynamic>;
      
      final now = DateTime.now();
      final result = <bool>[];
      
      // Get logs for the last N days
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: days - i - 1));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        if (logsMap.containsKey(dateKey)) {
          final logData = logsMap[dateKey] as Map<String, dynamic>;
          final log = DailyLogModel.fromMap(logData);
          result.add(log.completed);
        } else {
          // No log for this day
          result.add(false);
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting completion history: $e');
      return List.filled(days, false);
    }
  }
  
  // Check for and add achievements
  Future<List<String>> checkAndUpdateAchievements() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return [];
      
      final newAchievements = <String>[];
      final achievements = user.achievements ?? {};
      
      // Check for streak achievements
      if (user.streakCount >= 7 && !achievements.containsKey('7_day_streak')) {
        achievements['7_day_streak'] = DateTime.now();
        newAchievements.add('7 Day Streak');
      }
      
      if (user.streakCount >= 30 && !achievements.containsKey('30_day_streak')) {
        achievements['30_day_streak'] = DateTime.now();
        newAchievements.add('30 Day Streak');
      }
      
      // Check for first failure
      if (user.lastCompletionStatus == false && !achievements.containsKey('first_failure')) {
        achievements['first_failure'] = DateTime.now();
        newAchievements.add('First Failure: Welcome to reality!');
      }
      
      // Check for 66-day challenge completion
      if (user.enrollmentDate != null) {
        final enrollmentDate = user.enrollmentDate!;
        final daysSinceEnrollment = DateTime.now().difference(enrollmentDate).inDays;
        
        if (daysSinceEnrollment >= 66 && !achievements.containsKey('66_day_complete')) {
          achievements['66_day_complete'] = DateTime.now();
          newAchievements.add('66 Day Challenge Completed');
        }
      }
      
      // Save user with updated achievements if there are new ones
      if (newAchievements.isNotEmpty) {
        final updatedUser = user.copyWith(achievements: achievements);
        await _saveUser(updatedUser);
      }
      
      return newAchievements;
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      return [];
    }
  }
}
