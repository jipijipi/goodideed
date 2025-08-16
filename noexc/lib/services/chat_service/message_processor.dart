import 'dart:convert';
import '../../models/chat_message.dart';
import '../../models/chat_sequence.dart';
import '../../models/choice.dart';
import '../text_templating_service.dart';
import '../text_variants_service.dart';
import '../user_data_service.dart';
import '../semantic_content_service.dart';
import '../formatter_service.dart';

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
       _semanticContentService =
           semanticContentService ?? SemanticContentService.instance;

  /// Process a single message template and replace variables with stored values
  /// Also applies semantic content resolution and text variants
  Future<ChatMessage> processMessageTemplate(
    ChatMessage message,
    ChatSequence? currentSequence,
  ) async {
    String textToProcess = message.text;
    List<Choice>? processedChoices = message.choices;

    // 1. Apply semantic content resolution (new system)
    if (message.contentKey != null &&
        message.contentKey!.isNotEmpty &&
        message.type != MessageType.choice) {
      textToProcess = await _semanticContentService.getContent(
        message.contentKey!,
        message.text,
      );
    } else {
      // 2. Fallback to legacy variant system for backward compatibility
      if (_variantsService != null &&
          currentSequence != null &&
          message.type != MessageType.choice &&
          message.type != MessageType.textInput &&
          message.type != MessageType.autoroute &&
          !message.hasMultipleTexts) {
        // Get variant for the main text
        textToProcess = await _variantsService.getVariant(
          message.text,
          currentSequence.sequenceId,
          message.id,
        );
      }
    }

    // 3. Process choice options if present
    if (message.choices != null) {
      processedChoices = [];
      for (Choice choice in message.choices!) {
        String choiceText = choice.text;

        // Apply semantic content to choice if contentKey present
        if (choice.contentKey != null && choice.contentKey!.isNotEmpty) {
          choiceText = await _semanticContentService.getContent(
            choice.contentKey!,
            choice.text,
          );
        }

        // Unescape choice text for markdown rendering
        choiceText = FormatterService().unescapeTextForMarkdown(choiceText);

        processedChoices.add(
          Choice(
            text: choiceText,
            nextMessageId: choice.nextMessageId,
            sequenceId: choice.sequenceId,
            value: choice.value,
            contentKey: choice.contentKey,
          ),
        );
      }
    }

    // 4. Apply template processing if service is available
    if (_templatingService != null) {
      textToProcess = await _templatingService.processTemplate(textToProcess);
    }

    // 5. Unescape newlines and other common escape sequences for markdown rendering
    textToProcess = FormatterService().unescapeTextForMarkdown(textToProcess);

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
  Future<List<ChatMessage>> processMessageTemplates(
    List<ChatMessage> messages,
    ChatSequence? currentSequence,
  ) async {
    final List<ChatMessage> processedMessages = [];

    for (final message in messages) {
      final processedMessage = await processMessageTemplate(
        message,
        currentSequence,
      );
      processedMessages.add(processedMessage);
    }

    return processedMessages;
  }

  /// Handle user text input and store it if storeKey is provided
  Future<void> handleUserTextInput(
    ChatMessage textInputMessage,
    String userInput,
  ) async {
    if (_userDataService != null && textInputMessage.storeKey != null) {
      await _userDataService.storeValue(textInputMessage.storeKey!, userInput);
    }
  }

  /// Handle user choice selection and store it if storeKey is provided
  Future<void> handleUserChoice(
    ChatMessage choiceMessage,
    Choice selectedChoice,
  ) async {
    if (_userDataService != null && choiceMessage.storeKey != null) {
      // Use custom value if provided, fallback to choice text
      final rawValue = selectedChoice.value ?? selectedChoice.text;

      // Parse JSON arrays for activeDays and similar array-based configurations
      final valueToStore = _parseChoiceValue(rawValue);

      await _userDataService.storeValue(choiceMessage.storeKey!, valueToStore);
    }
  }

  /// Parse choice values, converting JSON arrays to proper List objects
  dynamic _parseChoiceValue(dynamic rawValue) {
    if (rawValue is! String) {
      return rawValue; // Not a string, return as-is
    }

    final stringValue = rawValue;

    // Check if it looks like a JSON array: starts with [ and ends with ]
    if (stringValue.trim().startsWith('[') &&
        stringValue.trim().endsWith(']')) {
      try {
        // Parse as JSON and convert to List<int> for activeDays
        final parsed = json.decode(stringValue);
        if (parsed is List) {
          // Convert all elements to int for weekday numbers
          return parsed
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? e)
              .toList();
        }
      } catch (e) {
        // If JSON parsing fails, fall back to original string value
        return rawValue;
      }
    }

    return rawValue; // Not a JSON array, return as-is
  }

  // Unescape logic moved to FormatterService
}
