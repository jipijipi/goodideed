import 'dart:convert';
import '../models/data_action.dart';
import 'user_data_service.dart';
import '../constants/data_action_constants.dart';
import 'session_service.dart';

class DataActionProcessor {
  final UserDataService _userDataService;
  final SessionService? _sessionService;
  
  // Event callback for UI notifications
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  DataActionProcessor(this._userDataService, {SessionService? sessionService})
      : _sessionService = sessionService;

  /// Set callback for event notifications
  void setEventCallback(Future<void> Function(String eventType, Map<String, dynamic> data) callback) {
    _onEvent = callback;
  }

  Future<void> processActions(List<DataAction> actions) async {
    for (final action in actions) {
      await _processAction(action);
    }
  }

  Future<void> _processAction(DataAction action) async {
    switch (action.type) {
      case DataActionType.set:
        final resolvedValue = await _resolveTemplateFunction(action.value);
        await _userDataService.storeValue(action.key, resolvedValue);
        break;
      case DataActionType.increment:
        await _incrementValue(action.key, action.value ?? DataActionConstants.defaultIncrementValue);
        break;
      case DataActionType.decrement:
        await _decrementValue(action.key, action.value ?? DataActionConstants.defaultDecrementValue);
        break;
      case DataActionType.reset:
        await _resetValue(action.key, action.value ?? DataActionConstants.defaultResetValue);
        break;
      case DataActionType.trigger:
        await _processTrigger(action);
        break;
    }
  }

  Future<void> _incrementValue(String key, dynamic incrementBy) async {
    final currentValue = await _userDataService.getValue<int>(key) ?? DataActionConstants.defaultNumericValue;
    final newValue = currentValue + (incrementBy as int);
    await _userDataService.storeValue(key, newValue);
  }

  Future<void> _decrementValue(String key, dynamic decrementBy) async {
    final currentValue = await _userDataService.getValue<int>(key) ?? DataActionConstants.defaultNumericValue;
    final newValue = currentValue - (decrementBy as int);
    await _userDataService.storeValue(key, newValue);
  }

  Future<void> _resetValue(String key, dynamic resetValue) async {
    await _userDataService.storeValue(key, resetValue);
  }

  Future<void> _processTrigger(DataAction action) async {
    if (_onEvent != null && action.event != null) {
      try {
        await _onEvent!(action.event!, action.data ?? {});
      } catch (e) {
        // Silent error handling - events should not fail the message flow
      }
    }
  }

  /// Resolve template functions like TODAY_DATE, NEXT_ACTIVE_DATE
  Future<dynamic> _resolveTemplateFunction(dynamic value) async {
    if (value is! String) {
      return value; // Not a string, return as-is
    }

    switch (value) {
      case 'TODAY_DATE':
        return _formatDate(DateTime.now());
      
      case 'NEXT_ACTIVE_DATE':
        if (_sessionService != null) {
          return await _getNextActiveDate();
        }
        return _formatDate(DateTime.now().add(const Duration(days: 1))); // Fallback
      
      case 'NEXT_ACTIVE_WEEKDAY':
        if (_sessionService != null) {
          return await _getNextActiveWeekday();
        }
        return DateTime.now().add(const Duration(days: 1)).weekday; // Fallback
      
      default:
        return value; // Not a template function, return as-is
    }
  }

  /// Format date as YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get the next active date based on user's active days configuration
  Future<String> _getNextActiveDate() async {
    final now = DateTime.now();
    
    // Snapshot all dependencies at once to avoid race conditions
    final rawActiveDays = await _userDataService.getValue<dynamic>('task.activeDays');
    
    // Parse activeDays to handle both array and string formats
    final activeDays = _parseActiveDays(rawActiveDays);
    
    // If no active days configured, default to tomorrow
    if (activeDays == null || activeDays.isEmpty) {
      final tomorrow = now.add(const Duration(days: 1));
      return _formatDate(tomorrow);
    }
    
    // Find the next day that matches an active day
    for (int i = 1; i <= 7; i++) {
      final testDate = now.add(Duration(days: i));
      final testWeekday = testDate.weekday;
      
      if (activeDays.contains(testWeekday)) {
        return _formatDate(testDate);
      }
    }
    
    // Fallback - should never reach here if activeDays is valid
    final tomorrow = now.add(const Duration(days: 1));
    return _formatDate(tomorrow);
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

  /// Get the next active weekday number based on user's active days configuration
  /// Derives from _getNextActiveDate() to avoid duplicate logic
  Future<int> _getNextActiveWeekday() async {
    final nextActiveDateString = await _getNextActiveDate();
    final nextActiveDate = DateTime.parse(nextActiveDateString);
    return nextActiveDate.weekday;
  }
}