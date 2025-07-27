#!/usr/bin/env dart

import 'dart:io';

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
    
    print('🚀 Starting conversation CLI...');
    print('📋 Sequence: ${config.sequenceId}');
    if (config.scenarioName != null) {
      print('👤 Scenario: ${config.scenarioName}');
    }
    print('');
    
    // For now, show what would happen
    print('📝 This CLI would run the following conversation:');
    print('   • Sequence: ${config.sequenceId}');
    print('   • Interactive: ${config.interactive}');
    print('   • Verbose: ${config.verbose}');
    if (config.scenarioName != null) {
      print('   • Scenario: ${config.scenarioName}');
    }
    if (config.autoResponses.isNotEmpty) {
      print('   • Auto responses: ${config.autoResponses}');
    }
    
    print('');
    print('🔧 To use the full conversation runner, run:');
    print('   flutter test test/cli/conversation_test.dart --name "${config.sequenceId}"');
    
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
  dart tool/conversation_cli_standalone.dart [OPTIONS]

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
  dart tool/conversation_cli_standalone.dart --sequence welcome_seq

  # Load returning user scenario  
  dart tool/conversation_cli_standalone.dart --scenario "Returning User"

  # Auto-run with predetermined responses
  dart tool/conversation_cli_standalone.dart --auto "choice:1,text:My Task"

  # Debug mode with verbose output
  dart tool/conversation_cli_standalone.dart --sequence onboarding_seq --verbose

  # List available sequences
  dart tool/conversation_cli_standalone.dart --list-sequences

  # List available scenarios
  dart tool/conversation_cli_standalone.dart --list-scenarios

SEQUENCES:
  welcome_seq, onboarding_seq, active_seq, inactive_seq, pending_seq,
  completed_seq, failed_seq, deadline_seq, reminders_seq, sendoff_seq

SCENARIOS:
  "New User", "Returning User", "Weekend User", "Past Deadline",
  "High Streak", "Struggling User", "Evening Check", "Reset All"

FULL CONVERSATION TESTING:
  To run full conversation tests with actual Flutter services:
    flutter test test/cli/conversation_test.dart

  To run specific sequence tests:
    flutter test test/cli/conversation_test.dart --name "welcome_seq"

For more information, see: CLAUDE.md
''');
}

Future<void> listAvailableSequences() async {
  print('📋 Available Sequences:');
  print('');
  
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
  print('Usage: dart tool/conversation_cli_standalone.dart --sequence <sequence_id>');
  print('');
  print('For full testing with Flutter services:');
  print('  flutter test test/cli/conversation_test.dart --name "<sequence_id>"');
}

Future<void> listAvailableScenarios() async {
  print('👤 Available Scenarios:');
  print('');
  
  final scenarios = {
    'New User': 'Brand new user, first time opening app',
    'Returning User': 'User who has used the app before',
    'Weekend User': 'User opening app on weekend',
    'Past Deadline': 'User who missed their deadline',
    'High Streak': 'User with a long completion streak',
    'Struggling User': 'User who has been failing tasks',
    'Evening Check': 'User checking in during evening hours',
    'Reset All': 'Clean slate with all data reset',
  };
  
  for (final entry in scenarios.entries) {
    print('  • "${entry.key}"');
    print('    ${entry.value}');
    print('');
  }
  
  print('Usage: dart tool/conversation_cli_standalone.dart --scenario "Scenario Name"');
  print('');
  print('For full testing with Flutter services:');
  print('  flutter test test/cli/conversation_test.dart');
}