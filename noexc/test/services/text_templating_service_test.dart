import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/text_templating_service.dart';
import 'package:noexc/services/user_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel('flutter/assets')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'loadString') {
      final String key = methodCall.arguments as String;
      
      switch (key) {
        case 'assets/content/formatters/timeOfDay.json':
          return '{"1": "morning", "2": "afternoon", "3": "evening", "4": "night"}';
        case 'assets/content/formatters/intensity.json':
          return '{"none": "off", "mild": "low", "severe": "high", "extreme": "maximum"}';
        case 'assets/content/formatters/activeDays.json':
          return '{"1,2,3,4,5": "weekdays", "6,7": "weekends", "1,2,3,4,5,6,7": "daily"}';
        default:
          throw PlatformException(code: 'FileNotFound', message: 'Asset not found');
      }
    }
    return null;
  });

  group('TextTemplatingService', () {
    late TextTemplatingService templatingService;
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      templatingService = TextTemplatingService(userDataService);
    });

    test('should replace single template variable', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John Doe');
      const text = 'Hello, {user.name}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John Doe!'));
    });

    test('should replace multiple template variables', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John Doe');
      await userDataService.storeValue('user.age', 25);
      const text = 'Hello, {user.name}! You are {user.age} years old.';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John Doe! You are 25 years old.'));
    });

    test('should leave template variables unchanged if no stored value exists', () async {
      // Arrange
      const text = 'Hello, {user.name}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, {user.name}!'));
    });

    test('should handle mixed existing and non-existing variables', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John Doe');
      const text = 'Hello, {user.name}! Your favorite color is {user.color}.';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John Doe! Your favorite color is {user.color}.'));
    });

    test('should handle text with no template variables', () async {
      // Arrange
      const text = 'Hello, welcome to our app!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, welcome to our app!'));
    });

    test('should handle empty text', () async {
      // Arrange
      const text = '';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals(''));
    });

    test('should handle nested object notation', () async {
      // Arrange
      await userDataService.storeValue('preferences.theme', 'dark');
      await userDataService.storeValue('settings.language', 'English');
      const text = 'Your theme is {preferences.theme} and language is {settings.language}.';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Your theme is dark and language is English.'));
    });

    test('should handle boolean values', () async {
      // Arrange
      await userDataService.storeValue('user.isActive', true);
      const text = 'User active status: {user.isActive}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('User active status: true'));
    });

    test('should handle list values by converting to string', () async {
      // Arrange
      await userDataService.storeValue('user.interests', ['Flutter', 'Dart']);
      const text = 'Your interests: {user.interests}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Your interests: [Flutter, Dart]'));
    });

    test('should handle malformed template syntax gracefully', () async {
      // Arrange
      const text = 'Hello {user.name and {incomplete';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello {user.name and {incomplete'));
    });

    test('should use fallback value when provided and stored value does not exist', () async {
      // Arrange
      const text = 'Hello, {user.name|Guest}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, Guest!'));
    });

    test('should use stored value instead of fallback when stored value exists', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John Doe');
      const text = 'Hello, {user.name|Guest}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John Doe!'));
    });

    test('should handle multiple templates with different fallback scenarios', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'Alice');
      // user.age is not stored, so should use fallback
      const text = 'Hello, {user.name|Guest}! You are {user.age|unknown} years old.';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, Alice! You are unknown years old.'));
    });

    test('should handle empty fallback value', () async {
      // Arrange
      const text = 'Hello, {user.name|}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, !'));
    });

    test('should handle fallback with special characters', () async {
      // Arrange
      const text = 'Status: {user.status|Not Available - Please Try Later}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Status: Not Available - Please Try Later'));
    });

    test('should handle nested fallback syntax gracefully', () async {
      // Arrange
      const text = 'Hello, {user.name|{default.name|Guest}}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, {default.name|Guest}!'));
    });

    test('should handle template without fallback alongside template with fallback', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'Bob');
      const text = 'Hello, {user.name|Guest}! Your email is {user.email}.';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, Bob! Your email is {user.email}.'));
    });

    test('should handle pipe character in stored value', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John|Doe');
      const text = 'Hello, {user.name|Guest}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John|Doe!'));
    });

    test('should handle task current date and status templates', () async {
      // Arrange
      await userDataService.storeValue('task.currentDate', '2024-07-18');
      await userDataService.storeValue('task.currentStatus', 'pending');
      const text = 'Today ({task.currentDate}), your task status is: {task.currentStatus}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Today (2024-07-18), your task status is: pending'));
    });

    test('should handle task templates with fallbacks', () async {
      // Arrange - don't set any task data
      const text = 'Date: {task.currentDate|unknown}, Status: {task.currentStatus|none}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Date: unknown, Status: none'));
    });

    test('should handle previous day task templates', () async {
      // Arrange
      await userDataService.storeValue('task.previousDate', '2024-07-17');
      await userDataService.storeValue('task.previousStatus', 'pending');
      await userDataService.storeValue('task.previousTask', 'Morning run');
      const text = 'Yesterday ({task.previousDate}), your task "{task.previousTask}" is {task.previousStatus}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Yesterday (2024-07-17), your task "Morning run" is pending'));
    });

    test('should handle previous day templates with fallbacks', () async {
      // Arrange - don't set any previous day data
      const text = 'Previous: {task.previousDate|none}, Status: {task.previousStatus|no previous task}, Task: {task.previousTask|nothing}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Previous: none, Status: no previous task, Task: nothing'));
    });

    test('should handle mixed current and previous day templates', () async {
      // Arrange
      await userDataService.storeValue('task.currentDate', '2024-07-18');
      await userDataService.storeValue('task.currentStatus', 'pending');
      await userDataService.storeValue('task.previousDate', '2024-07-17');
      await userDataService.storeValue('task.previousStatus', 'completed');
      await userDataService.storeValue('task.previousTask', 'Read book');
      const text = 'Today ({task.currentDate}): {task.currentStatus}. Yesterday ({task.previousDate}): {task.previousTask} was {task.previousStatus}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Today (2024-07-18): pending. Yesterday (2024-07-17): Read book was completed'));
    });

    test('should handle previous day status values correctly', () async {
      // Test all possible status values
      const testCases = [
        {'status': 'pending', 'expected': 'pending'},
        {'status': 'completed', 'expected': 'completed'},
        {'status': 'failed', 'expected': 'failed'},
      ];

      for (final testCase in testCases) {
        // Arrange
        await userDataService.storeValue('task.previousStatus', testCase['status']);
        const text = 'Previous task is {task.previousStatus}';

        // Act
        final result = await templatingService.processTemplate(text);

        // Assert
        expect(result, equals('Previous task is ${testCase['expected']}'));
      }
    });

    // New formatter tests
    test('should format values using timeOfDay formatter', () async {
      // Arrange
      await userDataService.storeValue('task.deadlineTime', 1);
      const text = 'See you by {task.deadlineTime:timeOfDay}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('See you by morning'));
    });

    test('should format values using intensity formatter', () async {
      // Arrange
      await userDataService.storeValue('reminders.intensity', 'severe');
      const text = 'Notification level: {reminders.intensity:intensity}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Notification level: high'));
    });

    test('should format values using activeDays formatter', () async {
      // Arrange
      await userDataService.storeValue('task.activeDays', '1,2,3,4,5');
      const text = 'Active on: {task.activeDays:activeDays}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Active on: weekdays'));
    });

    test('should fall back to raw value when formatter not found', () async {
      // Arrange
      await userDataService.storeValue('task.deadlineTime', 1);
      const text = 'See you by {task.deadlineTime:nonExistentFormatter}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('See you by 1'));
    });

    test('should fall back to raw value when value not found in formatter', () async {
      // Arrange
      await userDataService.storeValue('task.deadlineTime', 999);
      const text = 'See you by {task.deadlineTime:timeOfDay}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('See you by 999'));
    });

    test('should combine formatter with fallback syntax', () async {
      // Arrange - don't store any value
      const text = 'See you by {task.deadlineTime:timeOfDay|your deadline}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('See you by your deadline'));
    });

    test('should use formatted value over fallback when value exists', () async {
      // Arrange
      await userDataService.storeValue('task.deadlineTime', 2);
      const text = 'See you by {task.deadlineTime:timeOfDay|your deadline}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('See you by afternoon'));
    });

    test('should handle multiple formatters in same text', () async {
      // Arrange
      await userDataService.storeValue('task.deadlineTime', 3);
      await userDataService.storeValue('reminders.intensity', 'mild');
      const text = 'Reminder at {task.deadlineTime:timeOfDay} with {reminders.intensity:intensity} intensity';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Reminder at evening with low intensity'));
    });

    test('should handle mixed formatted and non-formatted templates', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'Alice');
      await userDataService.storeValue('task.deadlineTime', 4);
      const text = 'Hello {user.name}, see you by {task.deadlineTime:timeOfDay}';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello Alice, see you by night'));
    });
  });
}