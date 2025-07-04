import 'choice.dart';

class ChatMessage {
  final int id;
  final String text;
  final int delay;
  final String sender;
  final bool isChoice;
  final List<Choice>? choices;
  final int? nextMessageId;

  ChatMessage({
    required this.id,
    required this.text,
    required this.delay,
    this.sender = 'bot',
    this.isChoice = false,
    this.choices,
    this.nextMessageId,
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
      delay: json['delay'] as int,
      sender: json['sender'] as String? ?? 'bot',
      isChoice: json['isChoice'] as bool? ?? false,
      choices: choices,
      nextMessageId: json['nextMessageId'] as int?,
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

    if (choices != null) {
      json['choices'] = choices!.map((choice) => choice.toJson()).toList();
    }

    if (nextMessageId != null) {
      json['nextMessageId'] = nextMessageId!;
    }

    return json;
  }

  bool get isFromBot => sender == 'bot';
  bool get isFromUser => sender == 'user';
}