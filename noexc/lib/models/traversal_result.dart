import 'chat_message.dart';

/// Represents the possible reasons why message traversal stopped
enum TraversalStopReason {
  /// Reached an interactive message (choice or textInput)
  interactiveMessage,
  
  /// Reached end of sequence (no more messages)
  endOfSequence,
  
  /// Need to transition to another sequence
  sequenceTransition,
  
  /// Encountered an error during traversal
  error,
  
  /// Hit maximum traversal limit (safety check)
  maxDepthReached,
}

/// Result of a message traversal operation
class TraversalResult {
  /// Messages collected during traversal (raw, unprocessed)
  final List<ChatMessage> messages;
  
  /// Reason why traversal stopped
  final TraversalStopReason stopReason;
  
  /// Next message ID to continue from (if applicable)
  final int? nextMessageId;
  
  /// Target sequence ID for transition (if stopReason is sequenceTransition)
  final String? targetSequenceId;
  
  /// Error message (if stopReason is error)
  final String? errorMessage;
  
  /// Whether this result indicates a successful traversal
  bool get isSuccess => stopReason != TraversalStopReason.error;
  
  /// Whether this result requires sequence transition
  bool get requiresSequenceTransition => stopReason == TraversalStopReason.sequenceTransition;
  
  /// Whether this result contains interactive messages that require user input
  bool get hasUserInteraction => stopReason == TraversalStopReason.interactiveMessage;

  const TraversalResult({
    required this.messages,
    required this.stopReason,
    this.nextMessageId,
    this.targetSequenceId,
    this.errorMessage,
  });

  /// Create a successful traversal result
  factory TraversalResult.success({
    required List<ChatMessage> messages,
    required TraversalStopReason stopReason,
    int? nextMessageId,
    String? targetSequenceId,
  }) {
    return TraversalResult(
      messages: messages,
      stopReason: stopReason,
      nextMessageId: nextMessageId,
      targetSequenceId: targetSequenceId,
    );
  }

  /// Create an error traversal result
  factory TraversalResult.error({
    required String errorMessage,
    List<ChatMessage>? messages,
  }) {
    return TraversalResult(
      messages: messages ?? [],
      stopReason: TraversalStopReason.error,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'TraversalResult(messages: ${messages.length}, stopReason: $stopReason, nextMessageId: $nextMessageId, targetSequenceId: $targetSequenceId)';
  }
}