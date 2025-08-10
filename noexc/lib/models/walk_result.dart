import 'chat_message.dart';

/// Represents why the message walker stopped walking
enum WalkStopReason {
  /// Reached an interactive message that requires user input
  interactiveMessage,

  /// Reached the end of the current message chain
  endOfChain,

  /// Encountered a sequence boundary that requires transition
  sequenceBoundary,

  /// Hit the maximum walk depth (safety mechanism)
  maxDepthReached,
}

/// Result of a message walking operation - pure navigation with no side effects
class WalkResult {
  /// Raw messages collected during the walk (unprocessed)
  final List<ChatMessage> messages;

  /// Reason why the walk stopped
  final WalkStopReason stopReason;

  /// The ID where the walk stopped (useful for continuation)
  final int? stopMessageId;

  /// Target sequence ID if stop reason is sequenceBoundary
  final String? targetSequenceId;

  /// Number of messages walked (for debugging)
  final int walkDepth;

  /// Whether this walk result is valid and successful
  bool get isValid => stopReason != WalkStopReason.maxDepthReached;

  /// Whether this result requires user interaction to continue
  bool get requiresUserInteraction =>
      stopReason == WalkStopReason.interactiveMessage;

  /// Whether this result requires a sequence transition
  bool get requiresSequenceTransition =>
      stopReason == WalkStopReason.sequenceBoundary;

  /// Whether the walk reached a natural end
  bool get reachedEnd => stopReason == WalkStopReason.endOfChain;

  const WalkResult({
    required this.messages,
    required this.stopReason,
    this.stopMessageId,
    this.targetSequenceId,
    this.walkDepth = 0,
  });

  /// Create a successful walk result
  factory WalkResult.success({
    required List<ChatMessage> messages,
    required WalkStopReason stopReason,
    int? stopMessageId,
    String? targetSequenceId,
    int walkDepth = 0,
  }) {
    return WalkResult(
      messages: messages,
      stopReason: stopReason,
      stopMessageId: stopMessageId,
      targetSequenceId: targetSequenceId,
      walkDepth: walkDepth,
    );
  }

  /// Create a walk result that hit max depth
  factory WalkResult.maxDepthReached({
    required List<ChatMessage> messages,
    required int walkDepth,
  }) {
    return WalkResult(
      messages: messages,
      stopReason: WalkStopReason.maxDepthReached,
      walkDepth: walkDepth,
    );
  }

  @override
  String toString() {
    return 'WalkResult(messages: ${messages.length}, stopReason: $stopReason, '
        'stopMessageId: $stopMessageId, targetSequenceId: $targetSequenceId, '
        'walkDepth: $walkDepth)';
  }
}
