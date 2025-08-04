import 'dart:convert';
import '../models/data_action.dart';
import 'user_data_service.dart';
import '../constants/data_action_constants.dart';
import 'session_service.dart';
import 'logger_service.dart';

class DataActionProcessor {
  final UserDataService _userDataService;
  final SessionService? _sessionService;
  final LoggerService _logger = LoggerService.instance;
  
  // Event callback for UI notifications
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  DataActionProcessor(this._userDataService, {SessionService? sessionService})
      : _sessionService = sessionService;

  /// Set callback for event notifications
  void setEventCallback(Future<void> Function(String eventType, Map<String, dynamic> data) callback) {
    _onEvent = callback;
  }

  Future<void> processActions(List<DataAction> actions) async {
    if (actions.isEmpty) {
      _logger.debug('No dataActions to process', component: LogComponent.dataActionProcessor);
      return;
    }
    
    _logger.debug('Processing ${actions.length} dataAction(s): ${actions.map((a) => a.type.name).join(', ')}', 
        component: LogComponent.dataActionProcessor);
        
    for (final action in actions) {
      await _processAction(action);
    }
    
    _logger.debug('Completed processing ${actions.length} dataAction(s)', 
        component: LogComponent.dataActionProcessor);
  }

  Future<void> _processAction(DataAction action) async {
    _logger.debug('Processing action: ${action.type.name.toUpperCase()} ${action.key} = ${action.value}', 
        component: LogComponent.dataActionProcessor);
        
    switch (action.type) {
      case DataActionType.set:
        final resolvedValue = await _resolveTemplateFunction(action.value);
        await _userDataService.storeValue(action.key, resolvedValue);
        _logger.debug('Stored ${action.key} = $resolvedValue', 
            component: LogComponent.dataActionProcessor);
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
    _logger.debug('Incremented $key: $currentValue + $incrementBy = $newValue', 
        component: LogComponent.dataActionProcessor);
  }

  Future<void> _decrementValue(String key, dynamic decrementBy) async {
    final currentValue = await _userDataService.getValue<int>(key) ?? DataActionConstants.defaultNumericValue;
    final newValue = currentValue - (decrementBy as int);
    await _userDataService.storeValue(key, newValue);
    _logger.debug('Decremented $key: $currentValue - $decrementBy = $newValue', 
        component: LogComponent.dataActionProcessor);
  }

  Future<void> _resetValue(String key, dynamic resetValue) async {
    final oldValue = await _userDataService.getValue<dynamic>(key);
    await _userDataService.storeValue(key, resetValue);
    _logger.debug('Reset $key: $oldValue → $resetValue', 
        component: LogComponent.dataActionProcessor);
  }

  Future<void> _processTrigger(DataAction action) async {
    if (_onEvent != null && action.event != null) {
      _logger.debug('Triggering event: ${action.event} with data: ${action.data ?? {}}', 
          component: LogComponent.dataActionProcessor);
      try {
        await _onEvent!(action.event!, action.data ?? {});
        _logger.debug('Successfully triggered event: ${action.event}', 
            component: LogComponent.dataActionProcessor);
      } catch (e) {
        _logger.warning('Event trigger failed for ${action.event}: $e', 
            component: LogComponent.dataActionProcessor);
        // Silent error handling - events should not fail the message flow
      }
    } else {
      if (_onEvent == null) {
        _logger.debug('No event callback set - skipping trigger ${action.event}', 
            component: LogComponent.dataActionProcessor);
      } else {
        _logger.debug('No event specified in trigger action', 
            component: LogComponent.dataActionProcessor);
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
        final resolved = _formatDate(DateTime.now());
        _logger.debug('Template function TODAY_DATE → $resolved', 
            component: LogComponent.dataActionProcessor);
        return resolved;
      
      case 'NEXT_ACTIVE_DATE':
        if (_sessionService != null) {
          final resolved = await _getNextActiveDate();
          _logger.debug('Template function NEXT_ACTIVE_DATE → $resolved', 
              component: LogComponent.dataActionProcessor);
          return resolved;
        }
        final fallback = _formatDate(DateTime.now().add(const Duration(days: 1)));
        _logger.debug('Template function NEXT_ACTIVE_DATE → $fallback (fallback - no session service)', 
            component: LogComponent.dataActionProcessor);
        return fallback;
      
      case 'NEXT_ACTIVE_WEEKDAY':
        if (_sessionService != null) {
          final resolved = await _getNextActiveWeekday();
          _logger.debug('Template function NEXT_ACTIVE_WEEKDAY → $resolved', 
              component: LogComponent.dataActionProcessor);
          return resolved;
        }
        final fallback = DateTime.now().add(const Duration(days: 1)).weekday;
        _logger.debug('Template function NEXT_ACTIVE_WEEKDAY → $fallback (fallback - no session service)', 
            component: LogComponent.dataActionProcessor);
        return fallback;
      
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
    _logger.debug('NEXT_ACTIVE_DATE: Raw activeDays = $rawActiveDays', 
        component: LogComponent.dataActionProcessor);
    
    // Parse activeDays to handle both array and string formats
    final activeDays = _parseActiveDays(rawActiveDays);
    _logger.debug('NEXT_ACTIVE_DATE: Parsed activeDays = $activeDays (today is ${now.weekday})', 
        component: LogComponent.dataActionProcessor);
    
    // If no active days configured, default to tomorrow
    if (activeDays == null || activeDays.isEmpty) {
      final tomorrow = now.add(const Duration(days: 1));
      final result = _formatDate(tomorrow);
      _logger.debug('NEXT_ACTIVE_DATE: No activeDays configured, using tomorrow = $result', 
          component: LogComponent.dataActionProcessor);
      return result;
    }
    
    // Find the next day that matches an active day
    for (int i = 1; i <= 7; i++) {
      final testDate = now.add(Duration(days: i));
      final testWeekday = testDate.weekday;
      
      if (activeDays.contains(testWeekday)) {
        final result = _formatDate(testDate);
        _logger.debug('NEXT_ACTIVE_DATE: Found next active day in $i days (weekday $testWeekday) = $result', 
            component: LogComponent.dataActionProcessor);
        return result;
      }
    }
    
    // Fallback - should never reach here if activeDays is valid
    final tomorrow = now.add(const Duration(days: 1));
    final result = _formatDate(tomorrow);
    _logger.debug('NEXT_ACTIVE_DATE: Fallback to tomorrow = $result', 
        component: LogComponent.dataActionProcessor);
    return result;
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