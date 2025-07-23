import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/user_data_service.dart';

void main() {
  group('UserDataService', () {
    late UserDataService userDataService;

    setUp(() async {
      // Clear any existing preferences before each test
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
    });

    test('should store and retrieve string values', () async {
      // Arrange
      const key = StorageKeys.userName;
      const value = 'John Doe';

      // Act
      await userDataService.storeValue(key, value);
      final retrievedValue = await userDataService.getValue<String>(key);

      // Assert
      expect(retrievedValue, equals(value));
    });

    test('should store and retrieve int values', () async {
      // Arrange
      const key = 'user.age';
      const value = 25;

      // Act
      await userDataService.storeValue(key, value);
      final retrievedValue = await userDataService.getValue<int>(key);

      // Assert
      expect(retrievedValue, equals(value));
    });

    test('should store and retrieve bool values', () async {
      // Arrange
      const key = 'user.isActive';
      const value = true;

      // Act
      await userDataService.storeValue(key, value);
      final retrievedValue = await userDataService.getValue<bool>(key);

      // Assert
      expect(retrievedValue, equals(value));
    });

    test('should store and retrieve list of strings', () async {
      // Arrange
      const key = 'user.interests';
      const value = ['Flutter', 'Dart', 'Mobile Development'];

      // Act
      await userDataService.storeValue(key, value);
      final retrievedValue = await userDataService.getValue<List<String>>(key);

      // Assert
      expect(retrievedValue, equals(value));
    });

    test('should return null for non-existent keys', () async {
      // Act
      final retrievedValue = await userDataService.getValue<String>('non.existent.key');

      // Assert
      expect(retrievedValue, isNull);
    });

    test('should check if value exists', () async {
      // Arrange
      const key = StorageKeys.userName;
      const value = 'John Doe';

      // Act & Assert - before storing
      expect(await userDataService.hasValue(key), isFalse);

      // Store value
      await userDataService.storeValue(key, value);

      // Act & Assert - after storing
      expect(await userDataService.hasValue(key), isTrue);
    });

    test('should remove specific values', () async {
      // Arrange
      const key = StorageKeys.userName;
      const value = 'John Doe';
      await userDataService.storeValue(key, value);

      // Verify value exists
      expect(await userDataService.hasValue(key), isTrue);

      // Act
      await userDataService.removeValue(key);

      // Assert
      expect(await userDataService.hasValue(key), isFalse);
      expect(await userDataService.getValue<String>(key), isNull);
    });

    test('should clear all data', () async {
      // Arrange
      await userDataService.storeValue(StorageKeys.userName, 'John Doe');
      await userDataService.storeValue('user.age', 25);
      await userDataService.storeValue('user.isActive', true);

      // Verify data exists
      expect(await userDataService.hasValue(StorageKeys.userName), isTrue);
      expect(await userDataService.hasValue('user.age'), isTrue);
      expect(await userDataService.hasValue('user.isActive'), isTrue);

      // Act
      await userDataService.clearAllData();

      // Assert
      expect(await userDataService.hasValue(StorageKeys.userName), isFalse);
      expect(await userDataService.hasValue('user.age'), isFalse);
      expect(await userDataService.hasValue('user.isActive'), isFalse);
    });

    test('should get all data as map', () async {
      // Arrange
      const userData = {
        StorageKeys.userName: 'John Doe',
        'user.age': 25,
        'user.isActive': true,
      };

      for (final entry in userData.entries) {
        await userDataService.storeValue(entry.key, entry.value);
      }

      // Act
      final allData = await userDataService.getAllData();

      // Assert
      expect(allData, equals(userData));
    });

    test('should handle storing null values by removing the key', () async {
      // Arrange
      const key = StorageKeys.userName;
      await userDataService.storeValue(key, 'John Doe');
      expect(await userDataService.hasValue(key), isTrue);

      // Act
      await userDataService.storeValue(key, null);

      // Assert
      expect(await userDataService.hasValue(key), isFalse);
    });
  });
}