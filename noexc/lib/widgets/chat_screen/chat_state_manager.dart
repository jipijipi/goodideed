import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../../models/chat_sequence.dart';
import '../../services/logger_service.dart';
import '../../services/service_locator.dart';
import '../../services/app_lifecycle_manager.dart';
import '../../constants/app_constants.dart';
import '../../services/engagement_policy.dart';
import 'state_management/message_display_manager.dart';
import 'state_management/user_interaction_handler.dart';

/// Orchestrates chat state management by coordinating focused components
/// Main controller that handles initialization, user actions, and debug controls
class ChatStateManager extends ChangeNotifier with WidgetsBindingObserver {
  // Component managers - use ServiceLocator for dependency injection
  late final MessageDisplayManager _messageDisplayManager;
  late final UserInteractionHandler _userInteractionHandler;
  late final AppLifecycleManager _lifecycleManager;

  // State
  bool _isPanelVisible = false;
  bool _disposed = false;

  // Getters - delegate to appropriate managers
  List<ChatMessage> get displayedMessages =>
      _messageDisplayManager.displayedMessages;
  ChatMessage? get currentTextInputMessage =>
      _messageDisplayManager.currentTextInputMessage;
  bool get isPanelVisible => _isPanelVisible;
  ScrollController get scrollController =>
      _messageDisplayManager.scrollController;
  GlobalKey<AnimatedListState> get animatedListKey =>
      _messageDisplayManager.animatedListKey;
  String get currentSequenceId {
    // Authoritative sequence from engine; fallback to default for UI
    return ServiceLocator.instance.chatService.currentSequence?.sequenceId ??
        AppConstants.defaultSequenceId;
  }
  ChatSequence? get currentSequence =>
      ServiceLocator.instance.chatService.currentSequence;

  // Service access
  get userDataService => ServiceLocator.instance.userDataService;
  AppLifecycleManager get lifecycleManager => _lifecycleManager;

  /// Initialize the chat state manager
  Future<void> initialize() async {
    final overallStopwatch = Stopwatch()..start();
    final timings = <String, int>{};

    logger.info('💬 ChatStateManager initialization started');

    try {
      // Services are already initialized at app level via ServiceLocator

      // Initialize component managers
      var stepStopwatch = Stopwatch()..start();
      _messageDisplayManager = MessageDisplayManager();
      _userInteractionHandler = UserInteractionHandler(
        messageDisplayManager: _messageDisplayManager,
        chatService: ServiceLocator.instance.chatService,
        messageQueue: ServiceLocator.instance.messageQueue,
      );
      timings['ComponentManagers'] = stepStopwatch.elapsedMilliseconds;
      logger.debug('✓ ComponentManagers: ${timings['ComponentManagers']}ms');

      // Initialize lifecycle manager
      stepStopwatch.reset();
      _lifecycleManager = AppLifecycleManager(
        sessionService: ServiceLocator.instance.sessionService,
        onAppResumedFromEndState: _handleAppResumedFromEndState,
      );
      timings['LifecycleManager'] = stepStopwatch.elapsedMilliseconds;
      logger.debug('✓ LifecycleManager: ${timings['LifecycleManager']}ms');

      // Keep UI sequence in sync with engine transitions
      stepStopwatch.reset();
      ServiceLocator.instance.chatService.setOnSequenceChanged((seqId) {
        logger.debug('Sequence changed (engine) → $seqId', component: LogComponent.ui);
        notifyListeners();
      });

      // Set up event callback for typing indicators and other UI events
      ServiceLocator.instance.chatService.setEventCallback(_handleChatServiceEvent);

      // Register as lifecycle observer
      WidgetsBinding.instance.addObserver(this);
      timings['EventCallbacks+Observer'] = stepStopwatch.elapsedMilliseconds;
      logger.debug('✓ EventCallbacks+Observer: ${timings['EventCallbacks+Observer']}ms');

      // Load and display initial messages (most expensive operation)
      stepStopwatch.reset();
      await _messageDisplayManager.loadAndDisplayMessages(
        ServiceLocator.instance.chatService,
        ServiceLocator.instance.messageQueue,
        AppConstants.defaultSequenceId,
        notifyListeners,
      );
      timings['LoadAndDisplayMessages'] = stepStopwatch.elapsedMilliseconds;
      logger.debug('✓ LoadAndDisplayMessages: ${timings['LoadAndDisplayMessages']}ms');

      final totalTime = overallStopwatch.elapsedMilliseconds;
      logger.info('🎯 ChatStateManager initialization completed in ${totalTime}ms');

      // Highlight the most expensive operation
      final maxEntry = timings.entries.reduce((a, b) => a.value > b.value ? a : b);
      logger.info('🐌 Slowest operation: ${maxEntry.key} (${maxEntry.value}ms, ${(maxEntry.value / totalTime * 100).toStringAsFixed(1)}% of total)');

    } catch (e) {
      final totalTime = overallStopwatch.elapsedMilliseconds;
      logger.error('❌ ChatStateManager initialization failed after ${totalTime}ms: $e');
      rethrow;
    }
  }

  /// Handle user choice selection
  Future<void> onChoiceSelected(
    Choice choice,
    ChatMessage choiceMessage,
  ) async {
    await _userInteractionHandler.handleChoiceSelection(
      choice,
      choiceMessage,
      currentSequenceId,
      notifyListeners,
    );
  }

  /// Handle user text input submission
  Future<void> onTextInputSubmitted(
    String userInput,
    ChatMessage textInputMessage,
  ) async {
    await _userInteractionHandler.handleTextInputSubmission(
      userInput,
      textInputMessage,
      notifyListeners,
    );
  }


  /// Handle app lifecycle state changes
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!_disposed) {
      await _lifecycleManager.didChangeAppLifecycleState(state);
    }
  }

  /// Handle app resuming from end state - trigger re-engagement
  Future<void> _handleAppResumedFromEndState() async {
    final reengageStopwatch = Stopwatch()..start();
    final timings = <String, int>{};

    try {
      // Essential log only
      logger.info('🔄 Resume re-engagement started', component: LogComponent.ui);
      final defaultSeq = AppConstants.defaultSequenceId;
      final activeSeq = ServiceLocator.instance.chatService.currentSequence?.sequenceId;
      logger.debug('active_seq=${activeSeq ?? 'none'} ui_seq=$currentSequenceId', component: LogComponent.ui);

      // Busy guard via policy (existing guards only)
      var stepStopwatch = Stopwatch()..start();
      final hasTextInput = _messageDisplayManager.currentTextInputMessage != null;
      final hasUnansweredChoice = _messageDisplayManager.displayedMessages.any(
        (m) => m.type == MessageType.choice && m.selectedChoiceText == null,
      );
      final panelOpen = _isPanelVisible;
      final canReengage = EngagementPolicy.shouldReengage(
        panelOpen: panelOpen,
        hasTextInput: hasTextInput,
        hasUnansweredChoice: hasUnansweredChoice,
      );
      timings['BusyGuardCheck'] = stepStopwatch.elapsedMilliseconds;

      if (!canReengage) {
        final totalTime = reengageStopwatch.elapsedMilliseconds;
        logger.info('⏭️  Re-engagement skipped after ${totalTime}ms: input=$hasTextInput choice=$hasUnansweredChoice panel=$panelOpen', component: LogComponent.ui);
        return;
      }

      // Append mode: start default sequence and append its messages without clearing
      stepStopwatch.reset();
      logger.info('🎯 Starting re-engagement with sequence=$defaultSeq', component: LogComponent.ui);
      final flow = await ServiceLocator.instance.chatService.start(defaultSeq);
      timings['StartSequence'] = stepStopwatch.elapsedMilliseconds;

      stepStopwatch.reset();
      await _messageDisplayManager.displayMessages(
        flow.messages,
        ServiceLocator.instance.messageQueue,
        notifyListeners,
      );
      timings['DisplayMessages'] = stepStopwatch.elapsedMilliseconds;

      final totalTime = reengageStopwatch.elapsedMilliseconds;
      logger.info('✅ Re-engagement completed in ${totalTime}ms', component: LogComponent.ui);
      logger.debug('🐌 Re-engagement timing: BusyCheck=${timings['BusyGuardCheck']}ms, StartSeq=${timings['StartSequence']}ms, DisplayMsg=${timings['DisplayMessages']}ms', component: LogComponent.ui);

    } catch (e) {
      final totalTime = reengageStopwatch.elapsedMilliseconds;
      logger.error('❌ Re-engagement failed after ${totalTime}ms: $e', component: LogComponent.ui);
    }
  }

  /// Toggle the user variables panel visibility
  void togglePanel() {
    _isPanelVisible = !_isPanelVisible;
    notifyListeners();
  }

  /// Switch to a different chat sequence
  Future<void> switchSequence(String sequenceId) async {
    logger.debug('switchSequence to=$sequenceId', component: LogComponent.ui);
    
    if (_disposed) {
      logger.warning('❌ switchSequence: ChatStateManager is disposed', component: LogComponent.ui);
      return;
    }
    
    final activeSeq = ServiceLocator.instance.chatService.currentSequence?.sequenceId;
    if (activeSeq == sequenceId) {
      logger.debug('switchSequence skip (already on $sequenceId)', component: LogComponent.ui);
      return;
    }

    try {
      logger.debug('switchSequence clearing messages', component: LogComponent.ui);
      // Clear current state
      _messageDisplayManager.clearMessages();
      
      logger.debug('switchSequence load/display for $sequenceId', component: LogComponent.ui);
      // Load new sequence
      await _messageDisplayManager.loadAndDisplayMessages(
        ServiceLocator.instance.chatService,
        ServiceLocator.instance.messageQueue,
        sequenceId,
        notifyListeners,
      );
      logger.debug('switchSequence notifyListeners', component: LogComponent.ui);
      notifyListeners();
      
      logger.debug('switchSequence done -> $sequenceId', component: LogComponent.ui);
    } catch (e) {
      logger.error('❌ Error switching sequence: $e', component: LogComponent.ui);
    }
  }

  /// Debug Control: Reset current chat sequence
  Future<void> resetChat() async {
    if (_disposed) return;

    try {
      logger.debug('Resetting chat sequence: $currentSequenceId', component: LogComponent.ui);

      // Clear current state
      _messageDisplayManager.clearMessages();

      // Reload current sequence from beginning
      await _messageDisplayManager.loadAndDisplayMessages(
        ServiceLocator.instance.chatService,
        ServiceLocator.instance.messageQueue,
        currentSequenceId,
        notifyListeners,
      );

      notifyListeners();
      logger.debug('Chat reset completed', component: LogComponent.ui);
    } catch (e) {
      logger.error('Failed to reset chat: $e', component: LogComponent.ui);
    }
  }

  /// Debug Control: Clear displayed messages only
  void clearMessages() {
    if (_disposed) return;

    _messageDisplayManager.clearMessages();
    notifyListeners();
  }

  /// Debug Control: Reload current sequence from file
  Future<void> reloadSequence() async {
    if (_disposed) return;

    try {
      // Force reload sequence from JSON file
      await ServiceLocator.instance.chatService.loadSequence(
        currentSequenceId,
      );

      // Reset chat with newly loaded sequence
      await resetChat();

      logger.info('Sequence reloaded: $currentSequenceId', component: LogComponent.ui);
    } catch (e) {
      logger.error('Failed to reload sequence: $e', component: LogComponent.ui);
    }
  }

  /// Debug Control: Clear all stored user data
  Future<void> clearAllUserData() async {
    if (_disposed) return;

    try {
      // Clear all stored user variables
      await ServiceLocator.instance.userDataService.clearAllData();

      logger.info('All user data cleared', component: LogComponent.ui);
    } catch (e) {
      logger.error('Failed to clear user data: $e', component: LogComponent.ui);
    }
  }

  /// Handle events from ChatService (typing indicators, etc.)
  Future<void> _handleChatServiceEvent(String eventType, Map<String, dynamic> data) async {
    if (_disposed) return;

    logger.debug('ChatStateManager received event: $eventType with data: $data', component: LogComponent.ui);

    switch (eventType) {
      case 'show_typing_indicator':
        _messageDisplayManager.showTypingIndicator(notifyListeners,
          reason: data['reason'] ?? 'processing');
        logger.debug('Showing typing indicator: ${data['reason']}', component: LogComponent.ui);
        break;
      case 'hide_typing_indicator':
        _messageDisplayManager.hideTypingIndicator(notifyListeners,
          reason: data['reason'] ?? 'processing');
        logger.debug('Hiding typing indicator: ${data['reason']}', component: LogComponent.ui);
        break;
      default:
        logger.debug('Unhandled ChatService event: $eventType', component: LogComponent.ui);
        break;
    }
  }

  /// Dispose of resources and cancel timers
  @override
  void dispose() {
    _disposed = true;

    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose lifecycle manager debounce timers
    try {
      _lifecycleManager.dispose();
    } catch (_) {}

    // Dispose component managers (ServiceLocator disposed at app level)
    _messageDisplayManager.dispose();
    _userInteractionHandler.dispose();

    super.dispose();
  }
}
