import '../../models/chat_message.dart';
import '../../models/walk_result.dart';
import '../logger_service.dart';

/// Interface for message storage access (to keep MessageWalker pure)
abstract class MessageProvider {
  bool hasMessage(int id);
  ChatMessage? getMessage(int id);
}

/// Pure message navigation component
/// 
/// SINGLE RESPONSIBILITY: Walk through message chains until a natural stop point
/// 
/// This component:
/// - DOES: Navigate message chains, detect stop conditions, collect raw messages
/// - DOES NOT: Process templates, handle sequences, modify state, make async calls
/// 
/// Pure function principles:
/// - Same input always produces same output
/// - No side effects
/// - No external dependencies except for message data access
class MessageWalker {
  static const int _maxWalkDepth = 50;
  final logger = LoggerService.instance;

  /// Walk messages starting from the given ID
  /// 
  /// Returns a WalkResult containing:
  /// - Raw messages collected during walk
  /// - Reason why walking stopped
  /// - Information needed for continuation
  /// 
  /// Stop conditions:
  /// 1. Interactive message (choice/textInput) - requires user input
  /// 2. Sequence boundary (message has sequenceId) - requires sequence transition
  /// 3. End of chain (no next message available) - natural end
  /// 4. Max depth reached - safety mechanism
  WalkResult walkFrom(int startId, MessageProvider provider) {
    logger.debug('Starting walk from message ID: $startId');
    
    final List<ChatMessage> messages = [];
    int? currentId = startId;
    int walkDepth = 0;
    
    while (currentId != null && walkDepth < _maxWalkDepth) {
      walkDepth++;
      
      // Check if message exists
      if (!provider.hasMessage(currentId)) {
        logger.debug('Message $currentId not found, ending walk');
        return WalkResult.success(
          messages: messages,
          stopReason: WalkStopReason.endOfChain,
          walkDepth: walkDepth,
        );
      }
      
      final ChatMessage message = provider.getMessage(currentId)!;
      logger.debug('Walking message ${message.id} of type ${message.type}');
      
      // Always collect the message first
      messages.add(message);
      
      // Stop at interactive messages - they need user input to continue
      if (message.isChoice || message.isTextInput) {
        logger.debug('Stopped at interactive message ${message.id}');
        return WalkResult.success(
          messages: messages,
          stopReason: WalkStopReason.interactiveMessage,
          stopMessageId: currentId,
          walkDepth: walkDepth,
        );
      }
      
      // Stop at sequence boundaries - they need sequence transition
      if (message.sequenceId != null) {
        logger.debug('Stopped at sequence boundary, target: ${message.sequenceId}');
        return WalkResult.success(
          messages: messages,
          stopReason: WalkStopReason.sequenceBoundary,
          stopMessageId: currentId,
          targetSequenceId: message.sequenceId,
          walkDepth: walkDepth,
        );
      }
      
      // Note: autoroute and dataAction messages are collected but don't stop the walk
      // The orchestrator will handle them during processing
      
      // Move to next message
      currentId = _getNextMessageId(message, currentId);
    }
    
    // Safety check - hit max depth
    if (walkDepth >= _maxWalkDepth) {
      logger.warning('Walk hit maximum depth of $walkDepth messages');
      return WalkResult.maxDepthReached(
        messages: messages,
        walkDepth: walkDepth,
      );
    }
    
    // Natural end of chain
    logger.debug('Walk completed naturally after $walkDepth steps');
    return WalkResult.success(
      messages: messages,
      stopReason: WalkStopReason.endOfChain,
      walkDepth: walkDepth,
    );
  }

  /// Determine the next message ID based on message navigation rules
  int? _getNextMessageId(ChatMessage message, int currentId) {
    // Explicit nextMessageId takes precedence
    if (message.nextMessageId != null) {
      return message.nextMessageId;
    }
    
    // Fallback to sequential ID (currentId + 1)
    // Note: The provider will check if this message exists
    return currentId + 1;
  }
}