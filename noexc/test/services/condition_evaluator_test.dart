import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/condition_evaluator.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ConditionEvaluator', () {
    late ConditionEvaluator conditionEvaluator;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      conditionEvaluator = ConditionEvaluator(userDataService);
    });

    test('should handle debug namespace variables', () async {
      // Store a value in debug namespace
      await userDataService.storeValue('debug.age', 25);
      
      // Test the condition
      final result = await conditionEvaluator.evaluate('debug.age >= 18');
      expect(result, true);
    });

    test('should handle operators inside quoted strings', () async {
      // Store a value with operators in it
      await userDataService.storeValue('debug.special_string', 'test >= 5');
      
      // Test the condition - this should not break parsing
      final result = await conditionEvaluator.evaluate('debug.special_string == \'test >= 5\'');
      expect(result, true);
    });

    test('should handle multiple operators in condition', () async {
      // Store a value with == in it
      await userDataService.storeValue('debug.complex_string', 'value == true');
      
      // Test the condition
      final result = await conditionEvaluator.evaluate('debug.complex_string == \'value == true\'');
      expect(result, true);
    });

    test('should handle numeric comparisons with different types', () async {
      // Store string number
      await userDataService.storeValue('debug.string_age', '25');
      
      // Test numeric comparison
      final result = await conditionEvaluator.evaluate('debug.string_age >= 18');
      expect(result, true);
    });

    test('should handle boolean comparisons', () async {
      // Store boolean
      await userDataService.storeValue('debug.premium', true);
      
      // Test boolean comparison
      final result = await conditionEvaluator.evaluate('debug.premium == true');
      expect(result, true);
    });

    test('should handle inequality comparisons', () async {
      // Store value
      await userDataService.storeValue('debug.level', 'intermediate');
      
      // Test inequality
      final result = await conditionEvaluator.evaluate('debug.level != \'expert\'');
      expect(result, true);
    });

    test('should handle namespace other than user', () async {
      // Store in custom namespace
      await userDataService.storeValue('custom.test', 'value');
      
      // Test the condition
      final result = await conditionEvaluator.evaluate('custom.test == \'value\'');
      expect(result, true);
    });
  });
}