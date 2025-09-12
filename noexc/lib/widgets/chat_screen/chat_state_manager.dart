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
    // Services are already initialized at app level via ServiceLocator

    // Initialize component managers
    _messageDisplayManager = MessageDisplayManager();
    _userInteractionHandler = UserInteractionHandler(
      messageDisplayManager: _messageDisplayManager,
      chatService: ServiceLocator.instance.chatService,
      messageQueue: ServiceLocator.instance.messageQueue,
    );

    // Initialize lifecycle manager
    _lifecycleManager = AppLifecycleManager(
      sessionService: ServiceLocator.instance.sessionService,
      onAppResumedFromEndState: _handleAppResumedFromEndState,
    );

    // Keep UI sequence in sync with engine transitions
    ServiceLocator.instance.chatService.setOnSequenceChanged((seqId) {
      logger.debug('Sequence changed (engine) → $seqId', component: LogComponent.ui);
      notifyListeners();
    });

    // Register as lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    await _messageDisplayManager.loadAndDisplayMessages(
      ServiceLocator.instance.chatService,
      ServiceLocator.instance.messageQueue,
      AppConstants.defaultSequenceId,
      notifyListeners,
    );
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
    try {
      // Essential log only
      logger.info('resume_reengage_handling', component: LogComponent.ui);
      final defaultSeq = AppConstants.defaultSequenceId;
      final activeSeq = ServiceLocator.instance.chatService.currentSequence?.sequenceId;
      logger.debug('active_seq=${activeSeq ?? 'none'} ui_seq=$currentSequenceId', component: LogComponent.ui);

      // Busy guard via policy (existing guards only)
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
      if (!canReengage) {
        logger.info('reengage_skipped busy input=$hasTextInput choice=$hasUnansweredChoice panel=$panelOpen', component: LogComponent.ui);
        return;
      }

      // Append mode: start default sequence and append its messages without clearing
      logger.info('reengage_target append sequence=$defaultSeq', component: LogComponent.ui);
      final flow = await ServiceLocator.instance.chatService.start(defaultSeq);
      await _messageDisplayManager.displayMessages(
        flow.messages,
        ServiceLocator.instance.messageQueue,
        notifyListeners,
      );

      logger.info('reengage_completed seq=$currentSequenceId', component: LogComponent.ui);
    } catch (e) {
      logger.error('reengage_failed error=$e', component: LogComponent.ui);
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
