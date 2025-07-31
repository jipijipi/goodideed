import '../../models/chat_message.dart';
import '../../config/chat_config.dart';
import '../chat_service/sequence_loader.dart';
import '../chat_service/message_processor.dart';
import '../chat_service/route_processor.dart';
import '../logger_service.dart';
import 'flow_traverser.dart';
import 'sequence_transition_manager.dart';

/// Represents the current state of flow processing
enum FlowState {
  /// No processing active
  idle,
  
  /// Currently traversing messages
  traversing,
  
  /// Processing autoroutes and data actions
  processingRoutes,
  
  /// Processing message templates and variants
  processingMessages,
  
  /// Transitioning between sequences
  transitioningSequence,
  
  /// Waiting for user input
  awaitingInput,
  
  /// Error state - recovery needed
  error,
}

/// State machine that orchestrates the message flow processing
/// 
/// This class coordinates between:
/// - FlowTraverser (pure navigation)
/// - RouteProcessor (autoroutes/data actions)
/// - MessageProcessor (templates/variants)
/// - SequenceTransitionManager (sequence changes)
class FlowStateMachine {
  final SequenceLoader _sequenceLoader;
  final MessageProcessor _messageProcessor;
  final RouteProcessor _routeProcessor;
  final FlowTraverser _flowTraverser;
  final SequenceTransitionManager _sequenceTransitionManager;
  final logger = LoggerService.instance;
  
  FlowState _currentState = FlowState.idle;
  
  FlowState get currentState => _currentState;
  
  FlowStateMachine({
    required SequenceLoader sequenceLoader,
    required MessageProcessor messageProcessor,
    required RouteProcessor routeProcessor,
  }) : _sequenceLoader = sequenceLoader,
       _messageProcessor = messageProcessor,
       _routeProcessor = routeProcessor,
       _flowTraverser = FlowTraverser(),
       _sequenceTransitionManager = SequenceTransitionManager(sequenceLoader);

  /// Process flow starting from given message ID
  /// 
  /// This is the main entry point that orchestrates the entire flow processing:
  /// 1. Traverse messages to find what needs processing
  /// 2. Handle any routes or data actions
  /// 3. Process templates and variants
  /// 4. Handle sequence transitions if needed
  /// 5. Return processed messages ready for display
  Future<List<ChatMessage>> processFlow(int startId) async {
    if (_currentState != FlowState.idle) {
      logger.warning('Flow processing already in progress, state: $_currentState');
      return [];
    }
    
    try {
      return await _processFlowInternal(startId);
    } catch (e, stackTrace) {
      logger.error('Flow processing failed: $e');
      logger.debug('Stack trace: $stackTrace');
      await _setState(FlowState.error);
      rethrow;
    } finally {
      await _setState(FlowState.idle);
    }
  }

  Future<List<ChatMessage>> _processFlowInternal(int startId) async {
    logger.info('Starting flow processing from message ID: $startId');
    
    // Phase 1: Traverse messages
    await _setState(FlowState.traversing);
    final traversalResult = _flowTraverser.traverse(startId, _sequenceLoader);
    
    logger.info('Traversal completed: $traversalResult');
    
    if (!traversalResult.isSuccess) {
      throw Exception('Traversal failed: ${traversalResult.errorMessage}');
    }
    
    // Phase 2: Handle sequence transitions if needed
    if (traversalResult.requiresSequenceTransition) {
      await _setState(FlowState.transitioningSequence);
      await _sequenceTransitionManager.transitionToSequence(
        traversalResult.targetSequenceId!
      );
      
      // Continue processing from the new sequence
      return await _processFlowInternal(ChatConfig.initialMessageId);
    }
    
    // Phase 3: Process routes and data actions
    final processedMessages = <ChatMessage>[];
    await _setState(FlowState.processingRoutes);
    
    for (final message in traversalResult.messages) {
      if (message.isAutoRoute) {
        // Process the autoroute to get next message ID
        final nextId = await _routeProcessor.processAutoRoute(message);
        if (nextId != null) {
          // Continue processing from the routed message
          final continuedMessages = await _processFlowInternal(nextId);
          processedMessages.addAll(continuedMessages);
        }
        // Skip adding autoroute messages to display
        continue;
      }
      
      if (message.isDataAction) {
        // Process data actions
        await _routeProcessor.processDataAction(message);
        // Skip adding dataAction messages to display
        continue;
      }
      
      // Add regular messages for template processing
      processedMessages.add(message);
    }
    
    // Phase 4: Process message templates and variants
    await _setState(FlowState.processingMessages);
    final templatedMessages = await _messageProcessor.processMessageTemplates(
      processedMessages, 
      _sequenceLoader.currentSequence
    );
    
    // Phase 5: Expand multi-text messages
    final expandedMessages = <ChatMessage>[];
    for (final message in templatedMessages) {
      expandedMessages.addAll(message.expandToIndividualMessages());
    }
    
    // Phase 6: Check if we're waiting for user input
    if (traversalResult.hasUserInteraction) {
      await _setState(FlowState.awaitingInput);
    }
    
    logger.info('Flow processing completed, returning ${expandedMessages.length} messages');
    return expandedMessages;
  }

  /// Transition to a new state with logging
  Future<void> _setState(FlowState newState) async {
    if (_currentState != newState) {
      logger.debug('Flow state transition: $_currentState → $newState');
      _currentState = newState;
    }
  }

  /// Reset state machine to idle (useful for error recovery)
  Future<void> reset() async {
    logger.info('Resetting flow state machine');
    await _setState(FlowState.idle);
  }
}