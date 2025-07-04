class ChatMessage {
  final int id;
  final String text;
  final int delay;
  final String sender;

  ChatMessage({
    required this.id,
    required this.text,
    required this.delay,
    this.sender = 'bot',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      text: json['text'] as String,
      delay: json['delay'] as int,
      sender: json['sender'] as String? ?? 'bot',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'delay': delay,
      'sender': sender,
    };
  }

  bool get isFromBot => sender == 'bot';
  bool get isFromUser => sender == 'user';
}