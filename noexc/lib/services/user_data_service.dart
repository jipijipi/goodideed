import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  static const String _keyPrefix = 'noexc_user_data_';

  /// Store a value with the given key
  Future<void> storeValue(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = _keyPrefix + key;

    if (value == null) {
      await prefs.remove(prefKey);
      return;
    }

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
      await prefs.setString(prefKey, jsonString);
    }
  }

  /// Retrieve a value by key with optional type casting
  Future<T?> getValue<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = _keyPrefix + key;

    if (!prefs.containsKey(prefKey)) {
      return null;
    }

    final value = prefs.get(prefKey);

    if (value == null) {
      return null;
    }

    // Handle type casting
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

    // Try to parse as JSON for complex types
    if (value is String) {
      try {
        final decoded = json.decode(value);
        return decoded as T;
      } catch (e) {
        // If JSON parsing fails, return the string value
        return value as T;
      }
    }

    return value as T?;
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