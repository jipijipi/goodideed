# Tristopher Chatbot Interaction System - Product Requirements Document

## Executive Summary

This PRD defines the comprehensive chatbot interaction system for Tristopher, a habit-forming app with a pessimistic robot companion. The system manages scripted daily interactions that adapt based on user progress, support multiple languages, and optimize for both user engagement and cost-effectiveness.

## 1. System Architecture Overview

### 1.1 Core Components

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  Firebase Cloud  │────▶│  Script Editor  │
│  (Client)       │◀────│  Functions       │◀────│  (External)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                         │
         ▼                       ▼                         ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Local Cache    │     │  Firestore DB    │     │  JSON Scripts   │
│  (SQLite)       │     │  (NoSQL)         │     │  (Version Control)│
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### 1.2 Design Principles

1. **Offline-First**: Core interactions work without internet
2. **Script Versioning**: All scripts are versioned and cacheable
3. **Lazy Loading**: Load only necessary content
4. **Cost Optimization**: Minimize Firebase reads/writes
5. **Extensibility**: Easy to add new content types and features

## 2. Data Architecture

### 2.1 Firebase Firestore Structure

```
firestore/
├── scripts/
│   ├── {version_id}/
│   │   ├── metadata
│   │   │   ├── version: "1.0.0"
│   │   │   ├── created_at: timestamp
│   │   │   ├── is_active: boolean
│   │   │   └── supported_languages: ["en", "es", "fr"]
│   │   │
│   │   ├── daily_events/
│   │   │   └── {event_id}/
│   │   │       ├── trigger_conditions
│   │   │       ├── priority: number
│   │   │       ├── variants: []
│   │   │       └── next_events: []
│   │   │
│   │   ├── plot_events/
│   │   │   └── {day_number}/
│   │   │       ├── messages: []
│   │   │       ├── conditions: {}
│   │   │       └── branches: {}
│   │   │
│   │   └── localization/
│   │       └── {language_code}/
│   │           ├── messages: {}
│   │           └── options: {}
│   │
├── user_conversations/
│   └── {user_id}/
│       ├── current_state/
│       │   ├── script_version: string
│       │   ├── day_in_journey: number
│       │   ├── active_branches: []
│       │   ├── variables: {}
│       │   └── last_interaction: timestamp
│       │
│       └── history/
│           └── {date}/
│               └── {message_id}/
│                   ├── content: string
│                   ├── type: string
│                   ├── sender: string
│                   ├── timestamp: timestamp
│                   └── metadata: {}
│
└── script_cache/
    └── {device_id}/
        ├── cached_version: string
        ├── cached_languages: []
        └── last_sync: timestamp
```

### 2.2 Local SQLite Schema

```sql
-- Scripts table for offline access
CREATE TABLE scripts (
    id TEXT PRIMARY KEY,
    version TEXT NOT NULL,
    language TEXT NOT NULL,
    content JSON NOT NULL,
    last_updated INTEGER,
    is_active INTEGER DEFAULT 1
);

-- Conversation history
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    conversation_date TEXT,
    sender TEXT,
    type TEXT,
    content TEXT,
    metadata JSON,
    timestamp INTEGER,
    synced INTEGER DEFAULT 0
);

-- User state
CREATE TABLE user_state (
    key TEXT PRIMARY KEY,
    value JSON,
    updated_at INTEGER
);

-- Cache metadata
CREATE TABLE cache_metadata (
    key TEXT PRIMARY KEY,
    value TEXT,
    expires_at INTEGER
);
```

## 3. Script Management System

### 3.1 Script Structure (JSON Format)

```json
{
  "version": "1.0.0",
  "metadata": {
    "author": "content_team",
    "created_at": "2025-01-15T10:00:00Z",
    "description": "Main storyline with pessimistic robot personality"
  },
  "global_variables": {
    "robot_personality_level": 5,
    "default_delay_ms": 1500
  },
  "daily_events": [
    {
      "id": "morning_checkin",
      "trigger": {
        "type": "time_window",
        "start": "06:00",
        "end": "12:00",
        "conditions": {
          "user_has_active_goal": true,
          "checked_in_today": false
        }
      },
      "variants": [
        {
          "id": "variant_1",
          "weight": 0.3,
          "conditions": {
            "streak_count": { "min": 0, "max": 5 }
          },
          "messages": [
            {
              "type": "text",
              "sender": "tristopher",
              "content": "morning_checkin_low_streak_1",
              "animation": "slide_in",
              "delay": 1000
            }
          ]
        }
      ],
      "responses": {
        "yes": {
          "next_event": "checkin_success",
          "set_variables": {
            "completed_today": true
          }
        },
        "no": {
          "next_event": "checkin_failure",
          "set_variables": {
            "completed_today": false
          }
        }
      }
    }
  ],
  "plot_timeline": {
    "day_1": {
      "events": [
        {
          "id": "introduction",
          "messages": [
            {
              "type": "sequence",
              "items": [
                {
                  "type": "text",
                  "content": "intro_message_1",
                  "bubble_style": "glitch"
                },
                {
                  "type": "text",
                  "content": "intro_message_2",
                  "delay": 2000
                }
              ]
            }
          ]
        }
      ]
    }
  },
  "message_templates": {
    "morning_checkin_low_streak_1": {
      "text": "Well, well. Look who's back. Did you actually {{goal_action}} yesterday, or are we resetting that pathetic {{streak_count}}-day streak?",
      "variables": ["goal_action", "streak_count"]
    }
  }
}
```

### 3.2 Script Loading Strategy

```dart
class ScriptManager {
  // Load scripts with intelligent caching
  Future<Script> loadScript() async {
    // 1. Check local cache validity
    final cachedScript = await _localCache.getScript();
    if (cachedScript != null && !_needsUpdate(cachedScript)) {
      return cachedScript;
    }
    
    // 2. Check for updates (lightweight metadata check)
    final latestVersion = await _checkLatestVersion();
    if (cachedScript?.version == latestVersion) {
      await _updateLastChecked();
      return cachedScript!;
    }
    
    // 3. Download only changed components
    final updates = await _downloadUpdates(
      currentVersion: cachedScript?.version,
      targetVersion: latestVersion,
    );
    
    // 4. Merge and save
    final updatedScript = _mergeScripts(cachedScript, updates);
    await _localCache.saveScript(updatedScript);
    
    return updatedScript;
  }
}
```

## 4. Message Processing Engine

### 4.1 Message Types and Properties

```dart
enum MessageType {
  text,           // Simple text message
  options,        // Multiple choice
  input,          // Free text input
  sequence,       // Multiple messages in sequence
  conditional,    // Based on conditions
  achievement,    // Achievement notification
  streak,         // Streak display
  animation,      // Special animations
  delay,          // Timed delay
}

class EnhancedMessage {
  final String id;
  final MessageType type;
  final String? content;
  final MessageSender sender;
  final DateTime timestamp;
  
  // Visual properties
  final BubbleStyle? bubbleStyle;
  final AnimationType? animation;
  final int? delay;
  final TextEffect? textEffect;
  
  // Interaction properties
  final List<MessageOption>? options;
  final InputConfig? inputConfig;
  final Map<String, dynamic>? metadata;
  
  // Branching
  final String? nextEventId;
  final Map<String, dynamic>? setVariables;
  
  // Localization
  final String? contentKey; // For localized content
  final Map<String, dynamic>? variables; // For template variables
}

enum BubbleStyle {
  normal,
  glitch,      // Flickering effect
  typewriter,  // Letter by letter
  shake,       // Angry emphasis
  fade,        // Gentle appearance
  matrix,      // Digital rain effect
}

enum AnimationType {
  slideIn,
  fadeIn,
  bounce,
  glitch,
  typewriter,
}

enum TextEffect {
  none,
  bold,
  italic,
  strikethrough,
  rainbow,     // For achievements
  pulsing,     // For emphasis
}
```

### 4.2 Conversation Flow Engine

```dart
class ConversationEngine {
  final ScriptManager _scriptManager;
  final UserStateManager _userState;
  final LocalizationManager _localization;
  
  Stream<EnhancedMessage> processDaily() async* {
    final script = await _scriptManager.loadScript();
    final userState = await _userState.getCurrentState();
    
    // 1. Check plot events for current day
    final plotEvents = _getPlotEvents(
      script: script,
      dayNumber: userState.dayInJourney,
    );
    
    // 2. Check triggered daily events
    final dailyEvents = _getTriggeredDailyEvents(
      script: script,
      userState: userState,
      currentTime: DateTime.now(),
    );
    
    // 3. Merge and prioritize events
    final events = _prioritizeEvents([
      ...plotEvents,
      ...dailyEvents,
    ]);
    
    // 4. Process each event
    for (final event in events) {
      yield* _processEvent(event, userState);
    }
  }
  
  Stream<EnhancedMessage> _processEvent(
    ScriptEvent event,
    UserState userState,
  ) async* {
    // Check conditions
    if (!_evaluateConditions(event.conditions, userState)) {
      return;
    }
    
    // Select variant based on weights and conditions
    final variant = _selectVariant(event.variants, userState);
    
    // Process messages
    for (final message in variant.messages) {
      final processed = await _processMessage(message, userState);
      yield processed;
      
      // Apply delay if specified
      if (processed.delay != null) {
        await Future.delayed(
          Duration(milliseconds: processed.delay!),
        );
      }
    }
    
    // Update state
    if (variant.setVariables != null) {
      await _userState.updateVariables(variant.setVariables!);
    }
  }
  
  Future<EnhancedMessage> _processMessage(
    ScriptMessage message,
    UserState userState,
  ) async {
    // Get localized content
    final content = await _localization.getMessage(
      key: message.contentKey,
      variables: _resolveVariables(message.variables, userState),
    );
    
    return EnhancedMessage(
      id: _generateMessageId(),
      type: message.type,
      content: content,
      sender: message.sender,
      timestamp: DateTime.now(),
      bubbleStyle: message.bubbleStyle,
      animation: message.animation,
      delay: message.delay,
      textEffect: message.textEffect,
      options: message.options,
      metadata: message.metadata,
    );
  }
}
```

## 5. Localization Strategy

### 5.1 Localization Structure

```json
{
  "en": {
    "messages": {
      "morning_checkin_low_streak_1": "Well, well. Look who's back. Did you actually {{goal_action}} yesterday, or are we resetting that pathetic {{streak_count}}-day streak?",
      "achievement_first_week": "Seven whole days. I'm almost impressed. Almost."
    },
    "options": {
      "yes_completed": "Yes, I did it.",
      "no_failed": "No, I failed.",
      "increase_stake": "Yes, increase it.",
      "keep_stake": "No, keep it the same."
    },
    "templates": {
      "stake_lost": "{{amount}} transferred to {{charity}}. Predictable."
    }
  },
  "es": {
    "messages": {
      "morning_checkin_low_streak_1": "Vaya, vaya. Mira quién volvió. ¿Realmente {{goal_action}} ayer, o vamos a reiniciar esa patética racha de {{streak_count}} días?"
    }
  }
}
```

### 5.2 Localization Manager

```dart
class LocalizationManager {
  final String _currentLanguage;
  final Map<String, LocalizationData> _cache = {};
  
  Future<String> getMessage({
    required String key,
    Map<String, dynamic>? variables,
  }) async {
    final data = await _getLocalizationData(_currentLanguage);
    var message = data.messages[key] ?? key;
    
    // Replace variables
    if (variables != null) {
      variables.forEach((key, value) {
        message = message.replaceAll('{{$key}}', value.toString());
      });
    }
    
    return message;
  }
  
  Future<void> downloadLanguagePack(String language) async {
    // Download only if not cached or outdated
    if (_cache.containsKey(language)) {
      final cached = _cache[language]!;
      if (!_isOutdated(cached)) return;
    }
    
    // Download from Firebase
    final data = await _firestore
        .collection('scripts')
        .doc(_currentVersion)
        .collection('localization')
        .doc(language)
        .get();
    
    _cache[language] = LocalizationData.fromFirestore(data);
    await _saveToLocal(language, _cache[language]!);
  }
}
```

## 6. External Script Editor Integration

### 6.1 Script Editor Requirements

The script editor should be a web-based tool that:

1. **Visual Flow Editor**: Drag-and-drop interface for creating conversation flows
2. **Preview Mode**: Real-time preview of conversations
3. **Localization Management**: Side-by-side editing of multiple languages
4. **Version Control**: Git-like branching and merging
5. **Validation**: Real-time validation of script syntax and logic
6. **Export Format**: JSON with schema validation

### 6.2 Script Import/Export Flow

```dart
class ScriptImporter {
  Future<void> importScript(String jsonContent) async {
    // 1. Validate schema
    final validation = _validateSchema(jsonContent);
    if (!validation.isValid) {
      throw ScriptValidationException(validation.errors);
    }
    
    // 2. Parse and transform
    final script = Script.fromJson(json.decode(jsonContent));
    
    // 3. Create new version
    final newVersion = await _createNewVersion(script);
    
    // 4. Upload to Firebase
    await _uploadToFirebase(newVersion, script);
    
    // 5. Notify clients of update
    await _notifyClients(newVersion);
  }
  
  Future<String> exportScript(String version) async {
    final script = await _loadScriptVersion(version);
    return json.encode(script.toJson());
  }
}
```

### 6.3 Editor API Specification

```yaml
openapi: 3.0.0
info:
  title: Tristopher Script Editor API
  version: 1.0.0

paths:
  /scripts:
    get:
      summary: List all script versions
      responses:
        200:
          description: List of scripts
          
  /scripts/{version}:
    get:
      summary: Get specific script version
      parameters:
        - name: version
          in: path
          required: true
          schema:
            type: string
            
  /scripts/import:
    post:
      summary: Import new script
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Script'
              
  /scripts/{version}/validate:
    post:
      summary: Validate script
      responses:
        200:
          description: Validation result
```

## 7. Performance Optimization

### 7.1 Caching Strategy

```dart
class CacheManager {
  static const Duration scriptCacheDuration = Duration(days: 7);
  static const Duration messageCacheDuration = Duration(days: 30);
  static const int maxCachedMessages = 1000;
  
  // Intelligent preloading
  Future<void> preloadContent(UserState userState) async {
    // Preload next 3 days of plot content
    final daysToPreload = [
      userState.dayInJourney + 1,
      userState.dayInJourney + 2,
      userState.dayInJourney + 3,
    ];
    
    for (final day in daysToPreload) {
      await _preloadDay(day);
    }
    
    // Preload common daily events
    await _preloadDailyEvents([
      'morning_checkin',
      'evening_reflection',
      'streak_milestone',
    ]);
  }
  
  // Cleanup old data
  Future<void> cleanup() async {
    // Remove messages older than retention period
    await _database.delete(
      'messages',
      where: 'timestamp < ?',
      whereArgs: [
        DateTime.now()
            .subtract(messageCacheDuration)
            .millisecondsSinceEpoch,
      ],
    );
    
    // Keep only recent conversation states
    await _cleanupOldStates();
  }
}
```

### 7.2 Network Optimization

```dart
class NetworkOptimizer {
  // Batch operations to minimize Firebase calls
  Future<void> syncConversationHistory() async {
    final unsyncedMessages = await _getUnsyncedMessages();
    
    if (unsyncedMessages.isEmpty) return;
    
    // Batch upload in chunks
    const batchSize = 100;
    for (var i = 0; i < unsyncedMessages.length; i += batchSize) {
      final batch = unsyncedMessages.skip(i).take(batchSize);
      await _uploadBatch(batch);
    }
  }
  
  // Delta sync for scripts
  Future<ScriptUpdate?> checkForUpdates(String currentVersion) async {
    // Single lightweight call to check version
    final latestVersion = await _firestore
        .collection('scripts')
        .doc('latest')
        .get()
        .then((doc) => doc.data()?['version']);
    
    if (latestVersion == currentVersion) return null;
    
    // Get only the delta
    return await _firestore
        .collection('script_updates')
        .doc('$currentVersion-to-$latestVersion')
        .get()
        .then((doc) => ScriptUpdate.fromFirestore(doc));
  }
}
```

## 8. Conversation History Management

### 8.1 History Storage Strategy

```dart
class ConversationHistoryManager {
  // Store recent history locally, older history in Firebase
  static const int localHistoryDays = 30;
  static const int cloudHistoryDays = 365;
  
  Future<List<EnhancedMessage>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    // Check local first
    final localMessages = await _getLocalHistory(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
    
    // If requesting older data, fetch from cloud
    if (startDate != null && 
        startDate.isBefore(
          DateTime.now().subtract(Duration(days: localHistoryDays))
        )) {
      final cloudMessages = await _getCloudHistory(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      
      return _mergeMessages(localMessages, cloudMessages);
    }
    
    return localMessages;
  }
  
  // Compress old conversations
  Future<void> archiveOldConversations() async {
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: localHistoryDays));
    
    final oldMessages = await _getLocalHistory(
      endDate: cutoffDate,
    );
    
    if (oldMessages.isEmpty) return;
    
    // Group by day and compress
    final compressed = _compressMessages(oldMessages);
    
    // Upload to Firebase
    await _uploadCompressedHistory(compressed);
    
    // Remove from local
    await _removeLocalMessages(oldMessages);
  }
}
```

### 8.2 History UI Access

```dart
class ConversationHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation History'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: ConversationHistoryList(
        // Lazy loading with pagination
        pageSize: 50,
        // Group by date
        groupBy: (message) => DateFormat.yMd().format(message.timestamp),
        // Filter options
        filterOptions: FilterOptions(
          dateRange: true,
          messageType: true,
          searchText: true,
        ),
      ),
    );
  }
}
```

## 9. Achievement and Progress Tracking

### 9.1 Achievement System Integration

```dart
class AchievementTrigger {
  final Stream<EnhancedMessage> messageStream;
  
  void listenForAchievements() {
    // Monitor conversation events
    messageStream.listen((message) {
      if (message.metadata?['triggers_achievement'] == true) {
        _checkAchievement(message.metadata!['achievement_id']);
      }
    });
    
    // Check milestone achievements
    _checkMilestoneAchievements();
  }
  
  Future<void> _checkAchievement(String achievementId) async {
    final achievement = await _getAchievement(achievementId);
    final unlocked = await _evaluateConditions(achievement.conditions);
    
    if (unlocked) {
      // Create special achievement message
      final message = EnhancedMessage(
        type: MessageType.achievement,
        content: achievement.message,
        bubbleStyle: BubbleStyle.glitch,
        animation: AnimationType.bounce,
        textEffect: TextEffect.rainbow,
        metadata: {
          'achievement': achievement.toJson(),
          'special_effect': 'confetti',
        },
      );
      
      await _displayAchievement(message);
    }
  }
}
```

## 10. Testing and Validation

### 10.1 Script Validation System

```dart
class ScriptValidator {
  List<ValidationError> validate(Script script) {
    final errors = <ValidationError>[];
    
    // Validate structure
    errors.addAll(_validateStructure(script));
    
    // Validate all paths are reachable
    errors.addAll(_validatePaths(script));
    
    // Validate all message keys exist in localization
    errors.addAll(_validateLocalization(script));
    
    // Validate conditions syntax
    errors.addAll(_validateConditions(script));
    
    // Validate variable references
    errors.addAll(_validateVariables(script));
    
    return errors;
  }
}
```

### 10.2 Testing Framework

```dart
class ConversationTestFramework {
  Future<void> runScriptTest(ScriptTest test) async {
    // Create test user state
    final testState = UserState(
      variables: test.initialVariables,
      dayInJourney: test.startDay,
    );
    
    // Run conversation flow
    final messages = <EnhancedMessage>[];
    await for (final message in _engine.processDaily()) {
      messages.add(message);
      
      // Simulate user responses
      if (message.options != null && test.responses.containsKey(message.id)) {
        await _simulateResponse(
          message,
          test.responses[message.id]!,
        );
      }
    }
    
    // Validate outcomes
    expect(messages.length, equals(test.expectedMessageCount));
    expect(testState.variables, equals(test.expectedVariables));
  }
}
```

## 11. Migration and Versioning

### 11.1 Script Migration System

```dart
class ScriptMigration {
  Future<void> migrateToVersion(String targetVersion) async {
    final currentVersion = await _getCurrentVersion();
    final migrations = _getMigrationPath(currentVersion, targetVersion);
    
    for (final migration in migrations) {
      await _applyMigration(migration);
    }
    
    await _updateVersion(targetVersion);
  }
  
  Future<void> _applyMigration(Migration migration) async {
    // Backup current state
    await _createBackup();
    
    try {
      // Apply schema changes
      await migration.applySchemaChanges();
      
      // Migrate data
      await migration.migrateData();
      
      // Validate
      final valid = await migration.validate();
      if (!valid) throw MigrationException('Validation failed');
      
    } catch (e) {
      // Rollback on failure
      await _rollback();
      rethrow;
    }
  }
}
```

## 12. Cost Analysis and Optimization

### 12.1 Firebase Usage Optimization

```
Estimated Firebase Costs (per 10,000 active users):

Firestore:
- Script downloads: ~10,000 reads/month (cached for 7 days)
- User state: ~300,000 reads/month (daily checks)
- History sync: ~100,000 writes/month
- Total: ~$150/month

Cloud Functions:
- Script validation: ~1,000 invocations/month
- History compression: ~10,000 invocations/month
- Total: ~$20/month

Storage:
- Scripts: ~10MB total (all versions)
- Compressed history: ~1GB/month
- Total: ~$5/month

Total estimated: ~$175/month for 10,000 active users
Cost per user: ~$0.0175/month
```

### 12.2 Optimization Strategies

1. **Aggressive Caching**: 7-day script cache reduces reads by 85%
2. **Delta Sync**: Only download changed content
3. **Local-First**: 30-day local history reduces cloud reads
4. **Batch Operations**: Group Firebase operations
5. **Compression**: Compress old conversations by 70%
6. **Lazy Loading**: Load content only when needed

## 13. Security and Privacy

### 13.1 Data Security

```dart
class SecurityManager {
  // Encrypt sensitive conversation data
  Future<String> encryptMessage(String content) async {
    final key = await _getEncryptionKey();
    return _aesEncrypt(content, key);
  }
  
  // Validate script integrity
  Future<bool> validateScriptIntegrity(Script script) async {
    final signature = script.metadata['signature'];
    final publicKey = await _getPublicKey();
    
    return _verifySignature(
      data: script.toJson(),
      signature: signature,
      publicKey: publicKey,
    );
  }
}
```

### 13.2 Privacy Controls

- User can delete conversation history
- Opt-out of cloud sync
- Export personal data
- No message content in analytics

## 14. Implementation Timeline

### Phase 1: Foundation (Weeks 1-4)
- Core data models
- Basic script loading
- Local storage implementation
- Simple message flow

### Phase 2: Advanced Features (Weeks 5-8)
- Branching logic
- Variable system
- Localization
- Animation system

### Phase 3: External Tools (Weeks 9-12)
- Script editor API
- Import/export
- Validation system
- Version control

### Phase 4: Optimization (Weeks 13-16)
- Performance tuning
- Cost optimization
- Analytics integration
- Launch preparation

## 15. Success Metrics

1. **User Engagement**
   - Daily active users
   - Messages per session
   - Conversation completion rate

2. **Technical Performance**
   - Message load time < 100ms
   - Script sync time < 2s
   - Offline availability > 95%

3. **Cost Efficiency**
   - Cost per user < $0.02/month
   - Cache hit rate > 85%
   - Bandwidth usage < 1MB/user/month

4. **Content Quality**
   - Script error rate < 0.1%
   - Localization coverage > 95%
   - User satisfaction > 4.5/5

## Conclusion

This comprehensive system design addresses all requirements while optimizing for user experience, developer productivity, and cost-effectiveness. The modular architecture allows for easy extension and modification as the product evolves.