import 'choice.dart';

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

  static const int defaultDelay = 1000; // Default delay in milliseconds
  static const String defaultPlaceholderText = 'Type your answer...';

  ChatMessage({
    required this.id,
    required this.text,
    this.delay = defaultDelay,
    this.sender = 'bot',
    this.isChoice = false,
    this.isTextInput = false,
    this.choices,
    this.nextMessageId,
    this.storeKey,
    this.placeholderText = defaultPlaceholderText,
    this.selectedChoiceText,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<Choice>? choices;
    if (json['choices'] != null) {
      choices = (json['choices'] as List)
          .map((choiceJson) => Choice.fromJson(choiceJson))
          .toList();
    }

    return ChatMessage(
      id: json['id'] as int,
      text: json['text'] as String,
      delay: json['delay'] as int? ?? defaultDelay,
      sender: json['sender'] as String? ?? 'bot',
      isChoice: json['isChoice'] as bool? ?? false,
      isTextInput: json['isTextInput'] as bool? ?? false,
      choices: choices,
      nextMessageId: json['nextMessageId'] as int?,
      storeKey: json['storeKey'] as String?,
      placeholderText: json['placeholderText'] as String? ?? defaultPlaceholderText,
      selectedChoiceText: json['selectedChoiceText'] as String?,
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

    if (placeholderText != defaultPlaceholderText) {
      json['placeholderText'] = placeholderText;
    }

    if (selectedChoiceText != null) {
      json['selectedChoiceText'] = selectedChoiceText!;
    }

    return json;
  }

  bool get isFromBot => sender == 'bot';
  bool get isFromUser => sender == 'user';
}