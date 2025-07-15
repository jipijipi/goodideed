import '../models/data_action.dart';
import 'user_data_service.dart';

class DataActionProcessor {
  final UserDataService _userDataService;

  DataActionProcessor(this._userDataService);

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
        await _incrementValue(action.key, action.value ?? 1);
        break;
      case DataActionType.decrement:
        await _decrementValue(action.key, action.value ?? 1);
        break;
      case DataActionType.reset:
        await _resetValue(action.key, action.value ?? 0);
        break;
    }
  }

  Future<void> _incrementValue(String key, dynamic incrementBy) async {
    final currentValue = await _userDataService.getValue<int>(key) ?? 0;
    final newValue = currentValue + (incrementBy as int);
    await _userDataService.storeValue(key, newValue);
  }

  Future<void> _decrementValue(String key, dynamic decrementBy) async {
    final currentValue = await _userDataService.getValue<int>(key) ?? 0;
    final newValue = currentValue - (decrementBy as int);
    await _userDataService.storeValue(key, newValue);
  }

  Future<void> _resetValue(String key, dynamic resetValue) async {
    await _userDataService.storeValue(key, resetValue);
  }
}