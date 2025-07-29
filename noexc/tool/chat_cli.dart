#!/usr/bin/env dart

import 'dart:io';
import '../test/cli/conversation_runner.dart';

const String version = '1.0.0';

void main(List<String> args) async {
  try {
    // Parse command line arguments
    final config = parseArguments(args);
    
    if (config.showHelp) {
      printHelp();
      return;
    }
    
    if (config.showVersion) {
      print('Chat CLI v$version');
      return;
    }
    
    if (config.listSequences) {
      await listAvailableSequences();
      return;
    }
    
    if (config.listScenarios) {
      await listAvailableScenarios();
      return;
    }
    
    // Load scenario if specified
    Map<String, dynamic>? userState;
    if (config.scenarioName != null) {
      userState = await loadScenario(config.scenarioName!);
      
      if (config.verbose) {
        print('✅ Loaded scenario: ${config.scenarioName}');
      }
    }
    
    print('🚀 Starting conversation CLI...');
    print('📋 Sequence: ${config.sequenceId}');
    if (config.scenarioName != null) {
      print('👤 Scenario: ${config.scenarioName}');
    }
    print('');
    
    // Run the conversation
    final result = await runConversation(
      sequenceId: config.sequenceId,
      userState: userState,
      autoResponses: config.autoResponses,
      interactive: config.interactive,
      verbose: config.verbose,
    );
    
    // Print results summary
    if (config.verbose || !config.interactive) {
      print('\n📊 === CONVERSATION SUMMARY ===');
      print('Duration: ${result.duration.inMilliseconds}ms');
      print('Messages: ${result.messages.length}');
      print('Completed: ${result.completed ? "✅" : "❌"}');
      if (result.endReason != null) {
        print('End reason: ${result.endReason}');
      }
      print('');
      
      // Show final user state if verbose
      if (config.verbose && result.finalUserState.isNotEmpty) {
        print('📝 Final User State:');
        result.finalUserState.forEach((key, value) {
          print('  $key: $value');
        });
        print('');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

class CliConfig {
  final String sequenceId;
  final String? scenarioName;
  final List<String> autoResponses;
  final bool interactive;
  final bool verbose;
  final bool showHelp;
  final bool showVersion;
  final bool listSequences;
  final bool listScenarios;
  
  CliConfig({
    required this.sequenceId,
    this.scenarioName,
    this.autoResponses = const [],
    this.interactive = true,
    this.verbose = false,
    this.showHelp = false,
    this.showVersion = false,
    this.listSequences = false,
    this.listScenarios = false,
  });
}

CliConfig parseArguments(List<String> args) {
  String sequenceId = 'welcome_seq';
  String? scenarioName;
  List<String> autoResponses = [];
  bool interactive = true;
  bool verbose = false;
  bool showHelp = false;
  bool showVersion = false;
  bool listSequences = false;
  bool listScenarios = false;
  
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--help':
      case '-h':
        showHelp = true;
        break;
      case '--version':
      case '-v':
        showVersion = true;
        break;
      case '--sequence':
      case '-s':
        if (i + 1 < args.length) {
          sequenceId = args[++i];
        }
        break;
      case '--scenario':
        if (i + 1 < args.length) {
          scenarioName = args[++i];
        }
        break;
      case '--auto':
      case '-a':
        interactive = false;
        if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
          // Parse auto responses: choice:1,text:hello
          final responses = args[++i].split(',');
          autoResponses.addAll(responses);
        }
        break;
      case '--verbose':
        verbose = true;
        break;
      case '--list-sequences':
        listSequences = true;
        break;
      case '--list-scenarios':
        listScenarios = true;
        break;
    }
  }
  
  return CliConfig(
    sequenceId: sequenceId,
    scenarioName: scenarioName,
    autoResponses: autoResponses,
    interactive: interactive,
    verbose: verbose,
    showHelp: showHelp,
    showVersion: showVersion,
    listSequences: listSequences,
    listScenarios: listScenarios,
  );
}

void printHelp() {
  print('''
🤖 Chat CLI - Test conversation flows without loading the UI

USAGE:
  dart tool/chat_cli.dart [OPTIONS]

OPTIONS:
  -s, --sequence <id>      Sequence to run (default: welcome_seq)
  --scenario <name>        Load predefined user scenario
  -a, --auto [responses]   Non-interactive mode with auto responses
  --verbose                Show detailed logging and state changes
  --list-sequences         List all available sequences
  --list-scenarios         List all available scenarios
  -v, --version           Show version information
  -h, --help              Show this help message

EXAMPLES:
  # Interactive conversation with welcome sequence
  dart tool/chat_cli.dart --sequence welcome_seq

  # Load returning user scenario  
  dart tool/chat_cli.dart --scenario "Returning User"

  # Auto-run with predetermined responses
  dart tool/chat_cli.dart --auto "choice:1,text:My Task"

  # Debug mode with verbose output
  dart tool/chat_cli.dart --sequence onboarding_seq --verbose

  # List available sequences
  dart tool/chat_cli.dart --list-sequences

  # List available scenarios
  dart tool/chat_cli.dart --list-scenarios

SEQUENCES:
  welcome_seq, onboarding_seq, active_seq, inactive_seq, pending_seq,
  completed_seq, failed_seq, deadline_seq, reminders_seq, sendoff_seq

SCENARIOS:
  "New User", "Returning User", "Weekend User", "Past Deadline",
  "High Streak", "Struggling User", "Evening Check", "Reset All"

For more information, see: CLAUDE.md
''');
}

Future<void> listAvailableSequences() async {
  print('📋 Available Sequences:');
  print('');
  
  // Import constants to get available sequences
  final sequences = [
    'welcome_seq',
    'onboarding_seq', 
    'active_seq',
    'inactive_seq',
    'pending_seq',
    'completed_seq',
    'failed_seq',
    'deadline_seq',
    'reminders_seq',
    'sendoff_seq',
    'intro_seq',
    'settask_seq',
    'weekdays_seq',
    'notice_seq',
    'excuse_seq',
    'overdue_seq',
    'previous_seq',
    'success_seq',
  ];
  
  for (final seq in sequences) {
    print('  • $seq');
  }
  
  print('');
  print('Usage: dart tool/chat_cli.dart --sequence <sequence_id>');
}

Future<void> listAvailableScenarios() async {
  print('👤 Available Scenarios:');
  print('');
  
  try {
    final scenarios = await loadScenarios();
    
    for (final entry in scenarios.entries) {
      final scenario = entry.value;
      final name = scenario['name'] ?? entry.key;
      final description = scenario['description'] ?? 'No description';
      
      print('  • "$name"');
      print('    $description');
      print('');
    }
    
    print('Usage: dart tool/chat_cli.dart --scenario "Scenario Name"');
    
  } catch (e) {
    print('❌ Error loading scenarios: $e');
  }
}

Future<Map<String, dynamic>> loadScenarios() async {
  // Simple implementation to load scenarios
  // This would normally import from ScenarioManager but we keep it simple
  return {
    'new_user': {
      'name': 'New User',
      'description': 'Brand new user, first time opening app',
      'variables': {
        'user.name': null,
        'user.isOnboarded': false,
        'session.visitCount': 1,
        'session.totalVisitCount': 1,
      }
    },
    'returning_user': {
      'name': 'Returning User', 
      'description': 'User who has used the app before',
      'variables': {
        'user.name': 'John Doe',
        'user.isOnboarded': true,
        'session.visitCount': 3,
        'session.totalVisitCount': 15,
        'task.currentDate': '2025-01-27',
        'task.currentStatus': 'pending',
      }
    },
    'weekend_user': {
      'name': 'Weekend User',
      'description': 'User opening app on weekend',
      'variables': {
        'user.name': 'Sarah Wilson',
        'user.isOnboarded': true,
        'session.isWeekend': true,
        'session.visitCount': 1,
        'task.isActiveDay': false,
      }
    },
    'past_deadline': {
      'name': 'Past Deadline',
      'description': 'User who missed their deadline',
      'variables': {
        'user.name': 'Mike Johnson',
        'user.isOnboarded': true,
        'task.currentDate': '2025-01-27',
        'task.currentStatus': 'overdue',
        'task.isPastDeadline': true,
      }
    },
  };
}