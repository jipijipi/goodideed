import '../../models/chat_message.dart';
import '../../models/choice.dart';
import '../chat_service/route_processor.dart';
import '../logger_service.dart';
import 'message_walker.dart';
import 'message_renderer.dart';
import 'sequence_manager.dart';

/// Result of flow processing
class FlowResponse {
  /// Processed messages ready for display
  final List<ChatMessage> messages;
  
  /// Whether the flow requires user interaction to continue
  final bool requiresUserInteraction;
  
  /// Message ID where user interaction occurred (for continuation)
  final int? interactionMessageId;
  
  /// Whether the flow completed naturally
  final bool isComplete;

  const FlowResponse({
    required this.messages,
    this.requiresUserInteraction = false,
    this.interactionMessageId,
    this.isComplete = false,
  });

  factory FlowResponse.withMessages(List<ChatMessage> messages) {
    return FlowResponse(
      messages: messages,
      isComplete: true,
    );
  }

  factory FlowResponse.awaitingInteraction({
    required List<ChatMessage> messages,
    required int interactionMessageId,
  }) {
    return FlowResponse(
      messages: messages,
      requiresUserInteraction: true,
      interactionMessageId: interactionMessageId,
    );
  }
}

/// Orchestrator that coordinates message flow without recursion
/// 
/// SINGLE RESPONSIBILITY: Coordinate between walker, renderer, and sequence manager
/// 
/// This component:
/// - DOES: Coordinate components, handle autoroutes/dataActions sequentially, manage flow state
/// - DOES NOT: Walk messages, process templates, manage sequences directly
/// 
/// Architecture principles:
/// - No recursion - all operations are sequential
/// - Clear state management with explicit phases
/// - Delegate to specialized components
class FlowOrchestrator {
  final MessageWalker _walker;
  final MessageRenderer _renderer;
  final SequenceManager _sequenceManager;
  final RouteProcessor _routeProcessor;
  final logger = LoggerService.instance;
  
  static const int _maxProcessingCycles = 25;

  FlowOrchestrator({
    required MessageWalker walker,
    required MessageRenderer renderer,
    required SequenceManager sequenceManager,
    required RouteProcessor routeProcessor,
  }) : _walker = walker,
       _renderer = renderer,
       _sequenceManager = sequenceManager,
       _routeProcessor = routeProcessor;

  /// Process flow starting from the given message ID
  /// 
  /// This method coordinates the entire flow processing:
  /// 1. Walk messages until natural stop
  /// 2. Handle autoroutes and data actions sequentially (no recursion)
  /// 3. Handle sequence transitions
  /// 4. Render messages for display
  /// 5. Return result with continuation information
  Future<FlowResponse> processFrom(int startId) async {
    logger.info('Starting flow processing from message ID: $startId');
    
    int currentStartId = startId;
    int processingCycles = 0;
    final List<ChatMessage> allDisplayMessages = [];
    
    // Sequential processing loop (replaces recursion)
    while (processingCycles < _maxProcessingCycles) {
      processingCycles++;
      logger.debug('Processing cycle $processingCycles, starting from: $currentStartId');
      
      // Phase 1: Walk messages
      final walkResult = _walker.walkFrom(currentStartId, _sequenceManager);
      logger.debug('Walk completed: $walkResult');
      
      if (!walkResult.isValid) {
        throw Exception('Walk failed: hit maximum depth');
      }
      
      // Phase 2: Handle special messages sequentially
      final ProcessingResult processingResult = await _processSpecialMessages(walkResult.messages);
      
      // If we have messages to display, add them to our collection
      if (processingResult.displayMessages.isNotEmpty) {
        allDisplayMessages.addAll(processingResult.displayMessages);
      }
      
      // Phase 3: Handle continuation based on walk result
      if (walkResult.requiresUserInteraction) {
        logger.info('Flow requires user interaction at message ${walkResult.stopMessageId}');
        
        // Render all collected messages and return for user interaction
        final renderedMessages = await _renderer.render(
          allDisplayMessages,
          _sequenceManager.currentSequence,
        );
        
        return FlowResponse.awaitingInteraction(
          messages: renderedMessages,
          interactionMessageId: walkResult.stopMessageId!,
        );
      }
      
      if (walkResult.requiresSequenceTransition) {
        logger.info('Flow requires sequence transition to: ${walkResult.targetSequenceId}');
        
        // Load new sequence and continue processing
        await _sequenceManager.loadSequence(walkResult.targetSequenceId!);
        
        // Start with the first message in the new sequence
        final firstMessageId = _sequenceManager.getFirstMessageId();
        if (firstMessageId == null) {
          throw Exception('New sequence ${walkResult.targetSequenceId} has no messages');
        }
        currentStartId = firstMessageId;
        logger.debug('Starting new sequence with first message ID: $currentStartId');
        continue; // Continue in new sequence
      }
      
      if (processingResult.continueFromId != null) {
        logger.debug('Continuing processing from message: ${processingResult.continueFromId}');
        currentStartId = processingResult.continueFromId!;
        continue; // Continue processing
      }
      
      // Natural end - no more processing needed
      logger.info('Flow processing completed naturally');
      break;
    }
    
    if (processingCycles >= _maxProcessingCycles) {
      logger.warning('Flow processing hit maximum cycles limit');
    }
    
    // Render all collected messages
    final renderedMessages = await _renderer.render(
      allDisplayMessages,
      _sequenceManager.currentSequence,
    );
    
    return FlowResponse.withMessages(renderedMessages);
  }

  /// Process special messages (autoroutes and data actions) sequentially
  Future<ProcessingResult> _processSpecialMessages(List<ChatMessage> messages) async {
    final List<ChatMessage> displayMessages = [];
    int? continueFromId;
    
    for (final message in messages) {
      if (message.type == MessageType.autoroute) {
        logger.debug('Processing autoroute message ${message.id}');
        continueFromId = await _routeProcessor.processAutoRoute(message);
        // Don't add autoroute messages to display
        continue;
      }
      
      if (message.type == MessageType.dataAction) {
        logger.debug('Processing dataAction message ${message.id}');
        await _routeProcessor.processDataAction(message);
        // Don't add dataAction messages to display
        continue;
      }
      
      // Regular message - add to display
      displayMessages.add(message);
    }
    
    return ProcessingResult(
      displayMessages: displayMessages,
      continueFromId: continueFromId,
    );
  }

  /// Process a single message template (legacy support)
  /// 
  /// This method provides backward compatibility for components that need
  /// to process individual messages rather than message flows.
  Future<ChatMessage> processMessageTemplate(ChatMessage message) async {
    logger.debug('Processing single message template: ${message.id}');
    
    // Use the renderer to process the message
    final processedMessages = await _renderer.render([message], _sequenceManager.currentSequence);
    
    if (processedMessages.isEmpty) {
      throw Exception('Message processing failed for message ${message.id}');
    }
    
    return processedMessages.first;
  }

  /// Process a list of message templates (legacy support)
  /// 
  /// This method provides backward compatibility for components that need
  /// to process multiple individual messages rather than message flows.
  Future<List<ChatMessage>> processMessageTemplates(List<ChatMessage> messages) async {
    logger.debug('Processing ${messages.length} message templates');
    
    // Use the renderer to process all messages
    return await _renderer.render(messages, _sequenceManager.currentSequence);
  }

  /// Handle user text input and store it if storeKey is provided (legacy support)
  /// 
  /// This method provides backward compatibility for components that need
  /// to handle user text input without going through the full flow.
  Future<void> handleUserTextInput(ChatMessage textInputMessage, String userInput) async {
    logger.debug('Handling user text input for message: ${textInputMessage.id}');
    
    // Delegate to the renderer for consistent processing
    await _renderer.handleUserTextInput(textInputMessage, userInput);
  }

  /// Handle user choice selection and store it if storeKey is provided (legacy support)
  /// 
  /// This method provides backward compatibility for components that need
  /// to handle user choice selection without going through the full flow.
  Future<void> handleUserChoice(ChatMessage choiceMessage, Choice selectedChoice) async {
    logger.debug('Handling user choice for message: ${choiceMessage.id}');
    
    // Delegate to the renderer for consistent processing
    await _renderer.handleUserChoice(choiceMessage, selectedChoice);
  }
}

/// Internal result of processing special messages
class ProcessingResult {
  final List<ChatMessage> displayMessages;
  final int? continueFromId;
  
  const ProcessingResult({
    required this.displayMessages,
    this.continueFromId,
  });
}