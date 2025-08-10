import 'dart:convert';
import '../services/user_data_service.dart';
import '../services/logger_service.dart';

/// Utility class for calculating active dates based on user's task.activeDays configuration
/// 
/// This shared utility ensures consistent active date logic across the application,
/// particularly for DataActionProcessor and NotificationService.
class ActiveDateCalculator {
  final UserDataService _userDataService;
  final LoggerService _logger = LoggerService.instance;

  ActiveDateCalculator(this._userDataService);

  /// Get the next active date based on user's active days configuration
  /// Always excludes today and returns the first active day after today
  Future<String> getNextActiveDate() async {
    final now = DateTime.now();
    
    // Snapshot all dependencies at once to avoid race conditions
    final rawActiveDays = await _userDataService.getValue<dynamic>('task.activeDays');
    
    // Parse activeDays to handle both array and string formats
    final activeDays = _parseActiveDays(rawActiveDays);
    
    // If no active days configured, default to tomorrow
    if (activeDays == null || activeDays.isEmpty) {
      final targetDate = now.add(const Duration(days: 1));
      return _formatDate(targetDate);
    }
    
    // Find the first active day, starting from tomorrow (excluding today)
    for (int i = 1; i <= 365; i++) { // Max 1 year lookahead
      final testDate = now.add(Duration(days: i));
      final testWeekday = testDate.weekday;
      
      if (activeDays.contains(testWeekday)) {
        return _formatDate(testDate);
      }
    }
    
    // Fallback - should never reach here if activeDays is valid
    final fallbackDate = now.add(const Duration(days: 1));
    _logger.warning('No active date found, using fallback');
    return _formatDate(fallbackDate);
  }

  /// Get the first active date starting from today (inclusive) based on user's active days configuration
  Future<String> getFirstActiveDate() async {
    final now = DateTime.now();
    
    // Snapshot all dependencies at once to avoid race conditions
    final rawActiveDays = await _userDataService.getValue<dynamic>('task.activeDays');
    
    // Parse activeDays to handle both array and string formats
    final activeDays = _parseActiveDays(rawActiveDays);
    
    // If no active days configured, default to today
    if (activeDays == null || activeDays.isEmpty) {
      return _formatDate(now);
    }
    
    // Check if today is an active day first
    if (activeDays.contains(now.weekday)) {
      return _formatDate(now);
    }
    
    // Find the first active day, starting from tomorrow
    for (int i = 1; i <= 365; i++) { // Max 1 year lookahead
      final testDate = now.add(Duration(days: i));
      final testWeekday = testDate.weekday;
      
      if (activeDays.contains(testWeekday)) {
        return _formatDate(testDate);
      }
    }
    
    // Fallback - should never reach here if activeDays is valid
    _logger.warning('No first active date found, using today as fallback');
    return _formatDate(now);
  }

  /// Get the next active weekday number based on user's active days configuration
  /// Derives from getNextActiveDate() to avoid duplicate logic
  Future<int> getNextActiveWeekday() async {
    final nextActiveDateString = await getNextActiveDate();
    final nextActiveDate = DateTime.parse(nextActiveDateString);
    return nextActiveDate.weekday;
  }

  /// Parse activeDays to handle both List and JSON string formats
  List<int>? _parseActiveDays(dynamic rawActiveDays) {
    if (rawActiveDays == null) {
      return null;
    }
    
    // If it's already a list, convert to List<int>
    if (rawActiveDays is List) {
      return rawActiveDays
          .map((e) => e is int ? e : int.tryParse(e.toString()))
          .where((e) => e != null)
          .cast<int>()
          .toList();
    }
    
    // If it's a string that looks like JSON, try to parse it
    if (rawActiveDays is String) {
      final stringValue = rawActiveDays.trim();
      if (stringValue.startsWith('[') && stringValue.endsWith(']')) {
        try {
          final parsed = json.decode(stringValue);
          if (parsed is List) {
            return parsed
                .map((e) => e is int ? e : int.tryParse(e.toString()))
                .where((e) => e != null)
                .cast<int>()
                .toList();
          }
        } catch (e) {
          // JSON parsing failed, return null
          return null;
        }
      }
    }
    
    return null;
  }

  /// Format date as YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}