import '../models/data_action.dart';
import 'user_data_service.dart';
import '../constants/data_action_constants.dart';

class DataActionProcessor {
  final UserDataService _userDataService;
  
  // Event callback for UI notifications
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  DataActionProcessor(this._userDataService);

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
        await _userDataService.storeValue(action.key, action.value);
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
}