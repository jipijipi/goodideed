import 'choice.dart';
import 'route_condition.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';

class ChatMessage {
  final int id;
  final String text;
  final int delay;
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
    this.delay = AppConstants.defaultMessageDelay,
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
  });

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

    return ChatMessage(
      id: json['id'] as int,
      text: json['text'] as String,
      delay: json['delay'] as int? ?? AppConstants.defaultMessageDelay,
      sender: json['sender'] as String? ?? ChatConfig.botSender,
      isChoice: json['isChoice'] as bool? ?? false,
      isTextInput: json['isTextInput'] as bool? ?? false,
      choices: choices,
      nextMessageId: json['nextMessageId'] as int?,
      storeKey: json['storeKey'] as String?,
      placeholderText: json['placeholderText'] as String? ?? AppConstants.defaultPlaceholderText,
      selectedChoiceText: json['selectedChoiceText'] as String?,
      isAutoRoute: json['isAutoRoute'] as bool? ?? false,
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
}