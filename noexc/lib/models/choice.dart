class Choice {
  final String text;
  final int nextMessageId;

  Choice({
    required this.text,
    required this.nextMessageId,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      text: json['text'] as String,
      nextMessageId: json['nextMessageId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'nextMessageId': nextMessageId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Choice &&
        other.text == text &&
        other.nextMessageId == nextMessageId;
  }

  @override
  int get hashCode => text.hashCode ^ nextMessageId.hashCode;
}