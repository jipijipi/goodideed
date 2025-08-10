import '../../models/chat_message.dart';
import '../../models/chat_sequence.dart';
import '../../models/choice.dart';
import '../chat_service/message_processor.dart';
import '../logger_service.dart';

/// Pure message processing component
///
/// SINGLE RESPONSIBILITY: Transform raw messages into display-ready messages
///
/// This component:
/// - DOES: Process templates, apply variants, expand multi-text messages
/// - DOES NOT: Decide which messages to process, handle flow logic, modify state
///
/// Pure function principles:
/// - Same input always produces same output (given same context)
/// - No side effects on flow or state
/// - Transformations only
class MessageRenderer {
  final MessageProcessor _messageProcessor;
  final logger = LoggerService.instance;

  MessageRenderer({required MessageProcessor messageProcessor})
    : _messageProcessor = messageProcessor;

  /// Render a list of raw messages into display-ready messages
  ///
  /// This method:
  /// 1. Filters out non-displayable messages (autoroute, dataAction)
  /// 2. Processes templates and variants for each message
  /// 3. Expands multi-text messages (|||) into individual messages
  /// 4. Returns the final list ready for UI display
  ///
  /// Note: This is a pure transformation - no flow decisions are made here
  Future<List<ChatMessage>> render(
    List<ChatMessage> rawMessages,
    ChatSequence? currentSequence,
  ) async {
    // Phase 1: Filter displayable messages
    final displayableMessages = _filterDisplayableMessages(rawMessages);

    // Phase 2: Process templates and variants
    final processedMessages = await _messageProcessor.processMessageTemplates(
      displayableMessages,
      currentSequence,
    );

    // Phase 3: Expand multi-text messages
    final expandedMessages = _expandMultiTextMessages(processedMessages);

    // Single summary log instead of 4 separate debug statements
    logger.debug(
      'Rendered ${rawMessages.length} → ${displayableMessages.length} → ${expandedMessages.length} messages',
    );

    return expandedMessages;
  }

  /// Filter out messages that should not be displayed to the user
  List<ChatMessage> _filterDisplayableMessages(List<ChatMessage> messages) {
    return messages.where((message) {
      // Autoroute and dataAction messages are not displayed - they're processed by orchestrator
      return message.type != MessageType.autoroute &&
          message.type != MessageType.dataAction;
    }).toList();
  }

  /// Expand messages that contain multiple texts (|||) into individual messages
  List<ChatMessage> _expandMultiTextMessages(List<ChatMessage> messages) {
    final List<ChatMessage> expandedMessages = [];

    for (final message in messages) {
      final individualMessages = message.expandToIndividualMessages();
      expandedMessages.addAll(individualMessages);
    }

    return expandedMessages;
  }

  /// Handle user text input and store it if storeKey is provided
  ///
  /// Delegates to the underlying MessageProcessor for consistency.
  Future<void> handleUserTextInput(
    ChatMessage textInputMessage,
    String userInput,
  ) async {
    await _messageProcessor.handleUserTextInput(textInputMessage, userInput);
  }

  /// Handle user choice selection and store it if storeKey is provided
  ///
  /// Delegates to the underlying MessageProcessor for consistency.
  Future<void> handleUserChoice(
    ChatMessage choiceMessage,
    Choice selectedChoice,
  ) async {
    await _messageProcessor.handleUserChoice(choiceMessage, selectedChoice);
  }
}
