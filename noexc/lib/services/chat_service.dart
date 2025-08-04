import '../models/chat_message.dart';
import '../models/chat_sequence.dart';
import '../models/choice.dart';
import 'user_data_service.dart';
import 'text_templating_service.dart';
import 'text_variants_service.dart';
import 'condition_evaluator.dart';
import 'data_action_processor.dart';
import 'session_service.dart';
import 'chat_service/sequence_loader.dart';
import 'chat_service/message_processor.dart';
import 'chat_service/route_processor.dart';
import 'flow/message_walker.dart';
import 'flow/message_renderer.dart';
import 'flow/flow_orchestrator.dart';
import 'flow/sequence_manager.dart';
import 'logger_service.dart';
import 'service_locator.dart';

/// Main chat service that orchestrates sequence loading, message processing, and routing
class ChatService {
  late final MessageProcessor _messageProcessor;
  late final RouteProcessor _routeProcessor;
  late final SequenceManager _sequenceManager;
  late final MessageWalker _messageWalker;
  late final MessageRenderer _messageRenderer;
  late final FlowOrchestrator _flowOrchestrator;
  final logger = LoggerService.instance;
  
  // Callback for notifying UI about events from dataAction triggers
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  ChatService({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
    TextVariantsService? variantsService,
    SessionService? sessionService,
  }) {
    // Initialize sequence management first (single source of truth)
    final sequenceLoader = SequenceLoader();
    _sequenceManager = SequenceManager(sequenceLoader: sequenceLoader);
    
    _messageProcessor = MessageProcessor(
      userDataService: userDataService,
      templatingService: templatingService,
      variantsService: variantsService,
    );
    
    _routeProcessor = RouteProcessor(
      conditionEvaluator: userDataService != null 
          ? ConditionEvaluator(userDataService) 
          : null,
      dataActionProcessor: userDataService != null 
          ? DataActionProcessor(userDataService, sessionService: sessionService) 
          : null,
      sequenceManager: _sequenceManager,
    );
    
    // Initialize clean architecture components
    _messageWalker = MessageWalker();
    _messageRenderer = MessageRenderer(messageProcessor: _messageProcessor);
    _flowOrchestrator = FlowOrchestrator(
      walker: _messageWalker,
      renderer: _messageRenderer,
      sequenceManager: _sequenceManager,
      routeProcessor: _routeProcessor,
    );
    
    // Set up event callback for dataActionProcessor
    if (_routeProcessor.dataActionProcessor != null) {
      _routeProcessor.dataActionProcessor!.setEventCallback(_handleEvent);
    }
  }


  /// Set callback for event notifications from dataAction triggers
  void setEventCallback(Future<void> Function(String eventType, Map<String, dynamic> data) callback) {
    _onEvent = callback;
  }

  /// Handle events from dataActionProcessor
  Future<void> _handleEvent(String eventType, Map<String, dynamic> data) async {
    // Handle specific event types
    switch (eventType) {
      case 'recalculate_active_day':
        await _handleRecalculateActiveDay();
        break;
      case 'recalculate_past_deadline':
        await _handleRecalculatePastDeadline();
        break;
      default:
        // Forward unknown events to UI callback
        if (_onEvent != null) {
          try {
            await _onEvent!(eventType, data);
          } catch (e) {
            // Silent error handling
          }
        }
    }
  }

  /// Handle recalculate_active_day event from dataAction trigger
  Future<void> _handleRecalculateActiveDay() async {
    try {
      final userDataService = ServiceLocator.instance.userDataService;
      final sessionService = SessionService(userDataService);
      await sessionService.recalculateActiveDay();
      logger.info('Successfully recalculated task.isActiveDay');
    } catch (e) {
      logger.error('Failed to recalculate active day: $e');
    }
  }

  /// Handle recalculate_past_deadline event from dataAction trigger
  Future<void> _handleRecalculatePastDeadline() async {
    try {
      final userDataService = ServiceLocator.instance.userDataService;
      final sessionService = SessionService(userDataService);
      await sessionService.recalculatePastDeadline();
      logger.info('Successfully recalculated task.isPastDeadline');
    } catch (e) {
      logger.error('Failed to recalculate past deadline: $e');
    }
  }

  /// Load a specific chat sequence by ID
  Future<ChatSequence> loadSequence(String sequenceId) async {
    await _sequenceManager.loadSequence(sequenceId);
    return _sequenceManager.currentSequence!;
  }

  /// Load the default chat script (for backward compatibility)
  Future<List<ChatMessage>> loadChatScript() async {
    // Use SequenceManager instead of SequenceLoader directly
    await _sequenceManager.loadSequence('onboarding_seq');
    return _sequenceManager.currentSequence!.messages;
  }

  bool hasMessage(int id) {
    return _sequenceManager.hasMessage(id);
  }

  ChatMessage? getMessageById(int id) {
    return _sequenceManager.getMessage(id);
  }

  /// Get initial messages for a specific sequence
  Future<List<ChatMessage>> getInitialMessages({String sequenceId = 'onboarding_seq'}) async {
    if (_sequenceManager.currentSequenceId != sequenceId) {
      await loadSequence(sequenceId);
    }
    
    // Start with the first message in the sequence
    final firstMessageId = _sequenceManager.getFirstMessageId();
    if (firstMessageId == null) {
      throw Exception('Sequence $sequenceId has no messages');
    }
    
    return await _getMessagesFromId(firstMessageId);
  }

  /// Get the current loaded sequence
  ChatSequence? get currentSequence => _sequenceManager.currentSequence;

  Future<List<ChatMessage>> getMessagesAfterChoice(int startId) async {
    return await _getMessagesFromId(startId);
  }

  Future<List<ChatMessage>> getMessagesAfterTextInput(int nextMessageId, String userInput) async {
    return await _getMessagesFromId(nextMessageId);
  }

  ChatMessage createUserResponseMessage(int id, String userInput) {
    // Move user message creation logic here instead of delegating to SequenceLoader
    return ChatMessage(
      id: id,
      text: userInput,
      delay: 0,
      sender: 'user',
      type: MessageType.user,
    );
  }

  /// Handle user text input and store it if storeKey is provided
  Future<void> handleUserTextInput(ChatMessage textInputMessage, String userInput) async {
    // Use FlowOrchestrator for consistent processing
    await _flowOrchestrator.handleUserTextInput(textInputMessage, userInput);
  }

  /// Handle user choice selection and store it if storeKey is provided
  Future<void> handleUserChoice(ChatMessage choiceMessage, Choice selectedChoice) async {
    // Use FlowOrchestrator for consistent processing
    await _flowOrchestrator.handleUserChoice(choiceMessage, selectedChoice);
  }

  /// Process a single message template and replace variables with stored values
  Future<ChatMessage> processMessageTemplate(ChatMessage message) async {
    // Use FlowOrchestrator for consistent processing
    return await _flowOrchestrator.processMessageTemplate(message);
  }

  /// Process a list of messages and replace template variables
  Future<List<ChatMessage>> processMessageTemplates(List<ChatMessage> messages) async {
    // Use FlowOrchestrator for consistent processing
    return await _flowOrchestrator.processMessageTemplates(messages);
  }

  Future<List<ChatMessage>> _getMessagesFromId(int startId) async {
    logger.info('Processing messages from ID: $startId');
    
    final flowResponse = await _flowOrchestrator.processFrom(startId);
    return flowResponse.messages;
  }

}