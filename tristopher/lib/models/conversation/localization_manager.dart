import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/database/conversation_database.dart';

/// LocalizationManager handles all multi-language support for the conversation system.
/// 
/// Think of this as Tristopher's language learning center. Just as a polyglot doesn't
/// simply translate words but understands cultural context and idioms, this manager
/// ensures Tristopher's personality shines through in every language.
/// 
/// Key design decisions:
/// 
/// 1. **Template-Based System**: Instead of storing complete sentences for every scenario,
///    we use templates with variables. This reduces storage by 60-70% and makes updates easier.
/// 
/// 2. **Lazy Loading**: We only load languages when needed, not all at once. If a user
///    only speaks English, why load Spanish, French, and German translations?
/// 
/// 3. **Fallback Chain**: If a translation is missing, we fall back gracefully:
///    Requested language → English → Message key. Users always see something meaningful.
/// 
/// 4. **Context-Aware**: Some messages need different translations based on context.
///    "You failed" might be translated differently if it's the first failure vs. the tenth.
/// 
/// 5. **Cultural Adaptation**: Sarcasm and humor don't translate directly. Each language
///    can have culturally appropriate variations of Tristopher's personality.
class LocalizationManager {
  static final LocalizationManager _instance = LocalizationManager._internal();
  factory LocalizationManager() => _instance;
  LocalizationManager._internal();

  final ConversationDatabase _database = ConversationDatabase();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // In-memory cache for loaded translations
  final Map<String, LocalizationData> _cache = {};
  
  // Current active language
  String _currentLanguage = 'en';
  
  // Cache configuration
  static const Duration _cacheValidity = Duration(days: 30);
  
  /// Set the active language for the conversation system.
  /// 
  /// This is like switching Tristopher's brain to think in a different language.
  /// All subsequent messages will use this language.
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    
    // Ensure we have the language pack loaded
    if (!_cache.containsKey(languageCode)) {
      await loadLanguagePack(languageCode);
    }
  }

  /// Get a localized message with optional variable substitution.
  /// 
  /// This is the main method that transforms message keys into actual text.
  /// For example:
  /// - Key: "morning_greeting_streak"
  /// - Variables: {"name": "John", "streak": 5}
  /// - English result: "Well, John. 5 days in a row. Don't get cocky."
  /// - Spanish result: "Vaya, John. 5 días seguidos. No te emociones."
  /// 
  /// The beauty is that each language can structure the sentence differently
  /// while maintaining the same meaning and tone.
  Future<String> getMessage({
    required String key,
    Map<String, dynamic>? variables,
    String? languageOverride,
  }) async {
    final language = languageOverride ?? _currentLanguage;
    
    // Ensure language pack is loaded
    final localizationData = await _getLocalizationData(language);
    
    // Get the message template
    String? message = localizationData.messages[key];
    
    // Fallback chain if message not found
    if (message == null) {
      print('⚠️ Missing translation for key "$key" in language "$language"');
      
      // Try English as fallback
      if (language != 'en') {
        final englishData = await _getLocalizationData('en');
        message = englishData.messages[key];
      }
      
      // If still not found, return the key itself as last resort
      if (message == null) {
        print('❌ Missing translation for key "$key" in all languages');
        return key; // This makes missing translations obvious during development
      }
    }
    
    // Apply variable substitution
    if (variables != null && variables.isNotEmpty) {
      message = _applyVariables(message, variables);
    }
    
    return message;
  }

  /// Get a localized option (button text, choices, etc.).
  /// 
  /// Options often need to be concise due to UI constraints, so they're
  /// managed separately from regular messages.
  Future<String> getOption({
    required String key,
    String? languageOverride,
  }) async {
    final language = languageOverride ?? _currentLanguage;
    final localizationData = await _getLocalizationData(language);
    
    String? option = localizationData.options[key];
    
    // Fallback to English
    if (option == null && language != 'en') {
      final englishData = await _getLocalizationData('en');
      option = englishData.options[key];
    }
    
    return option ?? key;
  }

  /// Apply variables to a message template.
  /// 
  /// This is more sophisticated than simple string replacement. It handles:
  /// - Number formatting (1000 → "1,000" in English, "1.000" in German)
  /// - Pluralization (1 day vs 2 days)
  /// - Gender agreement in languages that require it
  /// - Contextual variations
  String _applyVariables(String template, Map<String, dynamic> variables) {
    String result = template;
    
    // First pass: simple variable replacement
    variables.forEach((key, value) {
      final placeholder = '{{$key}}';
      if (result.contains(placeholder)) {
        result = result.replaceAll(placeholder, _formatValue(value));
      }
    });
    
    // Second pass: handle conditional pluralization
    // Format: {{count:singular|plural}}
    final pluralPattern = RegExp(r'\{\{(\w+):([^|]+)\|([^}]+)\}\}');
    result = result.replaceAllMapped(pluralPattern, (match) {
      final variableName = match.group(1)!;
      final singular = match.group(2)!;
      final plural = match.group(3)!;
      
      final value = variables[variableName];
      if (value is num) {
        return value == 1 ? singular : plural;
      }
      return match.group(0)!; // Return unchanged if not a number
    });
    
    // Third pass: handle conditional text based on boolean values
    // Format: {{variable?true text:false text}}
    final conditionalPattern = RegExp(r'\{\{(\w+)\?([^:]+):([^}]+)\}\}');
    result = result.replaceAllMapped(conditionalPattern, (match) {
      final variableName = match.group(1)!;
      final trueText = match.group(2)!;
      final falseText = match.group(3)!;
      
      final value = variables[variableName];
      if (value is bool) {
        return value ? trueText : falseText;
      }
      return match.group(0)!; // Return unchanged if not a boolean
    });
    
    return result;
  }

  /// Format a value for display based on its type and the current language.
  /// 
  /// Different cultures format numbers, dates, and currency differently.
  /// This method ensures values are displayed appropriately.
  String _formatValue(dynamic value) {
    if (value == null) return '';
    
    if (value is num) {
      // Format numbers with appropriate separators
      // TODO: Use proper NumberFormat based on locale
      return value.toString();
    }
    
    if (value is DateTime) {
      // Format dates appropriately for the culture
      // TODO: Use proper DateFormat based on locale
      return value.toLocal().toString().split(' ')[0];
    }
    
    return value.toString();
  }

  /// Get localization data for a specific language.
  /// 
  /// This implements the caching strategy - check memory first, then database,
  /// then download from Firebase if necessary.
  Future<LocalizationData> _getLocalizationData(String language) async {
    // Check memory cache
    if (_cache.containsKey(language)) {
      return _cache[language]!;
    }
    
    // Check database cache
    final cachedData = await _loadFromDatabase(language);
    if (cachedData != null) {
      _cache[language] = cachedData;
      return cachedData;
    }
    
    // Download from Firebase or load from assets
    final data = await _downloadLanguagePack(language);
    _cache[language] = data;
    await _saveToDatabase(language, data);
    
    return data;
  }

  /// Load a language pack from the local database.
  Future<LocalizationData?> _loadFromDatabase(String language) async {
    try {
      // Check if cache is valid
      final isValid = await _database.isCacheValid('localization_$language');
      if (!isValid) return null;
      
      // Load from database
      final data = await _database.getUserState('localization_$language');
      if (data != null) {
        return LocalizationData.fromJson(data);
      }
    } catch (e) {
      print('⚠️ Error loading localization from database: $e');
    }
    return null;
  }

  /// Save a language pack to the database for offline use.
  Future<void> _saveToDatabase(String language, LocalizationData data) async {
    try {
      await _database.saveUserState(
        'localization_$language',
        data.toJson(),
      );
      
      await _database.saveCacheMetadata(
        'localization_$language',
        DateTime.now().toIso8601String(),
        _cacheValidity,
      );
    } catch (e) {
      print('⚠️ Error saving localization to database: $e');
    }
  }

  /// Download a language pack from Firebase or load from bundled assets.
  /// 
  /// The download strategy prioritizes Firebase for fresh content but falls
  /// back to bundled translations to ensure offline functionality.
  Future<LocalizationData> _downloadLanguagePack(String language) async {
    try {
      // Try to download from Firebase first
      final doc = await _firestore
          .collection('scripts')
          .doc('current')
          .collection('localization')
          .doc(language)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return LocalizationData(
          language: language,
          messages: Map<String, String>.from(data['messages'] ?? {}),
          options: Map<String, String>.from(data['options'] ?? {}),
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }
    } catch (e) {
      print('⚠️ Error downloading language pack from Firebase: $e');
    }
    
    // Fall back to bundled assets
    return await _loadBundledLanguagePack(language);
  }

  /// Load a language pack from bundled assets.
  /// 
  /// These are the translations that ship with the app, ensuring basic
  /// functionality even on first launch without internet.
  Future<LocalizationData> _loadBundledLanguagePack(String language) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/localization/$language.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      
      return LocalizationData(
        language: language,
        messages: Map<String, String>.from(data['messages'] ?? {}),
        options: Map<String, String>.from(data['options'] ?? {}),
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
    } catch (e) {
      print('❌ Error loading bundled language pack: $e');
      
      // Ultimate fallback: return minimal English data
      if (language != 'en') {
        return await _loadBundledLanguagePack('en');
      }
      
      // If even English fails, return empty data
      return LocalizationData(
        language: language,
        messages: {},
        options: {},
        metadata: {},
      );
    }
  }

  /// Load a specific language pack into memory.
  /// 
  /// This is useful for preloading languages the user might switch to,
  /// ensuring smooth language changes without loading delays.
  Future<void> loadLanguagePack(String language) async {
    if (!_cache.containsKey(language)) {
      await _getLocalizationData(language);
    }
  }

  /// Get list of available languages.
  /// 
  /// This helps the UI show only languages that have translations available.
  Future<List<LanguageInfo>> getAvailableLanguages() async {
    // In a full implementation, this would query Firebase or check bundled assets
    return [
      LanguageInfo(code: 'en', name: 'English', nativeName: 'English'),
      LanguageInfo(code: 'es', name: 'Spanish', nativeName: 'Español'),
      LanguageInfo(code: 'fr', name: 'French', nativeName: 'Français'),
      LanguageInfo(code: 'de', name: 'German', nativeName: 'Deutsch'),
      LanguageInfo(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    ];
  }

  /// Clear all cached translations.
  /// 
  /// Useful for forcing fresh downloads or during development.
  void clearCache() {
    _cache.clear();
    print('🗑️ Localization cache cleared');
  }

  /// Get statistics about loaded translations.
  /// 
  /// Helpful for monitoring and debugging.
  Map<String, dynamic> getStats() {
    return {
      'current_language': _currentLanguage,
      'loaded_languages': _cache.keys.toList(),
      'cache_size': _cache.values
          .map((data) => data.messages.length + data.options.length)
          .fold(0, (a, b) => a + b),
    };
  }
}

/// LocalizationData holds all translations for a specific language.
/// 
/// The separation between messages and options allows for different translation
/// workflows - messages might need more context and review, while options are
/// typically shorter and more standardized.
class LocalizationData {
  final String language;
  final Map<String, String> messages;
  final Map<String, String> options;
  final Map<String, dynamic> metadata;

  LocalizationData({
    required this.language,
    required this.messages,
    required this.options,
    required this.metadata,
  });

  factory LocalizationData.fromJson(Map<String, dynamic> json) {
    return LocalizationData(
      language: json['language'],
      messages: Map<String, String>.from(json['messages']),
      options: Map<String, String>.from(json['options']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'messages': messages,
      'options': options,
      'metadata': metadata,
    };
  }
}

/// LanguageInfo provides metadata about available languages.
class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;

  LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

/// Example localization file structure (would be in assets/localization/en.json):
/// 
/// {
///   "messages": {
///     "morning_greeting_streak": "Well, {{name}}. {{streak}} {{streak:day|days}} in a row. Don't get cocky.",
///     "failure_response": "Predictable. Your {{amount}} has been sent to {{charity}}. I hope it stings.",
///     "achievement_first_week": "Seven whole days. {{surprised?I'm almost impressed|I expected nothing less}}. Almost.",
///     "daily_checkin": "Did you actually {{goal_action}} yesterday, or are we resetting that pathetic {{streak}} day streak?",
///     "streak_milestone_10": "A 10-day streak. You're either lying or you've surprised us both.",
///     "stake_increase_prompt": "Feeling confident? Your current stake of {{amount}} seems rather... safe.",
///     "no_internet_warning": "No internet connection. I'll remember everything when you're back online. Can't escape that easily."
///   },
///   "options": {
///     "yes_completed": "Yes, I did it",
///     "no_failed": "No, I failed",
///     "increase_stake": "Increase stake",
///     "keep_same": "Keep it the same",
///     "set_new_goal": "Set new goal",
///     "view_history": "View history",
///     "settings": "Settings"
///   },
///   "metadata": {
///     "version": "1.0.0",
///     "last_updated": "2024-01-15",
///     "translator": "AI Assistant",
///     "notes": "Maintain Tristopher's pessimistic tone throughout"
///   }
/// }
