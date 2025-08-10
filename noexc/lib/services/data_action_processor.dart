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
  }

  /// Set callback for event notifications
  void setEventCallback(Future<void> Function(String eventType, Map<String, dynamic> data) callback) {
    _onEvent = callback;
  }

  Future<void> processActions(List<DataAction> actions) async {
    if (actions.isEmpty) return;
    
    // Summary debug log showing action types instead of individual action logging
    final actionSummary = actions.map((a) => '${a.type.name}(${a.key})').join(', ');
    _logger.debug('Processing ${actions.length} dataActions: $actionSummary', component: LogComponent.dataActionProcessor);
        
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
        _logger.warning('Trigger failed: ${action.event} - $e', 
            component: LogComponent.dataActionProcessor);
        // Silent error handling - events should not fail the message flow
      }
    }
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