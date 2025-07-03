class ChatMessage {
  final int id;
  final String text;
  final String timestamp;
  final int delay;

  ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.delay,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      text: json['text'] as String,
      timestamp: json['timestamp'] as String,
      delay: json['delay'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp,
      'delay': delay,
    };
  }
}