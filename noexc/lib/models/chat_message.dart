import 'choice.dart';
import 'route_condition.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';

class ChatMessage {
  final int id;
  final String text;
  final List<String>? texts; // New: Support for multiple consecutive texts
  final int delay;
  final List<int>? delays; // New: Individual delays for each text in texts array
  final String sender;
  final bool isChoice;
  final bool isTextInput;
  final List<Choice>? choices;
  final int? nextMessageId;
  final String? storeKey;
  final String placeholderText;
  final String? selectedChoiceText;
  final bool isAutoRoute;
  final List<RouteCondition>? routes;

  ChatMessage({
    required this.id,
    required this.text,
    this.texts,
    this.delay = AppConstants.defaultMessageDelay,
    this.delays,
    this.sender = ChatConfig.botSender,
    this.isChoice = false,
    this.isTextInput = false,
    this.choices,
    this.nextMessageId,
    this.storeKey,
    this.placeholderText = AppConstants.defaultPlaceholderText,
    this.selectedChoiceText,
    this.isAutoRoute = false,
    this.routes,
  }) : assert(
         texts == null || texts.isNotEmpty,
         'texts array cannot be empty if provided'
       ),
       assert(
         delays == null || texts == null || delays.length == texts.length,
         'delays array must match texts array length'
       ),
       assert(
         !isChoice || text.isEmpty,
         'Choice messages should not have text content'
       ),
       assert(
         !isTextInput || text.isEmpty,
         'Text input messages should not have text content'
       ),
       assert(
         !isAutoRoute || text.isEmpty,
         'Autoroute messages should not have text content'
       );

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<Choice>? choices;
    if (json['choices'] != null) {
      choices = (json['choices'] as List)
          .map((choiceJson) => Choice.fromJson(choiceJson))
          .toList();
    }

    List<RouteCondition>? routes;
    if (json['routes'] != null) {
      routes = (json['routes'] as List)
          .map((routeJson) => RouteCondition.fromJson(routeJson))
          .toList();
    }

    // Handle texts array
    List<String>? texts;
    if (json['texts'] != null) {
      texts = (json['texts'] as List).cast<String>();
    }

    // Handle delays array
    List<int>? delays;
    if (json['delays'] != null) {
      delays = (json['delays'] as List).cast<int>();
    }

    final isChoice = json['isChoice'] as bool? ?? false;
    final isTextInput = json['isTextInput'] as bool? ?? false;
    final isAutoRoute = json['isAutoRoute'] as bool? ?? false;
    
    // For interactive messages, use empty text to enforce single responsibility
    // Handle optional text field for interactive messages
    String messageText = json['text'] as String? ?? '';
    if (isChoice || isTextInput || isAutoRoute) {
      messageText = '';
    }
    
    return ChatMessage(
      id: json['id'] as int,
      text: messageText,
      texts: texts,
      delay: json['delay'] as int? ?? AppConstants.defaultMessageDelay,
      delays: delays,
      sender: json['sender'] as String? ?? ChatConfig.botSender,
      isChoice: isChoice,
      isTextInput: isTextInput,
      choices: choices,
      nextMessageId: json['nextMessageId'] as int?,
      storeKey: json['storeKey'] as String?,
      placeholderText: json['placeholderText'] as String? ?? AppConstants.defaultPlaceholderText,
      selectedChoiceText: json['selectedChoiceText'] as String?,
      isAutoRoute: isAutoRoute,
      routes: routes,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'text': text,
      'delay': delay,
      'sender': sender,
    };

    if (texts != null) {
      json['texts'] = texts!;
    }

    if (delays != null) {
      json['delays'] = delays!;
    }

    if (isChoice) {
      json['isChoice'] = isChoice;
    }

    if (isTextInput) {
      json['isTextInput'] = isTextInput;
    }

    if (choices != null) {
      json['choices'] = choices!.map((choice) => choice.toJson()).toList();
    }

    if (nextMessageId != null) {
      json['nextMessageId'] = nextMessageId!;
    }

    if (storeKey != null) {
      json['storeKey'] = storeKey!;
    }

    if (placeholderText != AppConstants.defaultPlaceholderText) {
      json['placeholderText'] = placeholderText;
    }

    if (selectedChoiceText != null) {
      json['selectedChoiceText'] = selectedChoiceText!;
    }

    if (isAutoRoute) {
      json['isAutoRoute'] = isAutoRoute;
    }

    if (routes != null) {
      json['routes'] = routes!.map((route) => route.toJson()).toList();
    }

    return json;
  }

  bool get isFromBot => sender == ChatConfig.botSender;
  bool get isFromUser => sender == ChatConfig.userSender;
  
  /// Returns true if this message has multiple texts
  bool get hasMultipleTexts => texts != null && texts!.isNotEmpty;
  
  /// Returns all text content as a list (single text becomes single-item list)
  List<String> get allTexts => hasMultipleTexts ? texts! : [text];
  
  /// Returns all delays as a list (single delay becomes repeated for each text)
  List<int> get allDelays {
    if (hasMultipleTexts && delays != null) {
      return delays!;
    } else if (hasMultipleTexts) {
      // Use default delay for all texts if no delays specified
      return List.filled(texts!.length, delay);
    } else {
      return [delay];
    }
  }
  
  /// Creates individual ChatMessage objects for each text in a multi-text message
  List<ChatMessage> expandToIndividualMessages() {
    if (!hasMultipleTexts) {
      return [this];
    }
    
    final textList = allTexts;
    final delayList = allDelays;
    final messages = <ChatMessage>[];
    
    for (int i = 0; i < textList.length; i++) {
      final isLast = i == textList.length - 1;
      messages.add(ChatMessage(
        id: id + i, // Use incremental IDs for individual messages
        text: isLast && (isChoice || isTextInput || isAutoRoute) ? '' : textList[i], // Interactive messages have no text
        delay: delayList[i],
        sender: sender,
        isChoice: isLast ? isChoice : false, // Only last message can have choices
        isTextInput: isLast ? isTextInput : false, // Only last message can have text input
        choices: isLast ? choices : null,
        nextMessageId: isLast ? nextMessageId : null, // Only last message has next ID
        storeKey: isLast ? storeKey : null, // Only last message stores data
        placeholderText: placeholderText,
        selectedChoiceText: selectedChoiceText,
        isAutoRoute: isLast ? isAutoRoute : false, // Only last message can autoroute
        routes: isLast ? routes : null,
      ));
    }
    
    return messages;
  }
}