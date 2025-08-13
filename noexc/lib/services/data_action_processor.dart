import '../models/data_action.dart';
import 'user_data_service.dart';
import '../constants/data_action_constants.dart';
import 'session_service.dart';
import 'logger_service.dart';
import '../utils/active_date_calculator.dart';

class DataActionProcessor {
  final UserDataService _userDataService;
  final SessionService? _sessionService;
  final LoggerService _logger = LoggerService.instance;
  late final ActiveDateCalculator _activeDateCalculator;

  // Event callback for UI notifications
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  DataActionProcessor(this._userDataService, {SessionService? sessionService})
    : _sessionService = sessionService {
    _activeDateCalculator = ActiveDateCalculator(_userDataService);

    // Mark session service as intentionally wired for future use
    if (_sessionService != null) {
      _logger.debug(
        'SessionService attached to DataActionProcessor',
        component: LogComponent.dataActionProcessor,
      );
    }
  }

  /// Set callback for event notifications
  void setEventCallback(
    Future<void> Function(String eventType, Map<String, dynamic> data) callback,
  ) {
    _onEvent = callback;
  }

  Future<void> processActions(List<DataAction> actions) async {
    if (actions.isEmpty) return;

    // Summary debug log showing action types instead of individual action logging
    final actionSummary = actions
        .map((a) => '${a.type.name}(${a.key})')
        .join(', ');
    _logger.debug(
      'Processing ${actions.length} dataActions: $actionSummary',
      component: LogComponent.dataActionProcessor,
    );

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
        await _incrementValue(
          action.key,
          action.value ?? DataActionConstants.defaultIncrementValue,
        );
        break;
      case DataActionType.decrement:
        await _decrementValue(
          action.key,
          action.value ?? DataActionConstants.defaultDecrementValue,
        );
        break;
      case DataActionType.reset:
        await _resetValue(
          action.key,
          action.value ?? DataActionConstants.defaultResetValue,
        );
        break;
      case DataActionType.trigger:
        await _processTrigger(action);
        break;
      case DataActionType.append:
        await _appendToList(action.key, action.value);
        break;
      case DataActionType.remove:
        await _removeFromList(action.key, action.value);
        break;
    }
  }

  Future<void> _incrementValue(String key, dynamic incrementBy) async {
    final currentValue =
        await _userDataService.getValue<int>(key) ??
        DataActionConstants.defaultNumericValue;
    final newValue = currentValue + (incrementBy as int);
    await _userDataService.storeValue(key, newValue);
  }

  Future<void> _decrementValue(String key, dynamic decrementBy) async {
    final currentValue =
        await _userDataService.getValue<int>(key) ??
        DataActionConstants.defaultNumericValue;
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
        _logger.warning(
          'Trigger failed: ${action.event} - $e',
          component: LogComponent.dataActionProcessor,
        );
        // Silent error handling - events should not fail the message flow
      }
    }
  }

  Future<void> _appendToList(String key, dynamic valueToAdd) async {
    if (valueToAdd == null) return;

    // Try to get existing list, default to empty list if not found
    final existingData = await _userDataService.getValue<dynamic>(key);
    List<dynamic> currentList;

    if (existingData == null) {
      currentList = [];
    } else if (existingData is List) {
      currentList = List<dynamic>.from(existingData);
    } else if (existingData is String) {
      // Try to parse as JSON list
      try {
        final parsed = _parseJsonList(existingData);
        currentList = List<dynamic>.from(parsed);
      } catch (e) {
        _logger.warning(
          'Failed to parse existing value as list for append operation on key "$key": $existingData',
          component: LogComponent.dataActionProcessor,
        );
        return;
      }
    } else {
      _logger.warning(
        'Cannot append to non-list value for key "$key": $existingData',
        component: LogComponent.dataActionProcessor,
      );
      return;
    }

    // Add the value if it's not already in the list
    if (!currentList.contains(valueToAdd)) {
      currentList.add(valueToAdd);
      await _userDataService.storeValue(key, currentList);
      _logger.debug(
        'Appended "$valueToAdd" to list at key "$key"',
        component: LogComponent.dataActionProcessor,
      );
    } else {
      _logger.debug(
        'Value "$valueToAdd" already exists in list at key "$key"',
        component: LogComponent.dataActionProcessor,
      );
    }
  }

  Future<void> _removeFromList(String key, dynamic valueToRemove) async {
    if (valueToRemove == null) return;

    // Try to get existing list
    final existingData = await _userDataService.getValue<dynamic>(key);
    if (existingData == null) {
      _logger.debug(
        'No existing list found for key "$key" - nothing to remove',
        component: LogComponent.dataActionProcessor,
      );
      return;
    }

    List<dynamic> currentList;
    if (existingData is List) {
      currentList = List<dynamic>.from(existingData);
    } else if (existingData is String) {
      // Try to parse as JSON list
      try {
        final parsed = _parseJsonList(existingData);
        currentList = List<dynamic>.from(parsed);
      } catch (e) {
        _logger.warning(
          'Failed to parse existing value as list for remove operation on key "$key": $existingData',
          component: LogComponent.dataActionProcessor,
        );
        return;
      }
    } else {
      _logger.warning(
        'Cannot remove from non-list value for key "$key": $existingData',
        component: LogComponent.dataActionProcessor,
      );
      return;
    }

    // Remove the value if it exists
    final initialLength = currentList.length;
    currentList.removeWhere((item) => item == valueToRemove);
    
    if (currentList.length < initialLength) {
      await _userDataService.storeValue(key, currentList);
      _logger.debug(
        'Removed "$valueToRemove" from list at key "$key"',
        component: LogComponent.dataActionProcessor,
      );
    } else {
      _logger.debug(
        'Value "$valueToRemove" not found in list at key "$key"',
        component: LogComponent.dataActionProcessor,
      );
    }
  }

  /// Helper method to parse JSON list strings like "[1,2,3]"
  List<dynamic> _parseJsonList(String jsonString) {
    // Handle simple cases where it might already be a valid JSON array
    if (jsonString.startsWith('[') && jsonString.endsWith(']')) {
      try {
        final parsed = _parseJsonValue(jsonString);
        if (parsed is List) {
          return parsed;
        }
      } catch (e) {
        // Fall through to error handling
      }
    }
    
    throw FormatException('Not a valid JSON list: $jsonString');
  }

  /// Helper method to safely parse JSON values
  dynamic _parseJsonValue(String jsonString) {
    // Simple JSON parser for basic cases - could use dart:convert for full parsing
    jsonString = jsonString.trim();
    
    if (jsonString.startsWith('[') && jsonString.endsWith(']')) {
      // Parse array like "[1,2,3]"
      final content = jsonString.substring(1, jsonString.length - 1).trim();
      if (content.isEmpty) return [];
      
      return content.split(',').map((item) {
        item = item.trim();
        // Remove quotes if present
        if ((item.startsWith('"') && item.endsWith('"')) ||
            (item.startsWith("'") && item.endsWith("'"))) {
          return item.substring(1, item.length - 1);
        }
        // Try parsing as number
        final numValue = int.tryParse(item) ?? double.tryParse(item);
        return numValue ?? item;
      }).toList();
    }
    
    throw FormatException('Cannot parse JSON: $jsonString');
  }

  /// Resolve template functions like TODAY_DATE, NEXT_ACTIVE_DATE, FIRST_ACTIVE_DATE
  Future<dynamic> _resolveTemplateFunction(dynamic value) async {
    if (value is! String) {
      return value; // Not a string, return as-is
    }

    switch (value) {
      case 'TODAY_DATE':
        return _formatDate(DateTime.now());

      case 'NEXT_ACTIVE_DATE':
        return await _activeDateCalculator.getNextActiveDate();

      case 'NEXT_ACTIVE_WEEKDAY':
        return await _activeDateCalculator.getNextActiveWeekday();

      case 'FIRST_ACTIVE_DATE':
        return await _activeDateCalculator.getFirstActiveDate();

      default:
        return value; // Not a template function, return as-is
    }
  }

  /// Format date as YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
