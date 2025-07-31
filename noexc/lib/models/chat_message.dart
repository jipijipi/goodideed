import 'choice.dart';
import 'route_condition.dart';
import 'data_action.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';

enum MessageType {
  bot,
  user,
  choice,
  textInput,
  autoroute,
  dataAction,
  image,
}

class ChatMessage {
  final int id;
  final String text;
  final int delay;
  final String sender;
  final MessageType type;
  final List<Choice>? choices;
  final int? nextMessageId;
  final String? sequenceId;  // Universal cross-sequence navigation
  final String? storeKey;
  final String placeholderText;
  final String? selectedChoiceText;
  final List<RouteCondition>? routes;
  final List<DataAction>? dataActions;
  final String? contentKey;
  final String? imagePath;

  ChatMessage({
    required this.id,
    required this.text,
    this.delay = AppConstants.defaultMessageDelay,
    this.sender = ChatConfig.botSender,
    this.type = MessageType.bot,
    this.choices,
    this.nextMessageId,
    this.sequenceId,  // Universal cross-sequence navigation
    this.storeKey,
    this.placeholderText = AppConstants.defaultPlaceholderText,
    this.selectedChoiceText,
    this.routes,
    this.dataActions,
    this.contentKey,
    this.imagePath,
  }) :
       assert(
         type != MessageType.choice || text.isEmpty,
         'Choice messages should not have text content'
       ),
       assert(
         type != MessageType.textInput || text.isEmpty,
         'Text input messages should not have text content'
       ),
       assert(
         type != MessageType.autoroute || text.isEmpty,
         'Autoroute messages should not have text content'
       ),
       assert(
         type != MessageType.dataAction || text.isEmpty,
         'DataAction messages should not have text content'
       ),
       assert(
         type != MessageType.image || text.isEmpty,
         'Image messages should not have text content'
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

    List<DataAction>? dataActions;
    if (json['dataActions'] != null) {
      dataActions = (json['dataActions'] as List)
          .map((actionJson) => DataAction.fromJson(actionJson))
          .toList();
    }

    // Determine message type from either new 'type' field or legacy boolean fields
    MessageType messageType;
    if (json['type'] != null) {
      final typeString = json['type'] as String;
      messageType = MessageType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => MessageType.bot,
      );
    } else {
      // Backward compatibility with boolean fields
      final isChoice = json['isChoice'] as bool? ?? false;
      final isTextInput = json['isTextInput'] as bool? ?? false;
      final isAutoRoute = json['isAutoRoute'] as bool? ?? false;
      final sender = json['sender'] as String? ?? ChatConfig.botSender;
      
      if (isChoice) {
        messageType = MessageType.choice;
      } else if (isTextInput) {
        messageType = MessageType.textInput;
      } else if (isAutoRoute) {
        messageType = MessageType.autoroute;
      } else if (sender == ChatConfig.userSender) {
        messageType = MessageType.user;
      } else {
        messageType = MessageType.bot;
      }
    }
    
    // For interactive messages, use empty text to enforce single responsibility
    String messageText = json['text'] as String? ?? '';
    if (messageType == MessageType.choice || 
        messageType == MessageType.textInput || 
        messageType == MessageType.autoroute ||
        messageType == MessageType.dataAction ||
        messageType == MessageType.image) {
      messageText = '';
    }
    
    final imagePath = json['imagePath'] as String?;
    
    return ChatMessage(
      id: json['id'] as int,
      text: messageText,
      delay: json['delay'] as int? ?? AppConstants.defaultMessageDelay,
      sender: json['sender'] as String? ?? ChatConfig.botSender,
      type: messageType,
      choices: choices,
      nextMessageId: json['nextMessageId'] as int?,
      sequenceId: json['sequenceId'] as String?,  // Universal cross-sequence navigation
      storeKey: json['storeKey'] as String?,
      placeholderText: json['placeholderText'] as String? ?? AppConstants.defaultPlaceholderText,
      selectedChoiceText: json['selectedChoiceText'] as String?,
      routes: routes,
      dataActions: dataActions,
      contentKey: json['contentKey'] as String?,
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'text': text,
      'delay': delay,
      'sender': sender,
      'type': type.name,
    };

    // Add backward compatibility boolean fields
    if (type == MessageType.choice) {
      json['isChoice'] = true;
    }
    if (type == MessageType.textInput) {
      json['isTextInput'] = true;
    }
    if (type == MessageType.autoroute) {
      json['isAutoRoute'] = true;
    }
    if (type == MessageType.dataAction) {
      json['isDataAction'] = true;
    }

    if (choices != null) {
      json['choices'] = choices!.map((choice) => choice.toJson()).toList();
    }

    if (nextMessageId != null) {
      json['nextMessageId'] = nextMessageId!;
    }

    if (sequenceId != null) {
      json['sequenceId'] = sequenceId!;
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

    if (routes != null) {
      json['routes'] = routes!.map((route) => route.toJson()).toList();
    }

    if (dataActions != null) {
      json['dataActions'] = dataActions!.map((action) => action.toJson()).toList();
    }

    if (contentKey != null) {
      json['contentKey'] = contentKey!;
    }

    if (imagePath != null) {
      json['imagePath'] = imagePath!;
    }

    return json;
  }

  bool get isFromBot => sender == ChatConfig.botSender;
  bool get isFromUser => sender == ChatConfig.userSender;
  
  // Convenience getters for backward compatibility
  bool get isChoice => type == MessageType.choice;
  bool get isTextInput => type == MessageType.textInput;
  bool get isAutoRoute => type == MessageType.autoroute;
  bool get isDataAction => type == MessageType.dataAction;
  bool get isImage => type == MessageType.image;
  
  /// Returns true if this message has multiple texts (contains separator)
  bool get hasMultipleTexts => text.contains(ChatConfig.multiTextSeparator);
  
  /// Returns all text content as a list (splits on separator or single text)
  List<String> get allTexts {
    if (hasMultipleTexts) {
      return text.split(ChatConfig.multiTextSeparator)
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    return [text];
  }
  
  /// Returns all delays as a list (uses same delay for all split texts)
  List<int> get allDelays => List.filled(allTexts.length, delay);
  
  /// Creates a copy of this message with optional field updates
  ChatMessage copyWith({
    int? id,
    String? text,
    int? delay,
    String? sender,
    MessageType? type,
    List<Choice>? choices,
    int? nextMessageId,
    String? sequenceId,
    String? storeKey,
    String? placeholderText,
    String? selectedChoiceText,
    List<RouteCondition>? routes,
    List<DataAction>? dataActions,
    String? contentKey,
    String? imagePath,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      delay: delay ?? this.delay,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      choices: choices ?? this.choices,
      nextMessageId: nextMessageId ?? this.nextMessageId,
      sequenceId: sequenceId ?? this.sequenceId,
      storeKey: storeKey ?? this.storeKey,
      placeholderText: placeholderText ?? this.placeholderText,
      selectedChoiceText: selectedChoiceText ?? this.selectedChoiceText,
      routes: routes ?? this.routes,
      dataActions: dataActions ?? this.dataActions,
      contentKey: contentKey ?? this.contentKey,
      imagePath: imagePath ?? this.imagePath,
    );
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
      final messageType = isLast ? type : MessageType.bot; // Only last message keeps original type
      final messageText = isLast && (type == MessageType.choice || type == MessageType.textInput || type == MessageType.autoroute || type == MessageType.dataAction || type == MessageType.image) 
          ? '' : textList[i]; // Interactive messages have no text
      
      messages.add(ChatMessage(
        id: id, // Keep same ID for all parts of multi-text message
        text: messageText,
        delay: delayList[i],
        sender: sender,
        type: messageType,
        choices: isLast ? choices : null,
        nextMessageId: isLast ? nextMessageId : null, // Only last message has next ID
        sequenceId: isLast ? sequenceId : null, // Only last message has sequence navigation
        storeKey: isLast ? storeKey : null, // Only last message stores data
        placeholderText: placeholderText,
        selectedChoiceText: selectedChoiceText,
        routes: isLast ? routes : null,
        dataActions: isLast ? dataActions : null,
        contentKey: isLast ? contentKey : null, // Only last message has contentKey for processing
        imagePath: isLast ? imagePath : null, // Only last message has imagePath
      ));
    }
    
    return messages;
  }
}