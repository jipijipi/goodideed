import '../../models/chat_message.dart';
import '../../models/chat_sequence.dart';
import '../../models/choice.dart';
import '../text_templating_service.dart';
import '../text_variants_service.dart';
import '../user_data_service.dart';
import '../semantic_content_service.dart';
import '../logger_service.dart';

/// Handles message processing including templates and variants
class MessageProcessor {
  final UserDataService? _userDataService;
  final TextTemplatingService? _templatingService;
  final TextVariantsService? _variantsService;
  final SemanticContentService _semanticContentService;

  MessageProcessor({
    UserDataService? userDataService,
    TextTemplatingService? templatingService,
    TextVariantsService? variantsService,
    SemanticContentService? semanticContentService,
  }) : _userDataService = userDataService,
       _templatingService = templatingService,
       _variantsService = variantsService,
       _semanticContentService = semanticContentService ?? SemanticContentService.instance;

  /// Process a single message template and replace variables with stored values
  /// Also applies semantic content resolution and text variants
  Future<ChatMessage> processMessageTemplate(ChatMessage message, ChatSequence? currentSequence) async {
    logger.debug('Processing message ID ${message.id}, type: ${message.type}, contentKey: "${message.contentKey}", text: "${message.text}"', component: LogComponent.messageProcessor);
    
    String textToProcess = message.text;
    List<Choice>? processedChoices = message.choices;
    
    // 1. Apply semantic content resolution (new system)
    if (message.contentKey != null && message.contentKey!.isNotEmpty) {
      logger.debug('Using semantic content system for contentKey: "${message.contentKey}"', component: LogComponent.messageProcessor);
      textToProcess = await _semanticContentService.getContent(message.contentKey!, message.text);
      logger.debug('Semantic content resolved to: "$textToProcess"', component: LogComponent.messageProcessor);
    } else {
      // 2. Fallback to legacy variant system for backward compatibility
      logger.debug('No contentKey, checking legacy variants system', component: LogComponent.messageProcessor);
      if (_variantsService != null && 
          currentSequence != null &&
          !message.isChoice && 
          !message.isTextInput && 
          !message.isAutoRoute && 
          !message.hasMultipleTexts) {
        
        logger.debug('Using legacy variants for sequence: ${currentSequence.sequenceId}, messageId: ${message.id}', component: LogComponent.messageProcessor);
        // Get variant for the main text
        textToProcess = await _variantsService.getVariant(
          message.text, 
          currentSequence.sequenceId, 
          message.id
        );
        logger.debug('Legacy variant resolved to: "$textToProcess"', component: LogComponent.messageProcessor);
      } else {
        logger.debug('No content processing - using original text', component: LogComponent.messageProcessor);
      }
    }
    
    // 3. Process choice options if present
    if (message.choices != null) {
      logger.debug('Processing ${message.choices!.length} choice options', component: LogComponent.messageProcessor);
      processedChoices = [];
      for (int i = 0; i < message.choices!.length; i++) {
        Choice choice = message.choices![i];
        logger.debug('   Choice ${i + 1}: text="${choice.text}", contentKey="${choice.contentKey}"', component: LogComponent.messageProcessor);
        String choiceText = choice.text;
        
        // Apply semantic content to choice if contentKey present
        if (choice.contentKey != null && choice.contentKey!.isNotEmpty) {
          logger.debug('Processing choice ${i + 1} with contentKey: "${choice.contentKey}"', component: LogComponent.messageProcessor);
          choiceText = await _semanticContentService.getContent(choice.contentKey!, choice.text);
          logger.debug('Choice ${i + 1} resolved to: "$choiceText"', component: LogComponent.messageProcessor);
        }
        
        processedChoices.add(Choice(
          text: choiceText,
          nextMessageId: choice.nextMessageId,
          sequenceId: choice.sequenceId,
          value: choice.value,
          contentKey: choice.contentKey,
        ));
      }
    }
    
    // 4. Apply template processing if service is available
    if (_templatingService != null) {
      textToProcess = await _templatingService.processTemplate(textToProcess);
    }
    
    return ChatMessage(
      id: message.id,
      text: textToProcess,
      delay: message.delay,
      sender: message.sender,
      type: message.type,
      choices: processedChoices,
      nextMessageId: message.nextMessageId,
      sequenceId: message.sequenceId,
      storeKey: message.storeKey,
      placeholderText: message.placeholderText,
      selectedChoiceText: message.selectedChoiceText,
      routes: message.routes,
      dataActions: message.dataActions,
      contentKey: message.contentKey,
      imagePath: message.imagePath,
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
      await _userDataService.storeValue(textInputMessage.storeKey!, userInput);
    }
  }

  /// Handle user choice selection and store it if storeKey is provided
  Future<void> handleUserChoice(ChatMessage choiceMessage, Choice selectedChoice) async {
    if (_userDataService != null && choiceMessage.storeKey != null) {
      // Use custom value if provided, fallback to choice text
      final valueToStore = selectedChoice.value ?? selectedChoice.text;
      await _userDataService.storeValue(choiceMessage.storeKey!, valueToStore);
    }
  }
}