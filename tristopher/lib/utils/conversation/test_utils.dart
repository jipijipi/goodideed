import 'package:tristopher_app/models/conversation/enhanced_message_model.dart';
import 'package:tristopher_app/models/conversation/script_model.dart';
import 'package:tristopher_app/utils/database/conversation_database.dart';
import 'dart:convert';

/// Testing utilities for the conversation system.
/// 
/// This class provides helper methods to simulate different scenarios
/// and test the conversation system during development.
class ConversationTestUtils {
  static final ConversationDatabase _database = ConversationDatabase();

  /// Set up a test user with specific state.
  static Future<void> setupTestUser({
    int dayInJourney = 1,
    int streakCount = 0,
    String goalAction = 'exercise',
    double stakeAmount = 10.0,
    String antiCharity = 'Political Campaign X',
    bool hasActiveGoal = true,
    bool checkedInToday = false,
    Map<String, dynamic>? additionalVariables,
  }) async {
    final variables = {
      'streak_count': streakCount,
      'goal_action': goalAction,
      'stake_amount': stakeAmount,
      'anti_charity': antiCharity,
      'has_active_goal': hasActiveGoal,
      'checked_in_today': checkedInToday,
      'total_completions': streakCount,
      'total_failures': 0,
      'longest_streak': streakCount,
      ...?additionalVariables,
    };

    await _database.saveUserState('conversation_state', {
      'script_version': '1.0.0',
      'day_in_journey': dayInJourney,
      'active_branches': [],
      'variables': variables,
      'last_interaction': DateTime.now().toIso8601String(),
    });
  }

  /// Create test messages for UI testing.
  static List<EnhancedMessageModel> createTestMessages() {
    return [
      EnhancedMessageModel.tristopherText(
        "Oh, you're back. Ready for another day of disappointment?",
        style: BubbleStyle.normal,
      ),
      EnhancedMessageModel(
        id: '1',
        type: MessageType.text,
        content: "Yes, I'm ready!",
        sender: MessageSender.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      EnhancedMessageModel.tristopherText(
        "Your enthusiasm is adorable. And misguided.",
        style: BubbleStyle.shake,
        delayMs: 1000,
      ),
      EnhancedMessageModel.withOptions(
        "Did you actually exercise yesterday?",
        [
          MessageOption(
            id: 'yes',
            text: 'Yes, I did it',
            nextEventId: 'checkin_success',
          ),
          MessageOption(
            id: 'no',
            text: 'No, I failed',
            nextEventId: 'checkin_failure',
          ),
        ],
      ),
      EnhancedMessageModel.achievement(
        'First Week Complete! 🎯',
        achievementData: {
          'id': 'week_1',
          'points': 100,
          'description': 'Completed 7 days in a row',
        },
      ),
      EnhancedMessageModel(
        id: '5',
        type: MessageType.streak,
        content: '🔥 Current streak: 7 days',
        sender: MessageSender.system,
        timestamp: DateTime.now(),
        animation: AnimationType.bounce,
        textEffect: TextEffect.pulsing,
      ),
    ];
  }

  /// Simulate different conversation scenarios.
  static class Scenarios {
    /// First time user experience.
    static Future<void> firstTimeUser() async {
      await setupTestUser(
        dayInJourney: 1,
        streakCount: 0,
        hasActiveGoal: false,
        checkedInToday: false,
      );
    }

    /// User with a good streak.
    static Future<void> successfulUser() async {
      await setupTestUser(
        dayInJourney: 15,
        streakCount: 14,
        hasActiveGoal: true,
        additionalVariables: {
          'recent_success_rate': 0.93,
          'last_failure_day': 3,
        },
      );
    }

    /// User who just failed.
    static Future<void> failureScenario() async {
      await setupTestUser(
        dayInJourney: 10,
        streakCount: 0,
        hasActiveGoal: true,
        additionalVariables: {
          'previous_streak': 8,
          'total_failures': 2,
          'total_stake_lost': 20.0,
        },
      );
    }

    /// User at a milestone.
    static Future<void> milestoneScenario() async {
      await setupTestUser(
        dayInJourney: 21,
        streakCount: 21,
        hasActiveGoal: true,
        additionalVariables: {
          'unlocked_week_achievement': true,
          'approaching_milestone': true,
        },
      );
    }

    /// Weekend scenario.
    static Future<void> weekendScenario() async {
      final now = DateTime.now();
      final isWeekend = now.weekday == DateTime.saturday || 
                       now.weekday == DateTime.sunday;
      
      await setupTestUser(
        dayInJourney: 12,
        streakCount: 5,
        hasActiveGoal: true,
        additionalVariables: {
          'is_weekend': isWeekend,
          'weekend_failure_rate': 0.4,
        },
      );
    }
  }

  /// Create a minimal test script for quick testing.
  static Script createTestScript() {
    return Script(
      id: 'test_script',
      version: '1.0.0',
      metadata: ScriptMetadata(
        author: 'test',
        createdAt: DateTime.now(),
        description: 'Test script for development',
        supportedLanguages: ['en'],
        isActive: true,
      ),
      globalVariables: {
        'robot_personality_level': 5,
        'default_delay_ms': 500, // Faster for testing
      },
      dailyEvents: [
        DailyEvent(
          id: 'test_checkin',
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
                  content: 'Test mode active. Did you complete your goal?',
                  properties: {
                    'bubbleStyle': 'glitch',
                    'animation': 'glitch',
                  },
                ),
                ScriptMessage(
                  type: 'options',
                  sender: 'tristopher',
                  content: 'Well?',
                  options: [
                    {'id': 'yes', 'text': 'Yes'},
                    {'id': 'no', 'text': 'No'},
                  ],
                ),
              ],
            ),
          ],
          responses: {
            'yes': EventResponse(
              setVariables: {'completed_today': true},
            ),
            'no': EventResponse(
              setVariables: {'completed_today': false},
            ),
          },
        ),
      ],
      plotTimeline: {},
      messageTemplates: {},
    );
  }

  /// Log current conversation state for debugging.
  static Future<void> logConversationState() async {
    print('=== Conversation State Debug ===');
    
    // Get user state
    final userState = await _database.getUserState('conversation_state');
    if (userState != null) {
      print('User State:');
      print(const JsonEncoder.withIndent('  ').convert(userState));
    } else {
      print('No user state found');
    }
    
    // Get recent messages
    final messages = await _database.getMessages(limit: 10);
    print('\nRecent Messages (${messages.length}):');
    for (final msg in messages) {
      print('  ${msg['sender']}: ${msg['content']}');
    }
    
    // Check cache status
    final scriptCacheValid = await _database.isCacheValid('script_1.0.0');
    print('\nCache Status:');
    print('  Script cache valid: $scriptCacheValid');
    
    print('================================');
  }

  /// Clear all test data.
  static Future<void> clearTestData() async {
    await _database.cleanup();
    print('Test data cleared');
  }

  /// Generate sample conversation history.
  static Future<void> generateSampleHistory({
    int days = 7,
    double successRate = 0.8,
  }) async {
    final random = Random();
    final now = DateTime.now();
    
    for (int i = days; i > 0; i--) {
      final date = now.subtract(Duration(days: i));
      final succeeded = random.nextDouble() < successRate;
      
      // Morning check-in
      await _database.saveMessage(
        id: 'msg_${date.millisecondsSinceEpoch}_1',
        sender: 'tristopher',
        type: 'text',
        content: 'Did you complete your goal yesterday?',
        metadata: {
          'timestamp': date.millisecondsSinceEpoch,
        },
      );
      
      // User response
      await _database.saveMessage(
        id: 'msg_${date.millisecondsSinceEpoch}_2',
        sender: 'user',
        type: 'text',
        content: succeeded ? 'Yes, I did it' : 'No, I failed',
        metadata: {
          'timestamp': date.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
        },
      );
      
      // Tristopher's response
      await _database.saveMessage(
        id: 'msg_${date.millisecondsSinceEpoch}_3',
        sender: 'tristopher',
        type: 'text',
        content: succeeded 
            ? 'Huh. Color me surprised.'
            : 'As expected. Your money has been sent.',
        metadata: {
          'timestamp': date.add(const Duration(minutes: 2)).millisecondsSinceEpoch,
        },
      );
    }
    
    print('Generated $days days of conversation history');
  }
}

/// Performance monitoring utilities.
class ConversationPerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _measurements = {};

  /// Start timing an operation.
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }

  /// Stop timing and record the measurement.
  static void stopTimer(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      _measurements[operation] ??= [];
      _measurements[operation]!.add(timer.elapsedMilliseconds);
      print('⏱️ $operation: ${timer.elapsedMilliseconds}ms');
    }
  }

  /// Get performance statistics.
  static Map<String, PerformanceStats> getStats() {
    final stats = <String, PerformanceStats>{};
    
    _measurements.forEach((operation, times) {
      if (times.isNotEmpty) {
        times.sort();
        final average = times.reduce((a, b) => a + b) / times.length;
        final median = times[times.length ~/ 2];
        final min = times.first;
        final max = times.last;
        
        stats[operation] = PerformanceStats(
          count: times.length,
          average: average,
          median: median.toDouble(),
          min: min,
          max: max,
        );
      }
    });
    
    return stats;
  }

  /// Clear all measurements.
  static void clear() {
    _timers.clear();
    _measurements.clear();
  }

  /// Print performance report.
  static void printReport() {
    print('\n=== Performance Report ===');
    final stats = getStats();
    
    stats.forEach((operation, stat) {
      print('$operation:');
      print('  Calls: ${stat.count}');
      print('  Average: ${stat.average.toStringAsFixed(1)}ms');
      print('  Median: ${stat.median.toStringAsFixed(1)}ms');
      print('  Min: ${stat.min}ms');
      print('  Max: ${stat.max}ms');
    });
    
    print('========================\n');
  }
}

/// Performance statistics.
class PerformanceStats {
  final int count;
  final double average;
  final double median;
  final int min;
  final int max;

  PerformanceStats({
    required this.count,
    required this.average,
    required this.median,
    required this.min,
    required this.max,
  });
}

// Add Random import
//import 'dart:math';
