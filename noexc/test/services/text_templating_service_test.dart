import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/text_templating_service.dart';
import 'package:noexc/services/user_data_service.dart';

void main() {
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
      await userDataService.storeValue('user.name', 'John Doe');
      const text = 'Hello, {user.name}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John Doe!'));
    });

    test('should replace multiple template variables', () async {
      // Arrange
      await userDataService.storeValue('user.name', 'John Doe');
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
      await userDataService.storeValue('user.name', 'John Doe');
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
      await userDataService.storeValue('user.name', 'John Doe');
      const text = 'Hello, {user.name|Guest}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John Doe!'));
    });

    test('should handle multiple templates with different fallback scenarios', () async {
      // Arrange
      await userDataService.storeValue('user.name', 'Alice');
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
      await userDataService.storeValue('user.name', 'Bob');
      const text = 'Hello, {user.name|Guest}! Your email is {user.email}.';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, Bob! Your email is {user.email}.'));
    });

    test('should handle pipe character in stored value', () async {
      // Arrange
      await userDataService.storeValue('user.name', 'John|Doe');
      const text = 'Hello, {user.name|Guest}!';

      // Act
      final result = await templatingService.processTemplate(text);

      // Assert
      expect(result, equals('Hello, John|Doe!'));
    });
  });
}