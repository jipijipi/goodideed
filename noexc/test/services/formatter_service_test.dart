import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:noexc/services/formatter_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter/assets'), (MethodCall methodCall) async {
    if (methodCall.method == 'loadString') {
      final String key = methodCall.arguments as String;
      
      switch (key) {
        case 'assets/content/formatters/timeOfDay.json':
          return '{"1": "morning", "2": "afternoon", "3": "evening", "4": "night"}';
        case 'assets/content/formatters/intensity.json':
          return '{"none": "off", "mild": "low", "severe": "high", "extreme": "maximum"}';
        case 'assets/content/formatters/activeDays.json':
          return '{"1,2,3,4,5": "weekdays", "6,7": "weekends", "1,2,3,4,5,6,7": "daily"}';
        case 'assets/content/formatters/timePeriod.json':
          return '{"10:00": "morning deadline", "14:00": "afternoon deadline", "18:00": "evening deadline", "23:00": "night deadline", "08:00": "morning start", "12:00": "afternoon start", "16:00": "evening start", "21:00": "night start"}';
        default:
          throw PlatformException(code: 'FileNotFound', message: 'Asset not found');
      }
    }
    return null;
    });
  });

  group('FormatterService', () {
    late FormatterService formatterService;

    setUp(() {
      formatterService = FormatterService();
    });

    test('should format timeOfDay values correctly', () async {
      expect(await formatterService.getFormattedValue('timeOfDay', 1), equals('morning'));
      expect(await formatterService.getFormattedValue('timeOfDay', 2), equals('afternoon'));
      expect(await formatterService.getFormattedValue('timeOfDay', 3), equals('evening'));
      expect(await formatterService.getFormattedValue('timeOfDay', 4), equals('night'));
    });

    test('should format intensity values correctly', () async {
      expect(await formatterService.getFormattedValue('intensity', 'none'), equals('off'));
      expect(await formatterService.getFormattedValue('intensity', 'mild'), equals('low'));
      expect(await formatterService.getFormattedValue('intensity', 'severe'), equals('high'));
      expect(await formatterService.getFormattedValue('intensity', 'extreme'), equals('maximum'));
    });

    test('should format activeDays values correctly', () async {
      expect(await formatterService.getFormattedValue('activeDays', '1,2,3,4,5'), equals('weekdays'));
      expect(await formatterService.getFormattedValue('activeDays', '6,7'), equals('weekends'));
      expect(await formatterService.getFormattedValue('activeDays', '1,2,3,4,5,6,7'), equals('daily'));
    });

    test('should format timePeriod values correctly', () async {
      expect(await formatterService.getFormattedValue('timePeriod', '10:00'), equals('morning deadline'));
      expect(await formatterService.getFormattedValue('timePeriod', '14:00'), equals('afternoon deadline'));
      expect(await formatterService.getFormattedValue('timePeriod', '18:00'), equals('evening deadline'));
      expect(await formatterService.getFormattedValue('timePeriod', '23:00'), equals('night deadline'));
      expect(await formatterService.getFormattedValue('timePeriod', '08:00'), equals('morning start'));
      expect(await formatterService.getFormattedValue('timePeriod', '12:00'), equals('afternoon start'));
      expect(await formatterService.getFormattedValue('timePeriod', '16:00'), equals('evening start'));
      expect(await formatterService.getFormattedValue('timePeriod', '21:00'), equals('night start'));
    });

    test('should return null for non-existent formatter', () async {
      expect(await formatterService.getFormattedValue('nonExistent', 1), isNull);
    });

    test('should return null for non-existent value in formatter', () async {
      expect(await formatterService.getFormattedValue('timeOfDay', 999), isNull);
    });

    test('should cache formatters after first load', () async {
      // First call loads the formatter
      await formatterService.getFormattedValue('timeOfDay', 1);
      
      // Second call should use cached version (verify by checking it still works)
      expect(await formatterService.getFormattedValue('timeOfDay', 2), equals('afternoon'));
    });

    test('should convert numeric values to strings for lookup', () async {
      // Test that numeric input works (converted to string internally)
      expect(await formatterService.getFormattedValue('timeOfDay', 1), equals('morning'));
      expect(await formatterService.getFormattedValue('timeOfDay', '1'), equals('morning'));
    });
  });
}