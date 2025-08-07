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
    final List<ChatMessage> messages = [];
    int? currentId = startId;
    int walkDepth = 0;
    
    while (currentId != null && walkDepth < _maxWalkDepth) {
      walkDepth++;
      
      // Check if message exists
      if (!provider.hasMessage(currentId)) {
        return WalkResult.success(
          messages: messages,
          stopReason: WalkStopReason.endOfChain,
          walkDepth: walkDepth,
        );
      }
      
      final ChatMessage message = provider.getMessage(currentId)!;
      
      // Always collect the message first
      messages.add(message);
      
      // Stop at interactive messages - they need user input to continue
      if (message.type == MessageType.choice || message.type == MessageType.textInput) {
        return WalkResult.success(
          messages: messages,
          stopReason: WalkStopReason.interactiveMessage,
          stopMessageId: currentId,
          walkDepth: walkDepth,
        );
      }
      
      // Stop at autoroute messages - they need route processing to determine next message
      if (message.type == MessageType.autoroute) {
        return WalkResult.success(
          messages: messages,
          stopReason: WalkStopReason.endOfChain,
          stopMessageId: currentId,
          walkDepth: walkDepth,
        );
      }
      
      // Stop at sequence boundaries - they need sequence transition
      if (message.sequenceId != null) {
        return WalkResult.success(
          messages: messages,
          stopReason: WalkStopReason.sequenceBoundary,
          stopMessageId: currentId,
          targetSequenceId: message.sequenceId,
          walkDepth: walkDepth,
        );
      }
      
      // Note: dataAction messages are collected and don't stop the walk
      // autoroute messages are collected but DO stop the walk for route processing
      // The orchestrator will handle both during processing
      
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