import '../../models/chat_message.dart';
import '../../models/traversal_result.dart';
import '../chat_service/sequence_loader.dart';
import '../logger_service.dart';

/// Pure traversal logic for message flow navigation
/// 
/// This class handles the core logic of moving from message to message
/// without any side effects (no template processing, no sequence loading).
/// It returns a traversal result indicating what messages were found
/// and why traversal stopped.
class FlowTraverser {
  static const int _maxTraversalDepth = 100;
  final logger = LoggerService.instance;

  /// Traverse messages starting from the given ID
  /// 
  /// This is a pure function that:
  /// 1. Follows message navigation rules (nextMessageId, sequential IDs)
  /// 2. Stops at interactive messages (choice, textInput)
  /// 3. Stops at sequence boundaries
  /// 4. Collects raw messages without processing
  /// 
  /// Returns [TraversalResult] indicating messages found and stop reason.
  TraversalResult traverse(int startId, SequenceLoader sequenceLoader) {
    logger.info('Starting traversal from message ID: $startId');
    
    final List<ChatMessage> messages = [];
    int? currentId = startId;
    int depth = 0;
    
    while (currentId != null && depth < _maxTraversalDepth) {
      depth++;
      
      // Safety check - ensure message exists
      if (!sequenceLoader.hasMessage(currentId)) {
        logger.info('Message $currentId not found, ending traversal');
        return TraversalResult.success(
          messages: messages,
          stopReason: TraversalStopReason.endOfSequence,
        );
      }
      
      final ChatMessage message = sequenceLoader.getMessageById(currentId)!;
      logger.debug('Processing message ${message.id} of type ${message.type}');
      
      // Handle auto-route messages - skip display but don't traverse their routes
      if (message.isAutoRoute) {
        logger.debug('Encountered autoroute message ${message.id}');
        messages.add(message);
        
        // Let the route processor handle this later - we just note it exists
        return TraversalResult.success(
          messages: messages,
          stopReason: TraversalStopReason.interactiveMessage,
          nextMessageId: currentId,
        );
      }
      
      // Handle data action messages - skip display but note them
      if (message.isDataAction) {
        logger.debug('Encountered dataAction message ${message.id}');
        messages.add(message);
        
        // Continue to next message after data action
        currentId = _getNext(message, currentId);
        continue;
      }
      
      // Check for sequence transition
      if (message.sequenceId != null) {
        logger.info('Sequence transition required to: ${message.sequenceId}');
        messages.add(message);
        
        return TraversalResult.success(
          messages: messages,
          stopReason: TraversalStopReason.sequenceTransition,
          targetSequenceId: message.sequenceId,
        );
      }
      
      // Add regular messages to result
      messages.add(message);
      
      // Stop at interactive messages that require user input
      if (message.isChoice || message.isTextInput) {
        logger.info('Stopping at interactive message ${message.id} of type ${message.type}');
        return TraversalResult.success(
          messages: messages,
          stopReason: TraversalStopReason.interactiveMessage,
          nextMessageId: currentId,
        );
      }
      
      // Move to next message
      currentId = _getNext(message, currentId);
    }
    
    // Check if we hit max depth (safety check)
    if (depth >= _maxTraversalDepth) {
      logger.warning('Maximum traversal depth reached ($depth messages)');
      return TraversalResult.error(
        errorMessage: 'Maximum traversal depth reached',
        messages: messages,
      );
    }
    
    // Natural end of sequence
    logger.info('Reached end of sequence after processing ${messages.length} messages');
    return TraversalResult.success(
      messages: messages,
      stopReason: TraversalStopReason.endOfSequence,
    );
  }

  /// Get the next message ID based on message navigation rules
  int? _getNext(ChatMessage message, int currentId) {
    // Explicit next message ID takes precedence
    if (message.nextMessageId != null) {
      return message.nextMessageId;
    }
    
    // Fallback to sequential ID
    return currentId + 1;
  }
}