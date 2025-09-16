import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/formatter_service.dart';
import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FormatterService', () {
    late FormatterService formatterService;

    setUp(() {
      setupQuietTesting();
      formatterService = FormatterService();
      formatterService.clearCache(); // Clear cache to ensure clean state
    });

    test('should format timeOfDay values correctly', () async {
      expect(
        await formatterService.getFormattedValue('timeOfDay', 1),
        equals('morning'),
      );
      expect(
        await formatterService.getFormattedValue('timeOfDay', 2),
        equals('afternoon'),
      );
      expect(
        await formatterService.getFormattedValue('timeOfDay', 3),
        equals('evening'),
      );
      expect(
        await formatterService.getFormattedValue('timeOfDay', 4),
        equals('night'),
      );
    });

    test('should format intensity values correctly', () async {
      expect(
        await formatterService.getFormattedValue('intensity', 'none'),
        equals('off'),
      );
      expect(
        await formatterService.getFormattedValue('intensity', 'mild'),
        equals('low'),
      );
      expect(
        await formatterService.getFormattedValue('intensity', 'severe'),
        equals('high'),
      );
      expect(
        await formatterService.getFormattedValue('intensity', 'extreme'),
        equals('maximum'),
      );
    });

    test('should format activeDays values correctly', () async {
      expect(
        await formatterService.getFormattedValue('activeDays', '1,2,3,4,5'),
        equals('weekdays'),
      );
      expect(
        await formatterService.getFormattedValue('activeDays', '6,7'),
        equals('weekends'),
      );
      expect(
        await formatterService.getFormattedValue('activeDays', '1,2,3,4,5,6,7'),
        equals('daily'),
      );
    });

    test('should format timePeriod values correctly', () async {
      expect(
        await formatterService.getFormattedValue('timePeriod', '10:00'),
        equals('morning deadline'),
      );
      expect(
        await formatterService.getFormattedValue('timePeriod', '14:00'),
        equals('afternoon deadline'),
      );
      expect(
        await formatterService.getFormattedValue('timePeriod', '18:00'),
        equals('evening deadline'),
      );
      expect(
        await formatterService.getFormattedValue('timePeriod', '23:00'),
        equals('night deadline'),
      );
      expect(
        await formatterService.getFormattedValue('timePeriod', '08:00'),
        equals('morning start'),
      );
      expect(
        await formatterService.getFormattedValue('timePeriod', '12:00'),
        equals('afternoon start'),
      );
      expect(
        await formatterService.getFormattedValue('timePeriod', '16:00'),
        equals('evening start'),
      );
      expect(
        await formatterService.getFormattedValue('timePeriod', '21:00'),
        equals('night start'),
      );
    });

    test('should return null for non-existent formatter', () async {
      expect(
        await formatterService.getFormattedValue('nonExistent', 1),
        isNull,
      );
    });

    test('should return null for non-existent value in formatter', () async {
      expect(
        await formatterService.getFormattedValue('timeOfDay', 999),
        isNull,
      );
    });

    test('should cache formatters after first load', () async {
      // First call loads the formatter
      await formatterService.getFormattedValue('timeOfDay', 1);

      // Second call should use cached version (verify by checking it still works)
      expect(
        await formatterService.getFormattedValue('timeOfDay', 2),
        equals('afternoon'),
      );
    });

    test('should convert numeric values to strings for lookup', () async {
      // Test that numeric input works (converted to string internally)
      expect(
        await formatterService.getFormattedValue('timeOfDay', 1),
        equals('morning'),
      );
      expect(
        await formatterService.getFormattedValue('timeOfDay', '1'),
        equals('morning'),
      );
    });

    group('Array joining with :join flag', () {
      test('should join weekday numbers to day names with proper grammar', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', [1, 2, 4]),
          equals('Monday, Tuesday and Thursday'),
        );
      });

      test('should handle string array format "[1,2,3]"', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', '[1,2,3]'),
          equals('Monday, Tuesday and Wednesday'),
        );
      });

      test('should prioritize direct mappings over array parsing', () async {
        // "6,7" has a direct mapping to "weekends" in activeDays.json, so it uses that
        expect(
          await formatterService.getFormattedValue('activeDays:join', '6,7'),
          equals('weekends'),
        );
      });

      test('should handle comma-separated format without direct mapping', () async {
        // "1,3" doesn't have a direct mapping, so it parses as array
        expect(
          await formatterService.getFormattedValue('activeDays:join', '1,3'),
          equals('Monday and Wednesday'),
        );
      });

      test('should handle single element array', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', [1]),
          equals('Monday'),
        );
      });

      test('should handle two element array', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', [1, 5]),
          equals('Monday and Friday'),
        );
      });

      test('should handle empty array', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', []),
          equals(''),
        );
      });

      test('should skip unmapped elements gracefully', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', [1, 99, 3]),
          equals('Monday and Wednesday'),
        );
      });

      test('should fall back to standard formatter for non-arrays', () async {
        // Should use existing activeDays mapping for "1,2,3,4,5"
        expect(
          await formatterService.getFormattedValue('activeDays:join', '1,2,3,4,5'),
          equals('weekdays'),
        );
      });

      test('should handle mixed number types in arrays', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', ['1', 2, '3']),
          equals('Monday, Tuesday and Wednesday'),
        );
      });

      test('should work with other formatters besides activeDays', () async {
        expect(
          await formatterService.getFormattedValue('timeOfDay:join', [1, 3]),
          equals('morning and evening'),
        );
      });

      test('should return null for non-existent formatter with join flag', () async {
        expect(
          await formatterService.getFormattedValue('nonExistent:join', [1, 2]),
          isNull,
        );
      });

      test('should handle whitespace in comma-separated strings', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:join', ' 1 , 2 , 3 '),
          equals('Monday, Tuesday and Wednesday'),
        );
      });

      test('should handle malformed JSON array gracefully', () async {
        // Should fall back to comma-separated parsing
        expect(
          await formatterService.getFormattedValue('activeDays:join', '[1,2,3'),
          equals('Tuesday and Wednesday'),  // "[1" doesn't map, "2" maps to Tuesday, "3" maps to Wednesday
        );
      });
    });

    group('Multiple flags support', () {
      test('should ignore unknown flags and process join flag', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:unknown:join', [1, 2]),
          equals('Monday and Tuesday'),
        );
      });

      test('should work without join flag (standard behavior)', () async {
        expect(
          await formatterService.getFormattedValue('activeDays:other', '1,2,3,4,5'),
          equals('weekdays'),
        );
      });
    });
  });
}
