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

    test('should handle compound conditions with &&', () async {
      await userDataService.storeValue('session.visitCount', 5);
      await userDataService.storeValue('session.timeOfDay', 1);

      final result = await conditionEvaluator.evaluateCompound(
        'session.visitCount > 1 && session.timeOfDay == 1',
      );
      expect(result, true);
    });

    test('should handle compound conditions with ||', () async {
      await userDataService.storeValue('session.visitCount', 1);
      await userDataService.storeValue('session.timeOfDay', 2);

      final result = await conditionEvaluator.evaluateCompound(
        'session.visitCount > 5 || session.timeOfDay == 2',
      );
      expect(result, true);
    });

    test('should handle session time-based conditions', () async {
      await userDataService.storeValue('session.timeOfDay', 1);
      await userDataService.storeValue('session.isWeekend', true);

      final morningResult = await conditionEvaluator.evaluate(
        'session.timeOfDay == 1',
      );
      final weekendResult = await conditionEvaluator.evaluate(
        'session.isWeekend == true',
      );

      expect(morningResult, true);
      expect(weekendResult, true);
    });

    test('should handle operators inside quoted strings', () async {
      // Store a value with operators in it
      await userDataService.storeValue('debug.special_string', 'test >= 5');

      // Test the condition - this should not break parsing
      final result = await conditionEvaluator.evaluate(
        'debug.special_string == \'test >= 5\'',
      );
      expect(result, true);
    });

    test('should handle edge case numeric comparisons', () async {
      // Test zero comparisons
      await userDataService.storeValue('test.zero', 0);
      expect(await conditionEvaluator.evaluate('test.zero == 0'), true);
      expect(await conditionEvaluator.evaluate('test.zero > 0'), false);
      expect(await conditionEvaluator.evaluate('test.zero < 0'), false);
      expect(await conditionEvaluator.evaluate('test.zero >= 0'), true);
      expect(await conditionEvaluator.evaluate('test.zero <= 0'), true);

      // Test negative numbers
      await userDataService.storeValue('test.negative', -5);
      expect(await conditionEvaluator.evaluate('test.negative < 0'), true);
      expect(await conditionEvaluator.evaluate('test.negative >= -5'), true);
      expect(await conditionEvaluator.evaluate('test.negative <= -5'), true);
      expect(await conditionEvaluator.evaluate('test.negative > -10'), true);
      expect(await conditionEvaluator.evaluate('test.negative < -10'), false);
    });

    test('should handle decimal/float comparisons', () async {
      await userDataService.storeValue('test.decimal', 3.14);
      expect(await conditionEvaluator.evaluate('test.decimal > 3'), true);
      expect(await conditionEvaluator.evaluate('test.decimal < 4'), true);
      expect(await conditionEvaluator.evaluate('test.decimal >= 3.14'), true);
      expect(await conditionEvaluator.evaluate('test.decimal <= 3.14'), true);
      expect(await conditionEvaluator.evaluate('test.decimal == 3.14'), true);
      expect(await conditionEvaluator.evaluate('test.decimal != 3.15'), true);
    });

    test('should handle string-to-number conversion edge cases', () async {
      // String numbers
      await userDataService.storeValue('test.string_num', '42');
      expect(await conditionEvaluator.evaluate('test.string_num > 40'), true);
      expect(await conditionEvaluator.evaluate('test.string_num < 50'), true);
      expect(await conditionEvaluator.evaluate('test.string_num == 42'), true);

      // String decimals
      await userDataService.storeValue('test.string_decimal', '3.14');
      expect(
        await conditionEvaluator.evaluate('test.string_decimal > 3'),
        true,
      );
      expect(
        await conditionEvaluator.evaluate('test.string_decimal < 4'),
        true,
      );

      // Invalid string numbers should fail numeric comparisons
      await userDataService.storeValue('test.invalid_num', 'abc');
      expect(await conditionEvaluator.evaluate('test.invalid_num > 0'), false);
      expect(await conditionEvaluator.evaluate('test.invalid_num < 0'), false);
    });

    test('should handle boundary value comparisons', () async {
      // Test with very large numbers
      await userDataService.storeValue('test.large', 999999999);
      expect(await conditionEvaluator.evaluate('test.large > 999999998'), true);
      expect(
        await conditionEvaluator.evaluate('test.large < 1000000000'),
        true,
      );

      // Test with very small numbers
      await userDataService.storeValue('test.small', 0.001);
      expect(await conditionEvaluator.evaluate('test.small > 0'), true);
      expect(await conditionEvaluator.evaluate('test.small < 0.01'), true);
    });

    test('should handle complex compound conditions', () async {
      await userDataService.storeValue('test.a', 10);
      await userDataService.storeValue('test.b', 20);
      await userDataService.storeValue('test.c', 30);

      // Multiple AND conditions
      final result1 = await conditionEvaluator.evaluateCompound(
        'test.a > 5 && test.b > 15 && test.c > 25',
      );
      expect(result1, true);

      // Mixed AND/OR (OR has lower precedence)
      final result2 = await conditionEvaluator.evaluateCompound(
        'test.a > 50 || test.b > 15 && test.c > 25',
      );
      expect(result2, true); // Should be (false || (true && true)) = true

      // All false AND
      final result3 = await conditionEvaluator.evaluateCompound(
        'test.a > 50 && test.b > 50 && test.c > 50',
      );
      expect(result3, false);

      // Mixed conditions with one true OR
      final result4 = await conditionEvaluator.evaluateCompound(
        'test.a > 50 || test.b > 50 || test.c == 30',
      );
      expect(result4, true);
    });

    test('should handle multiple operators in condition', () async {
      // Store a value with == in it
      await userDataService.storeValue('debug.complex_string', 'value == true');

      // Test the condition
      final result = await conditionEvaluator.evaluate(
        'debug.complex_string == \'value == true\'',
      );
      expect(result, true);
    });

    test('should handle numeric comparisons with different types', () async {
      // Store string number
      await userDataService.storeValue('debug.string_age', '25');

      // Test numeric comparison
      final result = await conditionEvaluator.evaluate(
        'debug.string_age >= 18',
      );
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
      final result = await conditionEvaluator.evaluate(
        'debug.level != \'expert\'',
      );
      expect(result, true);
    });

    test('should handle namespace other than user', () async {
      // Store in custom namespace
      await userDataService.storeValue('custom.test', 'value');

      // Test the condition
      final result = await conditionEvaluator.evaluate(
        'custom.test == \'value\'',
      );
      expect(result, true);
    });
  });
}
