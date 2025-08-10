import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/utils/active_date_calculator.dart';
import '../../lib/services/user_data_service.dart';
import '../test_helpers.dart';

void main() {
  group('ActiveDateCalculator', () {
    late UserDataService userDataService;
    late ActiveDateCalculator calculator;

    setUp(() {
      setupQuietTesting();
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      calculator = ActiveDateCalculator(userDataService);
    });

    tearDown(() async {
      await userDataService.clearAllData();
    });

    group('getNextActiveDate', () {
      test('should return tomorrow when no active days configured', () async {
        // Act
        final nextDate = await calculator.getNextActiveDate();
        
        // Assert
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final expectedDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(nextDate, expectedDate);
      });

      test('should return next active day when today is not active', () async {
        // Arrange - today is Saturday (7), set active days to Monday (1)
        await userDataService.storeValue('task.activeDays', [1]);
        
        // Act
        final nextDate = await calculator.getNextActiveDate();
        
        // Assert - should return next Monday
        expect(nextDate, isNotNull);
        final parsedDate = DateTime.parse(nextDate);
        expect(parsedDate.weekday, 1); // Monday
        expect(parsedDate.isAfter(DateTime.now()), true);
      });

      test('should return next occurrence when today is active', () async {
        // Arrange - set active days to include today
        final today = DateTime.now();
        await userDataService.storeValue('task.activeDays', [today.weekday]);
        
        // Act
        final nextDate = await calculator.getNextActiveDate();
        
        // Assert - should return next week's occurrence, not today
        final parsedDate = DateTime.parse(nextDate);
        expect(parsedDate.weekday, today.weekday);
        expect(parsedDate.isAfter(today.add(const Duration(days: 6))), true);
      });

      test('should handle JSON string format for active days', () async {
        // Arrange - set active days as JSON string
        await userDataService.storeValue('task.activeDays', '[1,3,5]');
        
        // Act
        final nextDate = await calculator.getNextActiveDate();
        
        // Assert
        expect(nextDate, isNotNull);
        final parsedDate = DateTime.parse(nextDate);
        expect([1, 3, 5].contains(parsedDate.weekday), true);
      });
    });

    group('getFirstActiveDate', () {
      test('should return today when today is active', () async {
        // Arrange - set today as active day
        final today = DateTime.now();
        await userDataService.storeValue('task.activeDays', [today.weekday]);
        
        // Act
        final firstDate = await calculator.getFirstActiveDate();
        
        // Assert
        final expectedDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        expect(firstDate, expectedDate);
      });

      test('should return next active day when today is not active', () async {
        // Arrange - set active days excluding today
        final today = DateTime.now();
        final nextWeekday = today.weekday == 7 ? 1 : today.weekday + 1;
        await userDataService.storeValue('task.activeDays', [nextWeekday]);
        
        // Act
        final firstDate = await calculator.getFirstActiveDate();
        
        // Assert
        final parsedDate = DateTime.parse(firstDate);
        expect(parsedDate.weekday, nextWeekday);
        expect(parsedDate.isAfter(today), true);
      });
    });

    group('getNextActiveWeekday', () {
      test('should return correct weekday number', () async {
        // Arrange
        await userDataService.storeValue('task.activeDays', [2]); // Tuesday
        
        // Act
        final weekday = await calculator.getNextActiveWeekday();
        
        // Assert
        expect(weekday, 2);
      });
    });

    group('edge cases', () {
      test('should handle null active days', () async {
        // Act
        final nextDate = await calculator.getNextActiveDate();
        
        // Assert - should default to tomorrow
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final expectedDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(nextDate, expectedDate);
      });

      test('should handle empty active days array', () async {
        // Arrange
        await userDataService.storeValue('task.activeDays', []);
        
        // Act
        final nextDate = await calculator.getNextActiveDate();
        
        // Assert - should default to tomorrow
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final expectedDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(nextDate, expectedDate);
      });

      test('should handle malformed JSON string', () async {
        // Arrange
        await userDataService.storeValue('task.activeDays', 'invalid-json');
        
        // Act
        final nextDate = await calculator.getNextActiveDate();
        
        // Assert - should default to tomorrow
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final expectedDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        expect(nextDate, expectedDate);
      });
    });
  });
}