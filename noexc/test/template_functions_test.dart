import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/data_action_processor.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/models/data_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Template Functions', () {
    late DataActionProcessor processor;
    late UserDataService userDataService;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      processor = DataActionProcessor(userDataService);
    });
    
    test('should resolve TODAY_DATE template function', () async {
      final actions = [
        DataAction(type: DataActionType.set, key: 'test.date', value: 'TODAY_DATE'),
      ];
      
      await processor.processActions(actions);
      
      final storedDate = await userDataService.getValue<String>('test.date');
      final today = DateTime.now();
      final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      expect(storedDate, equals(expectedDate));
    });
    
    test('should resolve NEXT_ACTIVE_DATE template function', () async {
      // Set up active days (Mon-Fri)
      await userDataService.storeValue('task.activeDays', [1, 2, 3, 4, 5]);
      
      final actions = [
        DataAction(type: DataActionType.set, key: 'test.nextDate', value: 'NEXT_ACTIVE_DATE'),
      ];
      
      await processor.processActions(actions);
      
      final storedDate = await userDataService.getValue<String>('test.nextDate');
      
      // Should be a future date (not today)
      expect(storedDate, isNotNull);
      expect(storedDate, isNot(equals('${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}')));
    });

    test('should resolve NEXT_ACTIVE_WEEKDAY template function', () async {
      // Set up active days (Mon-Fri) 
      await userDataService.storeValue('task.activeDays', [1, 2, 3, 4, 5]);
      
      final actions = [
        DataAction(type: DataActionType.set, key: 'test.nextWeekday', value: 'NEXT_ACTIVE_WEEKDAY'),
      ];
      
      await processor.processActions(actions);
      
      final storedWeekday = await userDataService.getValue<int>('test.nextWeekday');
      
      // Should be a weekday (1-7)
      expect(storedWeekday, isNotNull);
      expect(storedWeekday, greaterThanOrEqualTo(1));
      expect(storedWeekday, lessThanOrEqualTo(7));
      
      // Should be a weekday (Mon-Fri)
      expect([1, 2, 3, 4, 5], contains(storedWeekday));
    });
    
    test('should pass through non-template values unchanged', () async {
      final actions = [
        DataAction(type: DataActionType.set, key: 'test.regular', value: 'normal_value'),
        DataAction(type: DataActionType.set, key: 'test.number', value: 42),
      ];
      
      await processor.processActions(actions);
      
      final stringValue = await userDataService.getValue<String>('test.regular');
      final numberValue = await userDataService.getValue<int>('test.number');
      
      expect(stringValue, equals('normal_value'));
      expect(numberValue, equals(42));
    });
  });
}