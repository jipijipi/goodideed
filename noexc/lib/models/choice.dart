class Choice {
  final String text;
  final int? nextMessageId;
  final String? sequenceId;
  final dynamic value;

  Choice({
    required this.text,
    this.nextMessageId,
    this.sequenceId,
    this.value,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      text: json['text'] as String,
      nextMessageId: json['nextMessageId'] as int?,
      sequenceId: json['sequenceId'] as String?,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'text': text,
    };
    
    if (nextMessageId != null) {
      json['nextMessageId'] = nextMessageId!;
    }
    
    if (sequenceId != null) {
      json['sequenceId'] = sequenceId!;
    }
    
    if (value != null) {
      json['value'] = value;
    }
    
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Choice &&
        other.text == text &&
        other.nextMessageId == nextMessageId &&
        other.sequenceId == sequenceId &&
        other.value == value;
  }

  @override
  int get hashCode => text.hashCode ^ nextMessageId.hashCode ^ sequenceId.hashCode ^ value.hashCode;
}