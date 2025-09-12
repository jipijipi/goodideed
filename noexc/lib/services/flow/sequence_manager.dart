import '../../models/chat_message.dart';
import '../../models/chat_sequence.dart';
import '../chat_service/sequence_loader.dart';
import '../flow/message_walker.dart';
import '../logger_service.dart';

/// Clean sequence state management component
///
/// SINGLE RESPONSIBILITY: Manage sequence loading/unloading and message access
///
/// This component:
/// - DOES: Load sequences, provide message access, manage sequence state
/// - DOES NOT: Process messages, handle flow logic, make routing decisions
///
/// State management principles:
/// - Atomic operations (load succeeds completely or fails completely)
/// - Clear state tracking
/// - Simple, predictable interface
class SequenceManager implements MessageProvider {
  final SequenceLoader _sequenceLoader;
  final logger = LoggerService.instance;
  void Function(String sequenceId)? _onSequenceChanged;

  /// Currently loaded sequence (null if none loaded)
  ChatSequence? get currentSequence => _sequenceLoader.currentSequence;

  /// ID of currently loaded sequence (null if none loaded)
  String? get currentSequenceId => _sequenceLoader.currentSequence?.sequenceId;

  SequenceManager({required SequenceLoader sequenceLoader})
    : _sequenceLoader = sequenceLoader;

  /// Subscribe to sequence change events
  void setOnSequenceChanged(void Function(String sequenceId) callback) {
    _onSequenceChanged = callback;
  }

  /// Load a sequence by ID
  ///
  /// This operation is atomic - either succeeds completely or throws an exception.
  /// If it throws, the previous sequence state is preserved.
  Future<void> loadSequence(String sequenceId) async {
    logger.debug('Loading sequence: $sequenceId');

    try {
      final sequence = await _sequenceLoader.loadSequence(sequenceId);
      logger.debug(
        'Successfully loaded sequence: $sequenceId with ${sequence.messages.length} messages',
      );
      // Notify listeners about sequence change
      try {
        _onSequenceChanged?.call(sequenceId);
      } catch (e) {
        logger.warning('Sequence change callback failed: $e');
      }
    } catch (e) {
      logger.error('Failed to load sequence $sequenceId: $e');
      rethrow;
    }
  }

  /// Check if a message with the given ID exists in the current sequence
  @override
  bool hasMessage(int id) {
    final exists = _sequenceLoader.hasMessage(id);
    if (!exists) {
      logger.debug('Message $id not found in current sequence');
    }
    return exists;
  }

  /// Get a message by ID from the current sequence
  ///
  /// Returns null if the message doesn't exist.
  /// Use hasMessage() first to check existence if needed.
  @override
  ChatMessage? getMessage(int id) {
    final message = _sequenceLoader.getMessageById(id);
    if (message == null) {
      logger.debug('Message $id not found');
    }
    return message;
  }

  /// Get information about the current sequence state (for debugging)
  Map<String, dynamic> getStateInfo() {
    final sequence = currentSequence;
    return {
      'sequenceId': sequence?.sequenceId,
      'sequenceName': sequence?.name,
      'messageCount': sequence?.messages.length ?? 0,
      'isLoaded': sequence != null,
    };
  }

  /// Get the ID of the first message in the current sequence
  ///
  /// Returns null if no sequence is loaded or sequence has no messages.
  /// This is used to determine where to start when switching sequences.
  int? getFirstMessageId() {
    final sequence = currentSequence;
    if (sequence == null || sequence.messages.isEmpty) {
      return null;
    }
    return sequence.messages.first.id;
  }

  /// Validate that the current sequence is in a consistent state
  bool validateState() {
    final sequence = currentSequence;
    if (sequence == null) {
      logger.debug('No sequence loaded - state is valid');
      return true;
    }

    if (sequence.messages.isEmpty) {
      logger.warning('Loaded sequence ${sequence.sequenceId} has no messages');
      return false;
    }

    logger.debug(
      'Sequence state is valid: ${sequence.sequenceId} with ${sequence.messages.length} messages',
    );
    return true;
  }
}
