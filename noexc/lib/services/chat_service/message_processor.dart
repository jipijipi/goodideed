import '../../models/chat_message.dart';
import '../../models/chat_sequence.dart';
import '../../models/choice.dart';
import '../text_templating_service.dart';
import '../text_variants_service.dart';
import '../user_data_service.dart';
import '../semantic_content_service.dart';
import 'dart:developer' as developer;

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
    developer.log('🔧 MESSAGE_PROCESSOR: Processing message ID ${message.id}, type: ${message.type}, contentKey: "${message.contentKey}", text: "${message.text}"', name: 'MessageProcessor');
    
    String textToProcess = message.text;
    List<Choice>? processedChoices = message.choices;
    
    // 1. Apply semantic content resolution (new system)
    if (message.contentKey != null && message.contentKey!.isNotEmpty) {
      developer.log('🎯 MESSAGE_PROCESSOR: Using semantic content system for contentKey: "${message.contentKey}"', name: 'MessageProcessor');
      textToProcess = await _semanticContentService.getContent(message.contentKey!, message.text);
      developer.log('✨ MESSAGE_PROCESSOR: Semantic content resolved to: "$textToProcess"', name: 'MessageProcessor');
    } else {
      // 2. Fallback to legacy variant system for backward compatibility
      developer.log('📰 MESSAGE_PROCESSOR: No contentKey, checking legacy variants system', name: 'MessageProcessor');
      if (_variantsService != null && 
          currentSequence != null &&
          !message.isChoice && 
          !message.isTextInput && 
          !message.isAutoRoute && 
          !message.hasMultipleTexts) {
        
        developer.log('🗂️ MESSAGE_PROCESSOR: Using legacy variants for sequence: ${currentSequence.sequenceId}, messageId: ${message.id}', name: 'MessageProcessor');
        // Get variant for the main text
        textToProcess = await _variantsService.getVariant(
          message.text, 
          currentSequence.sequenceId, 
          message.id
        );
        developer.log('📜 MESSAGE_PROCESSOR: Legacy variant resolved to: "$textToProcess"', name: 'MessageProcessor');
      } else {
        developer.log('⚪ MESSAGE_PROCESSOR: No content processing - using original text', name: 'MessageProcessor');
      }
    }
    
    // 3. Process choice options if present
    if (message.choices != null) {
      developer.log('🔘 MESSAGE_PROCESSOR: Processing ${message.choices!.length} choice options', name: 'MessageProcessor');
      processedChoices = [];
      for (int i = 0; i < message.choices!.length; i++) {
        Choice choice = message.choices![i];
        developer.log('   Choice ${i + 1}: text="${choice.text}", contentKey="${choice.contentKey}"', name: 'MessageProcessor');
        String choiceText = choice.text;
        
        // Apply semantic content to choice if contentKey present
        if (choice.contentKey != null && choice.contentKey!.isNotEmpty) {
          developer.log('🎯 MESSAGE_PROCESSOR: Processing choice ${i + 1} with contentKey: "${choice.contentKey}"', name: 'MessageProcessor');
          choiceText = await _semanticContentService.getContent(choice.contentKey!, choice.text);
          developer.log('✨ MESSAGE_PROCESSOR: Choice ${i + 1} resolved to: "$choiceText"', name: 'MessageProcessor');
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