import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/chat_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/text_templating_service.dart';
import 'package:noexc/services/text_variants_service.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/scenario_manager.dart';
import 'package:noexc/services/logger_service.dart';
import 'package:noexc/models/chat_message.dart';
import 'package:noexc/models/choice.dart';
import 'package:noexc/constants/app_constants.dart';

/// Terminal color codes for enhanced output formatting
class TerminalColors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String underline = '\x1B[4m';
  
  // Text colors
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  
  // Bright colors
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';
  
  // Background colors
  static const String bgBlack = '\x1B[40m';
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';
  static const String bgWhite = '\x1B[47m';
}

/// Enhanced terminal output formatter
class TerminalFormatter {
  static bool colorsEnabled = true;
  
  static String colorize(String text, String color) {
    if (!colorsEnabled) return text;
    return '$color$text${TerminalColors.reset}';
  }
  
  static String bot(String text) => colorize(text, TerminalColors.brightCyan);
  static String user(String text) => colorize(text, TerminalColors.brightGreen);
  static String system(String text) => colorize(text, TerminalColors.brightYellow);
  static String error(String text) => colorize(text, TerminalColors.brightRed);
  static String success(String text) => colorize(text, TerminalColors.brightGreen);
  static String info(String text) => colorize(text, TerminalColors.brightBlue);
  static String dim(String text) => colorize(text, TerminalColors.dim);
  static String bold(String text) => colorize(text, TerminalColors.bold);
  static String choice(String text) => colorize(text, TerminalColors.yellow);
  
  static void printBox(String title, List<String> content, {String color = ''}) {
    final width = 60;
    final titleLine = '┌─ $title ';
    final padding = width - titleLine.length;
    
    print(colorize('$titleLine${'─' * padding}┐', color));
    for (final line in content) {
      final contentPadding = width - line.length - 2;
      print(colorize('│ $line${' ' * contentPadding}│', color));
    }
    print(colorize('└${'─' * (width - 1)}┘', color));
  }
  
  static void printSeparator({String char = '─', int length = 60}) {
    print(colorize(char * length, TerminalColors.dim));
  }
}

/// Result of a conversation run
class ConversationResult {
  final String sequenceId;
  final List<ChatMessage> messages;
  final Map<String, dynamic> finalUserState;
  final bool completed;
  final String? endReason;
  final Duration duration;

  ConversationResult({
    required this.sequenceId,
    required this.messages,
    required this.finalUserState,
    required this.completed,
    this.endReason,
    required this.duration,
  });
}

/// Core conversation runner that leverages existing test infrastructure
class ConversationRunner {
  late ChatService chatService;
  late UserDataService userDataService;
  late SessionService sessionService;
  
  bool interactive;
  bool verbose;
  List<ChatMessage> conversationLog = [];
  
  ConversationRunner({
    this.interactive = false,
    this.verbose = false,
  });

  /// Initialize services using existing test patterns
  Future<void> _initializeServices() async {
    // Use same setup as existing tests
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    // Check if colors should be disabled (for CI/CD environments)
    TerminalFormatter.colorsEnabled = Platform.environment['NO_COLOR'] == null;
    
    // Configure logger based on verbose flag
    logger.configure(
      minLevel: verbose ? LogLevel.debug : LogLevel.warning,
    );
    
    userDataService = UserDataService();
    final templatingService = TextTemplatingService(userDataService);
    final variantsService = TextVariantsService();
    
    chatService = ChatService(
      userDataService: userDataService,
      templatingService: templatingService,
      variantsService: variantsService,
    );
    
    sessionService = SessionService(userDataService);
  }

  /// Main function to run a conversation
  Future<ConversationResult> runConversation({
    required String sequenceId,
    Map<String, dynamic>? userState,
    List<String>? autoResponses,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await _initializeServices();
      
      if (verbose || interactive) {
        _printInitializationInfo(sequenceId, userState);
      }
      
      // Apply user state if provided
      if (userState != null) {
        await _applyUserState(userState);
      }
      
      // Initialize session (like production app)
      await sessionService.initializeSession();
      
      // Start conversation
      await _startConversation(sequenceId, autoResponses);
      
      // Get final state
      final finalUserState = await userDataService.getAllData();
      
      stopwatch.stop();
      
      return ConversationResult(
        sequenceId: sequenceId,
        messages: conversationLog,
        finalUserState: finalUserState,
        completed: true,
        duration: stopwatch.elapsed,
      );
      
    } catch (e) {
      stopwatch.stop();
      
      if (verbose) {
        _log('❌ Error during conversation: $e');
      }
      
      return ConversationResult(
        sequenceId: sequenceId,
        messages: conversationLog,
        finalUserState: {},
        completed: false,
        endReason: 'Error: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Print initialization information with enhanced formatting
  void _printInitializationInfo(String sequenceId, Map<String, dynamic>? userState) {
    if (interactive) {
      TerminalFormatter.printBox(
        'Conversation Runner',
        [
          'Sequence: $sequenceId',
          'Interactive: $interactive',
          'Verbose: $verbose',
          if (userState != null) 'User state: ${userState.length} variables',
        ],
        color: TerminalColors.brightBlue,
      );
      print('');
    } else if (verbose) {
      _log(TerminalFormatter.system('🚀 Initializing conversation runner...'));
      _log(TerminalFormatter.info('📋 Sequence: $sequenceId'));
      _log(TerminalFormatter.info('👤 Interactive mode: $interactive'));
    }
  }

  /// Apply user state from scenarios or custom data
  Future<void> _applyUserState(Map<String, dynamic> userState) async {
    if (verbose || interactive) {
      if (interactive) {
        TerminalFormatter.printBox(
          'Applying User State',
          userState.entries.map((e) => '${e.key}: ${e.value}').toList(),
          color: TerminalColors.brightYellow,
        );
        print('');
      } else {
        _log(TerminalFormatter.system('📝 Applying user state...'));
      }
    }
    
    for (final entry in userState.entries) {
      await userDataService.storeValue(entry.key, entry.value);
      if (verbose && !interactive) {
        _log('   ${entry.key}: ${entry.value}');
      }
    }
  }

  /// Start the conversation flow
  Future<void> _startConversation(String sequenceId, List<String>? autoResponses) async {
    if (verbose && !interactive) {
      _log(TerminalFormatter.system('🎬 Starting conversation flow...'));
    }
    
    // Load sequence and get initial messages
    final messages = await chatService.getInitialMessages(sequenceId: sequenceId);
    
    if (interactive) {
      TerminalFormatter.printSeparator(char: '═', length: 60);
      print(TerminalFormatter.bold(TerminalFormatter.system('🤖 CONVERSATION START')));
      TerminalFormatter.printSeparator(char: '═', length: 60);
      print('');
    }
    
    await _processMessages(messages, autoResponses ?? []);
  }

  /// Process a list of messages
  Future<void> _processMessages(List<ChatMessage> messages, List<String> autoResponses) async {
    int responseIndex = 0;
    
    for (final message in messages) {
      conversationLog.add(message);
      
      // Display message
      _displayMessage(message);
      
      // Handle user interactions
      if (message.isChoice) {
        final choice = await _handleChoice(message, autoResponses, responseIndex);
        if (choice != null) {
          responseIndex++;
          
          // Store choice and get next messages
          await chatService.handleUserChoice(message, choice);
          
          if (choice.nextMessageId != null) {
            final nextMessages = await chatService.getMessagesAfterChoice(choice.nextMessageId!);
            await _processMessages(nextMessages, autoResponses);
          } else if (choice.sequenceId != null) {
            // Cross-sequence navigation
            final nextMessages = await chatService.getInitialMessages(sequenceId: choice.sequenceId!);
            await _processMessages(nextMessages, autoResponses);
          }
          return;
        }
      } else if (message.isTextInput) {
        final userInput = await _handleTextInput(message, autoResponses, responseIndex);
        if (userInput != null) {
          responseIndex++;
          
          // Store input and get next messages
          await chatService.handleUserTextInput(message, userInput);
          
          if (message.nextMessageId != null) {
            final nextMessages = await chatService.getMessagesAfterTextInput(message.nextMessageId!, userInput);
            await _processMessages(nextMessages, autoResponses);
          }
          return;
        }
      }
    }
    
    if (interactive) {
      print('');
      TerminalFormatter.printSeparator(char: '═', length: 60);
      print(TerminalFormatter.bold(TerminalFormatter.success('🎯 CONVERSATION END')));
      TerminalFormatter.printSeparator(char: '═', length: 60);
    }
  }

  /// Display a message with enhanced formatting
  void _displayMessage(ChatMessage message) {
    if (message.isAutoRoute || message.isDataAction) {
      if (verbose) {
        final type = message.isAutoRoute ? 'AUTOROUTE' : 'DATA_ACTION';
        _log(TerminalFormatter.dim('🔄 $type: Processing...'));
      }
      return;
    }
    
    final isBot = message.sender == 'bot';
    final prefix = isBot ? '🤖' : '👤';
    final text = message.text;
    
    if (interactive) {
      // Enhanced interactive display with colors and formatting
      if (isBot) {
        print('$prefix ${TerminalFormatter.bot(text)}');
      } else {
        print('$prefix ${TerminalFormatter.user(text)}');
      }
      
      // Add small delay for better UX in interactive mode
      if (isBot) {
        sleep(Duration(milliseconds: 500));
      }
    } else {
      // Always show conversation content in non-interactive mode
      _log('$prefix $text');
    }
    
    // Display choices with enhanced formatting
    if (message.isChoice && message.choices != null) {
      if (interactive) {
        print('');
        for (int i = 0; i < message.choices!.length; i++) {
          final choice = message.choices![i];
          print('   ${TerminalFormatter.choice('${i + 1}.')} ${choice.text}');
        }
        print('');
      } else {
        // Always show choices in non-interactive mode
        for (int i = 0; i < message.choices!.length; i++) {
          final choice = message.choices![i];
          _log('   Choice ${i + 1}: ${choice.text}');
        }
      }
    }
    
    // Display text input prompt with enhanced formatting
    if (message.isTextInput) {
      final prompt = message.placeholderText ?? AppConstants.defaultPlaceholderText;
      if (interactive) {
        print('');
        print('   ${TerminalFormatter.info('💬')} ${TerminalFormatter.dim(prompt)}');
        print('');
      } else {
        // Always show text input prompts in non-interactive mode
        _log('   💬 Text input: $prompt');
      }
    }
  }

  /// Handle choice selection
  Future<Choice?> _handleChoice(ChatMessage message, List<String> autoResponses, int responseIndex) async {
    if (message.choices == null || message.choices!.isEmpty) {
      return null;
    }
    
    int selectedIndex = 0;
    
    if (interactive) {
      // Interactive mode: get user input with enhanced formatting
      while (true) {
        stdout.write('${TerminalFormatter.bold('👆 Select choice')} (${TerminalFormatter.choice('1-${message.choices!.length}')}): ');
        final input = stdin.readLineSync();
        
        if (input != null) {
          final choice = int.tryParse(input);
          if (choice != null && choice >= 1 && choice <= message.choices!.length) {
            selectedIndex = choice - 1;
            break;
          }
        }
        print(TerminalFormatter.error('❌ Invalid choice. Please enter 1-${message.choices!.length}'));
      }
    } else {
      // Automated mode: use auto-response or default to first choice
      if (responseIndex < autoResponses.length) {
        final response = autoResponses[responseIndex];
        if (response.startsWith('choice:')) {
          final choiceNum = int.tryParse(response.substring(7));
          if (choiceNum != null && choiceNum >= 1 && choiceNum <= message.choices!.length) {
            selectedIndex = choiceNum - 1;
          }
        }
      }
      
      if (!interactive) {
        // Always show auto-selections in non-interactive mode
        _log(TerminalFormatter.system('🤖 Auto-selected choice ${selectedIndex + 1}: ${message.choices![selectedIndex].text}'));
      }
    }
    
    final selectedChoice = message.choices![selectedIndex];
    
    // Log user selection
    final userMessage = ChatMessage(
      id: AppConstants.userResponseIdOffset + message.id,
      text: selectedChoice.text,
      sender: 'user',
      delay: 0,
    );
    conversationLog.add(userMessage);
    
    if (interactive) {
      print('👤 ${TerminalFormatter.user(selectedChoice.text)}');
      print('');
    }
    
    return selectedChoice;
  }

  /// Handle text input
  Future<String?> _handleTextInput(ChatMessage message, List<String> autoResponses, int responseIndex) async {
    String userInput = '';
    
    if (interactive) {
      // Interactive mode: get user input with enhanced formatting
      stdout.write('${TerminalFormatter.bold('✏️  Your input')}: ');
      userInput = stdin.readLineSync() ?? '';
    } else {
      // Automated mode: use auto-response or default
      if (responseIndex < autoResponses.length) {
        final response = autoResponses[responseIndex];
        if (response.startsWith('text:')) {
          userInput = response.substring(5);
        }
      }
      
      if (userInput.isEmpty) {
        userInput = 'Test input';
      }
      
      if (!interactive) {
        // Always show auto-inputs in non-interactive mode
        _log(TerminalFormatter.system('🤖 Auto-input: $userInput'));
      }
    }
    
    // Log user input
    final userMessage = ChatMessage(
      id: AppConstants.userResponseIdOffset + message.id,
      text: userInput,
      sender: 'user',
      delay: 0,
    );
    conversationLog.add(userMessage);
    
    if (interactive) {
      print('👤 ${TerminalFormatter.user(userInput)}');
      print('');
    }
    
    return userInput;
  }

  /// Log message with timestamp
  void _log(String message) {
    if (verbose || !interactive) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      print('[$timestamp] $message');
    }
  }
}

/// Load scenario from assets or use built-in scenarios
Future<Map<String, dynamic>?> loadScenario(String scenarioName, {bool verbose = false}) async {
  // First try to load from assets
  try {
    final scenarios = await ScenarioManager.loadScenarios();
    final scenario = scenarios[scenarioName];
    
    if (scenario != null && scenario['variables'] != null) {
      return Map<String, dynamic>.from(scenario['variables']);
    }
  } catch (e) {
    // Asset loading failed, use built-in scenarios
    if (verbose) {
      print('⚠️ Asset scenario loading failed, using built-in: $e');
    }
  }
  
  // Use built-in scenarios as fallback
  final builtInScenarios = {
    'new_user': {
      'user.name': null,
      'user.isOnboarded': false,
      'session.visitCount': 1,
      'session.totalVisitCount': 1,
    },
    'returning_user': {
      'user.name': 'John Doe',
      'user.isOnboarded': true,
      'session.visitCount': 3,
      'session.totalVisitCount': 15,
      'task.currentDate': '2025-01-27',
      'task.status': 'pending',
    },
    'weekend_user': {
      'user.name': 'Sarah Wilson',
      'user.isOnboarded': true,
      'session.isWeekend': true,
      'session.visitCount': 1,
      'task.isActiveDay': false,
    },
    'past_deadline': {
      'user.name': 'Mike Johnson',
      'user.isOnboarded': true,
      'task.currentDate': '2025-01-27',
      'task.status': 'overdue',
      'task.isPastDeadline': true,
    },
  };
  
  // Try exact match first
  if (builtInScenarios.containsKey(scenarioName)) {
    return builtInScenarios[scenarioName];
  }
  
  // Try case-insensitive lookup for user-friendly names
  final normalizedName = scenarioName.toLowerCase().replaceAll(' ', '_');
  if (builtInScenarios.containsKey(normalizedName)) {
    return builtInScenarios[normalizedName];
  }
  
  // Try partial matching
  for (final entry in builtInScenarios.entries) {
    if (entry.key.contains(normalizedName) || normalizedName.contains(entry.key)) {
      return entry.value;
    }
  }
  
  return null;
}

/// Quick run function for external usage
Future<ConversationResult> runConversation({
  required String sequenceId,
  Map<String, dynamic>? userState,
  List<String>? autoResponses,
  bool interactive = false,
  bool verbose = false,
}) async {
  final runner = ConversationRunner(
    interactive: interactive,
    verbose: verbose,
  );
  
  return await runner.runConversation(
    sequenceId: sequenceId,
    userState: userState,
    autoResponses: autoResponses,
  );
}