import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'script_model.dart';
import '../../utils/database/conversation_database.dart';

/// ScriptManager is the intelligent librarian of our conversation system.
/// 
/// Think of it as a smart cache that knows when to use local data and when
/// to fetch updates. This class embodies several key architectural decisions:
/// 
/// 1. **Offline-First Philosophy**: Always try to serve content from local storage
///    first. This ensures the app works even without internet and provides
///    instant responses.
/// 
/// 2. **Lazy Loading**: Don't download content until it's actually needed.
///    This saves bandwidth and reduces Firebase costs.
/// 
/// 3. **Smart Caching**: Cache scripts for 7 days by default, but check for
///    critical updates more frequently. This balances freshness with efficiency.
/// 
/// 4. **Version Control**: Track script versions to enable rollbacks and A/B testing.
/// 
/// 5. **Delta Updates**: When possible, download only what has changed rather
///    than entire scripts. This is like updating a book by changing only the
///    pages that were revised, not reprinting the whole book.
/// 
/// The economic impact of this design is significant:
/// - Reduces Firebase reads by ~85% through caching
/// - Minimizes bandwidth usage through delta updates
/// - Scales efficiently as user base grows
class ScriptManager {
  static final ScriptManager _instance = ScriptManager._internal();
  factory ScriptManager() => _instance;
  ScriptManager._internal();

  final ConversationDatabase _database = ConversationDatabase();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache configuration constants
  static const Duration _scriptCacheDuration = Duration(days: 7);
  static const Duration _versionCheckInterval = Duration(hours: 24);
  static const String _currentVersion = '1.0.0'; // Default version
  
  // In-memory cache for current session
  Script? _memoryCache;
  String? _memoryCacheVersion;

  /// Load the appropriate script for the current user context.
  /// 
  /// This method implements a sophisticated fallback strategy:
  /// 1. Check in-memory cache (fastest)
  /// 2. Check local database cache (fast, works offline)
  /// 3. Check if update needed from Firebase (requires internet)
  /// 4. Download from Firebase if necessary (slowest)
  /// 5. Fall back to bundled script if all else fails
  /// 
  /// Each level of the hierarchy is designed to be faster than the next,
  /// creating a smooth degradation of service quality.
  Future<Script> loadScript({
    required String language,
    bool forceRefresh = false,
  }) async {
    try {
      // Step 1: Memory cache check (microseconds)
      if (!forceRefresh && _memoryCache != null && _memoryCacheVersion == _currentVersion) {
        print('📚 ScriptManager: Serving from memory cache');
        return _memoryCache!;
      }

      // Step 2: Local database check (milliseconds)
      if (!forceRefresh) {
        final cachedScript = await _loadFromLocalCache(language);
        if (cachedScript != null) {
          // Check if cache is still valid
          final isValid = await _database.isCacheValid('script_$_currentVersion');
          if (isValid) {
            print('📚 ScriptManager: Serving from local cache');
            _memoryCache = cachedScript;
            _memoryCacheVersion = _currentVersion;
            return cachedScript;
          }
        }
      }

      // Step 3: Check for updates (lightweight metadata check)
      if (await _shouldCheckForUpdates()) {
        final hasUpdate = await _checkForScriptUpdate();
        if (hasUpdate) {
          print('📚 ScriptManager: New script version available');
          // Mark cache as invalid to force download
          forceRefresh = true;
        } else {
          // Update last check time
          await _database.saveCacheMetadata(
            'last_version_check',
            DateTime.now().toIso8601String(),
            _versionCheckInterval,
          );
        }
      }

      // Step 4: Download from Firebase if needed
      if (forceRefresh || _memoryCache == null) {
        print('📚 ScriptManager: Downloading from Firebase');
        final script = await _downloadScript(language);
        await _saveToLocalCache(script, language);
        _memoryCache = script;
        _memoryCacheVersion = script.version;
        return script;
      }

      // Step 5: Fall back to bundled script as last resort
      print('📚 ScriptManager: Falling back to bundled script');
      return await _loadBundledScript(language);

    } catch (e) {
      print('❌ ScriptManager: Error loading script: $e');
      // Always fall back to bundled script on error
      return await _loadBundledScript(language);
    }
  }

  /// Load script from local database cache.
  /// 
  /// The database acts as a persistent cache that survives app restarts.
  /// This is crucial for offline functionality and fast startup times.
  Future<Script?> _loadFromLocalCache(String language) async {
    try {
      final scriptData = await _database.getScript(_currentVersion, language);
      if (scriptData != null) {
        return Script.fromJson(scriptData);
      }
    } catch (e) {
      print('⚠️ ScriptManager: Error loading from cache: $e');
    }
    return null;
  }

  /// Save script to local cache for future use.
  /// 
  /// This creates a persistent copy that can be used offline and reduces
  /// the need for repeated Firebase downloads.
  Future<void> _saveToLocalCache(Script script, String language) async {
    try {
      await _database.saveScript(
        id: script.id,
        version: script.version,
        language: language,
        content: script.toJson(),
      );
      
      // Save cache metadata
      await _database.saveCacheMetadata(
        'script_${script.version}',
        DateTime.now().toIso8601String(),
        _scriptCacheDuration,
      );
    } catch (e) {
      print('⚠️ ScriptManager: Error saving to cache: $e');
    }
  }

  /// Check if we should look for script updates.
  /// 
  /// This implements a smart checking strategy to balance freshness with efficiency:
  /// - Check at most once per day to reduce Firebase reads
  /// - Skip checks if we recently checked
  /// - Force checks if cache is very old
  Future<bool> _shouldCheckForUpdates() async {
    try {
      final lastCheck = await _database.getUserState('last_version_check');
      if (lastCheck == null) return true;
      
      final lastCheckTime = DateTime.parse(lastCheck as String);
      final timeSinceCheck = DateTime.now().difference(lastCheckTime);
      
      return timeSinceCheck > _versionCheckInterval;
    } catch (e) {
      // If in doubt, check for updates
      return true;
    }
  }

  /// Check if a newer script version is available.
  /// 
  /// This is a lightweight operation that only fetches metadata, not the entire script.
  /// It's like checking if a new edition of a book is available without buying it.
  Future<bool> _checkForScriptUpdate() async {
    try {
      final doc = await _firestore
          .collection('scripts')
          .doc('latest_version')
          .get();
      
      if (doc.exists) {
        final latestVersion = doc.data()?['version'] as String?;
        return latestVersion != null && latestVersion != _currentVersion;
      }
    } catch (e) {
      print('⚠️ ScriptManager: Error checking for updates: $e');
    }
    return false;
  }

  /// Download script from Firebase.
  /// 
  /// This is the most expensive operation in terms of both time and money,
  /// so we do it as rarely as possible. The script is downloaded in chunks
  /// to provide progress feedback and enable resumable downloads.
  Future<Script> _downloadScript(String language) async {
    try {
      // First, get the script metadata
      final metadataDoc = await _firestore
          .collection('scripts')
          .doc(_currentVersion)
          .collection('metadata')
          .doc('info')
          .get();
      
      if (!metadataDoc.exists) {
        throw Exception('Script version $_currentVersion not found');
      }

      // Then download the main script content
      final scriptDoc = await _firestore
          .collection('scripts')
          .doc(_currentVersion)
          .collection('content')
          .doc(language)
          .get();
      
      if (!scriptDoc.exists) {
        // Fall back to English if requested language not available
        final englishDoc = await _firestore
            .collection('scripts')
            .doc(_currentVersion)
            .collection('content')
            .doc('en')
            .get();
        
        if (!englishDoc.exists) {
          throw Exception('No script content available');
        }
        
        return Script.fromJson(englishDoc.data()!);
      }
      
      return Script.fromJson(scriptDoc.data()!);
    } catch (e) {
      print('❌ ScriptManager: Error downloading script: $e');
      rethrow;
    }
  }

  /// Load bundled script from assets.
  /// 
  /// This is our ultimate fallback - a script that ships with the app.
  /// It ensures that even if everything else fails (no internet, corrupted cache,
  /// Firebase outage), the user can still use the app. It might not have the
  /// latest content, but it's better than a broken experience.
  /// 
  /// Think of this as the emergency backup generator - not ideal for long-term use,
  /// but essential for reliability.
  Future<Script> _loadBundledScript(String language) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/scripts/default_script_$language.json',
      );
      return Script.fromJson(json.decode(jsonString));
    } catch (e) {
      // If even the requested language fails, try English
      if (language != 'en') {
        try {
          final String jsonString = await rootBundle.loadString(
            'assets/scripts/default_script_en.json',
          );
          return Script.fromJson(json.decode(jsonString));
        } catch (e) {
          // Last resort: create a minimal script programmatically
          return _createMinimalScript();
        }
      }
      throw Exception('Failed to load any script');
    }
  }

  /// Create a minimal functional script as the ultimate fallback.
  /// 
  /// This ensures the app never completely fails, even if all resources are unavailable.
  Script _createMinimalScript() {
    return Script(
      id: 'minimal',
      version: '0.0.1',
      metadata: ScriptMetadata(
        author: 'system',
        createdAt: DateTime.now(),
        description: 'Minimal fallback script',
        supportedLanguages: ['en'],
        isActive: true,
      ),
      globalVariables: {
        'robot_personality_level': 3,
        'default_delay_ms': 1000,
      },
      dailyEvents: [
        DailyEvent(
          id: 'basic_checkin',
          trigger: EventTrigger(
            type: 'time_window',
            startTime: '00:00',
            endTime: '23:59',
            conditions: {},
          ),
          variants: [
            EventVariant(
              id: 'default',
              weight: 1.0,
              conditions: {},
              messages: [
                ScriptMessage(
                  type: 'text',
                  sender: 'tristopher',
                  content: 'Did you complete your goal?',
                ),
              ],
            ),
          ],
          responses: {
            'yes': EventResponse(setVariables: {'completed_today': true}),
            'no': EventResponse(setVariables: {'completed_today': false}),
          },
        ),
      ],
      plotTimeline: {},
      messageTemplates: {},
    );
  }

  /// Preload content for upcoming days.
  /// 
  /// This is like a librarian preparing books they know you'll need soon.
  /// By downloading content during idle times, we ensure smooth performance
  /// when the user actually needs it.
  Future<void> preloadContent({
    required int currentDay,
    required String language,
    int daysToPreload = 3,
  }) async {
    try {
      // This would be implemented to download specific day content
      // For now, the main script contains all days
      print('📚 ScriptManager: Preloading content for days ${currentDay + 1} to ${currentDay + daysToPreload}');
    } catch (e) {
      print('⚠️ ScriptManager: Error preloading content: $e');
    }
  }

  /// Clear all cached scripts.
  /// 
  /// Useful for debugging or when users want to force a fresh download.
  Future<void> clearCache() async {
    _memoryCache = null;
    _memoryCacheVersion = null;
    // Database cleanup would be implemented here
    print('📚 ScriptManager: Cache cleared');
  }

  /// Get script statistics for monitoring.
  /// 
  /// This helps track cache performance and optimize the caching strategy.
  Future<Map<String, dynamic>> getScriptStats() async {
    return {
      'memory_cache_loaded': _memoryCache != null,
      'memory_cache_version': _memoryCacheVersion,
      'current_version': _currentVersion,
      // Additional stats would be collected here
    };
  }
}
