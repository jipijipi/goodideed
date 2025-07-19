import '../models/chat_message.dart';
import '../models/chat_sequence.dart';
import '../models/choice.dart';
import '../config/chat_config.dart';
import 'user_data_service.dart';
import 'text_templating_service.dart';
import 'text_variants_service.dart';
import 'condition_evaluator.dart';
import 'data_action_processor.dart';
import 'chat_service/sequence_loader.dart';
import 'chat_service/message_processor.dart';
import 'chat_service/route_processor.dart';

/// Main chat service that orchestrates sequence loading, message processing, and routing
class ChatService {
  final SequenceLoader _sequenceLoader = SequenceLoader();
  late final MessageProcessor _messageProcessor;
  late final RouteProcessor _routeProcessor;
  final UserDataService? _userDataService;
  
  // Callback for notifying UI about sequence changes from autoroutes
  Future<void> Function(String sequenceId, int startMessageId)? _onSequenceSwitch;
  
  // Callback for notifying UI about events from dataAction triggers
  Future<void> Function(String eventType, Map<String, dynamic> data)? _onEvent;

  ChatService({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
    TextVariantsService? variantsService,
  }) : _userDataService = userDataService {
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
          ? DataActionProcessor(userDataService) 
          : null,
      sequenceLoader: _sequenceLoader,
    );
    
    // Set up event callback for dataActionProcessor
    if (_routeProcessor.dataActionProcessor != null) {
      _routeProcessor.dataActionProcessor!.setEventCallback(_handleEvent);
    }
  }

  /// Set callback for sequence switching notifications
  void setSequenceSwitchCallback(Future<void> Function(String sequenceId, int startMessageId) callback) {
    _onSequenceSwitch = callback;
  }

  /// Set callback for event notifications from dataAction triggers
  void setEventCallback(Future<void> Function(String eventType, Map<String, dynamic> data) callback) {
    _onEvent = callback;
  }

  /// Handle events from dataActionProcessor
  Future<void> _handleEvent(String eventType, Map<String, dynamic> data) async {
    if (_onEvent != null) {
      try {
        await _onEvent!(eventType, data);
      } catch (e) {
        // Silent error handling
      }
    }
  }

  /// Load a specific chat sequence by ID
  Future<ChatSequence> loadSequence(String sequenceId) async {
    return await _sequenceLoader.loadSequence(sequenceId);
  }

  /// Load the default chat script (for backward compatibility)
  Future<List<ChatMessage>> loadChatScript() async {
    return await _sequenceLoader.loadChatScript();
  }

  bool hasMessage(int id) {
    return _sequenceLoader.hasMessage(id);
  }

  ChatMessage? getMessageById(int id) {
    return _sequenceLoader.getMessageById(id);
  }

  /// Get initial messages for a specific sequence
  Future<List<ChatMessage>> getInitialMessages({String sequenceId = 'onboarding_seq'}) async {
    if (_sequenceLoader.currentSequence == null || _sequenceLoader.currentSequence!.sequenceId != sequenceId) {
      await loadSequence(sequenceId);
    }
    
    return await _getMessagesFromId(ChatConfig.initialMessageId);
  }

  /// Get the current loaded sequence
  ChatSequence? get currentSequence => _sequenceLoader.currentSequence;

  Future<List<ChatMessage>> getMessagesAfterChoice(int startId) async {
    return await _getMessagesFromId(startId);
  }

  Future<List<ChatMessage>> getMessagesAfterTextInput(int nextMessageId, String userInput) async {
    return await _getMessagesFromId(nextMessageId);
  }

  ChatMessage createUserResponseMessage(int id, String userInput) {
    return _sequenceLoader.createUserResponseMessage(id, userInput);
  }

  /// Handle user text input and store it if storeKey is provided
  Future<void> handleUserTextInput(ChatMessage textInputMessage, String userInput) async {
    await _messageProcessor.handleUserTextInput(textInputMessage, userInput);
  }

  /// Handle user choice selection and store it if storeKey is provided
  Future<void> handleUserChoice(ChatMessage choiceMessage, Choice selectedChoice) async {
    await _messageProcessor.handleUserChoice(choiceMessage, selectedChoice);
  }

  /// Process a single message template and replace variables with stored values
  Future<ChatMessage> processMessageTemplate(ChatMessage message) async {
    return await _messageProcessor.processMessageTemplate(message, _sequenceLoader.currentSequence);
  }

  /// Process a list of messages and replace template variables
  Future<List<ChatMessage>> processMessageTemplates(List<ChatMessage> messages) async {
    return await _messageProcessor.processMessageTemplates(messages, _sequenceLoader.currentSequence);
  }

  Future<List<ChatMessage>> _getMessagesFromId(int startId) async {
    List<ChatMessage> messages = [];
    int? currentId = startId;
    
    while (currentId != null && _sequenceLoader.hasMessage(currentId)) {
      ChatMessage msg = _sequenceLoader.getMessageById(currentId)!;
      
      // Handle autoroute messages
      if (msg.isAutoRoute) {
        currentId = await _routeProcessor.processAutoRoute(msg);
        continue; // Skip adding to display
      }
      
      // Handle dataAction messages
      if (msg.isDataAction) {
        currentId = await _routeProcessor.processDataAction(msg);
        continue; // Skip adding to display
      }
      
      // Process template and variants on the original message first
      final processedMsg = await processMessageTemplate(msg);
      
      // Expand multi-text messages into individual messages
      final expandedMessages = processedMsg.expandToIndividualMessages();
      messages.addAll(expandedMessages);
      
      // Stop at choice messages or text input messages - let UI handle the interaction
      if (msg.isChoice || msg.isTextInput) break;
      
      // Check for universal cross-sequence navigation
      if (msg.sequenceId != null) {
        final startMessageId = ChatConfig.initialMessageId;
        
        // Always load sequence directly and continue processing
        await loadSequence(msg.sequenceId!);
        currentId = startMessageId;
        
        continue;
      }
      
      // Move to next message
      if (msg.nextMessageId != null) {
        currentId = msg.nextMessageId;
      } else {
        // If no explicit next message, try sequential ID
        currentId = currentId + 1;
        if (!_sequenceLoader.hasMessage(currentId)) {
          break;
        }
      }
    }
    
    return messages;
  }
}