import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'logger_service.dart';

class UserDataService {
  static const String _keyPrefix = AppConstants.userDataKeyPrefix;
  final logger = LoggerService.instance;

  /// Store a value with the given key
  Future<void> storeValue(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = _keyPrefix + key;

    if (value == null) {
      logger.debug('storeValue: removing key "$key"');
      await prefs.remove(prefKey);
      return;
    }

    logger.debug(
      'storeValue: key="$key", value=$value, valueType=${value.runtimeType}',
    );

    if (value is String) {
      await prefs.setString(prefKey, value);
    } else if (value is int) {
      await prefs.setInt(prefKey, value);
    } else if (value is bool) {
      await prefs.setBool(prefKey, value);
    } else if (value is List<String>) {
      await prefs.setStringList(prefKey, value);
    } else {
      // For complex types, store as JSON string
      final jsonString = json.encode(value);
      logger.debug(
        'storeValue: encoding complex type as JSON for key "$key": $jsonString',
      );
      await prefs.setString(prefKey, jsonString);
    }
  }

  /// Retrieve a value by key with optional type casting
  Future<T?> getValue<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = _keyPrefix + key;

    if (!prefs.containsKey(prefKey)) {
      logger.debug('getValue: key "$key" not found in storage');
      return null;
    }

    final value = prefs.get(prefKey);

    if (value == null) {
      logger.debug('getValue: key "$key" has null value');
      return null;
    }

    // Log the retrieval attempt
    logger.debug(
      'getValue: key="$key", value=$value, valueType=${value.runtimeType}, expectedType=$T',
    );

    // Handle exact type matches first
    if (T == String && value is String) {
      return value as T;
    } else if (T == int && value is int) {
      return value as T;
    } else if (T == bool && value is bool) {
      return value as T;
    } else if (value is List<String>) {
      return value as T;
    } else if (T == dynamic) {
      return value as T;
    }

    // Handle common type conversions with logging
    if (T == String && value is int) {
      logger.warning(
        'Auto-converting int to String for key "$key": $value -> "${value.toString()}"',
      );
      return value.toString() as T;
    } else if (T == int && value is String) {
      logger.warning(
        'Attempting String to int conversion for key "$key": "$value"',
      );
      final parsed = int.tryParse(value);
      if (parsed != null) {
        logger.warning(
          'Successfully converted String to int for key "$key": "$value" -> $parsed',
        );
        return parsed as T;
      } else {
        logger.error(
          'Failed to convert String to int for key "$key": "$value" is not a valid integer',
        );
        return null;
      }
    } else if (T == String && value is bool) {
      logger.warning(
        'Auto-converting bool to String for key "$key": $value -> "${value.toString()}"',
      );
      return value.toString() as T;
    } else if (T == bool && value is String) {
      logger.warning(
        'Attempting String to bool conversion for key "$key": "$value"',
      );
      if (value.toLowerCase() == 'true') {
        return true as T;
      } else if (value.toLowerCase() == 'false') {
        return false as T;
      } else {
        logger.error(
          'Failed to convert String to bool for key "$key": "$value" is not a valid boolean',
        );
        return null;
      }
    }

    // Try to parse as JSON for complex types
    if (value is String) {
      try {
        final decoded = json.decode(value);
        logger.debug('Successfully parsed JSON for key "$key": $decoded');
        return decoded as T;
      } catch (e) {
        logger.warning(
          'JSON parsing failed for key "$key", returning as string: $e',
        );
        // If JSON parsing fails, return the string value
        return value as T;
      }
    }

    // Final attempt - with comprehensive error logging
    try {
      logger.debug(
        'Attempting final cast for key "$key": ${value.runtimeType} -> $T',
      );
      return value as T?;
    } catch (e) {
      final contextInfo = _getStorageContextInfo(key);
      logger.error(
        'Type casting FAILED for key "$key": '
        'stored=${value.runtimeType}($value), '
        'requested=$T, '
        'context=$contextInfo, '
        'error=$e, '
        'stackTrace=${StackTrace.current}',
      );

      // Return null instead of crashing the app
      logger.warning(
        'Returning null for key "$key" due to type casting failure',
      );
      return null;
    }
  }

  /// Get context information about a storage key for better error logging
  String _getStorageContextInfo(String key) {
    if (key.startsWith('session.')) {
      return 'session_data';
    } else if (key.startsWith('user.')) {
      return 'user_data';
    } else if (key.startsWith('task.')) {
      return 'task_data';
    } else {
      return 'unknown_context';
    }
  }

  /// Check if a value exists for the given key
  Future<bool> hasValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = _keyPrefix + key;
    return prefs.containsKey(prefKey);
  }

  /// Remove a specific value by key
  Future<void> removeValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = _keyPrefix + key;
    await prefs.remove(prefKey);
  }

  /// Clear all user data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Get all stored data as a map
  Future<Map<String, dynamic>> getAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    final Map<String, dynamic> result = {};

    for (final prefKey in keys) {
      final userKey = prefKey.substring(_keyPrefix.length);
      final value = prefs.get(prefKey);

      if (value != null) {
        result[userKey] = value;
      }
    }

    return result;
  }
}
