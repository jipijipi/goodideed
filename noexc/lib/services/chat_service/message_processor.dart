import '../../models/chat_message.dart';
import '../../models/chat_sequence.dart';
import '../../models/choice.dart';
import '../text_templating_service.dart';
import '../text_variants_service.dart';
import '../user_data_service.dart';

/// Handles message processing including templates and variants
class MessageProcessor {
  final UserDataService? _userDataService;
  final TextTemplatingService? _templatingService;
  final TextVariantsService? _variantsService;

  MessageProcessor({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
    TextVariantsService? variantsService,
  }) : _userDataService = userDataService,
       _templatingService = templatingService,
       _variantsService = variantsService;

  /// Process a single message template and replace variables with stored values
  /// Also applies text variants for regular messages (not choices, inputs, conditionals, or multi-texts)
  Future<ChatMessage> processMessageTemplate(ChatMessage message, ChatSequence? currentSequence) async {
    String textToProcess = message.text;
    
    // Apply variants only for regular messages (not choices, inputs, conditionals, or multi-texts)
    if (_variantsService != null && 
        currentSequence != null &&
        !message.isChoice && 
        !message.isTextInput && 
        !message.isAutoRoute && 
        !message.hasMultipleTexts) {
      
      // Get variant for the main text
      textToProcess = await _variantsService!.getVariant(
        message.text, 
        currentSequence.sequenceId, 
        message.id
      );
    }
    
    // Apply template processing if service is available
    if (_templatingService != null) {
      textToProcess = await _templatingService!.processTemplate(textToProcess);
    }
    
    return ChatMessage(
      id: message.id,
      text: textToProcess,
      delay: message.delay,
      sender: message.sender,
      type: message.type,
      choices: message.choices,
      nextMessageId: message.nextMessageId,
      storeKey: message.storeKey,
      placeholderText: message.placeholderText,
      routes: message.routes,
    );
  }

  /// Process a list of messages and replace template variables
  Future<List<ChatMessage>> processMessageTemplates(List<ChatMessage> messages, ChatSequence? currentSequence) async {
    final List<ChatMessage> processedMessages = [];
    
    for (final message in messages) {
      final processedMessage = await processMessageTemplate(message, currentSequence);
      processedMessages.add(processedMessage);
    }
    
    return processedMessages;
  }

  /// Handle user text input and store it if storeKey is provided
  Future<void> handleUserTextInput(ChatMessage textInputMessage, String userInput) async {
    if (_userDataService != null && textInputMessage.storeKey != null) {
      await _userDataService!.storeValue(textInputMessage.storeKey!, userInput);
    }
  }

  /// Handle user choice selection and store it if storeKey is provided
  Future<void> handleUserChoice(ChatMessage choiceMessage, Choice selectedChoice) async {
    if (_userDataService != null && choiceMessage.storeKey != null) {
      // Use custom value if provided, fallback to choice text
      final valueToStore = selectedChoice.value ?? selectedChoice.text;
      await _userDataService!.storeValue(choiceMessage.storeKey!, valueToStore);
    }
  }
}