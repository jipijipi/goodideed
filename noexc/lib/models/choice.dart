class Choice {
  final String text;
  final int? nextMessageId;
  final String? sequenceId;
  final dynamic value;
  final String? contentKey;

  Choice({
    required this.text,
    this.nextMessageId,
    this.sequenceId,
    this.value,
    this.contentKey,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    final sequenceId = json['sequenceId'] as String?;
    return Choice(
      text: json['text'] as String,
      nextMessageId: sequenceId != null ? null : json['nextMessageId'] as int?,
      sequenceId: sequenceId,
      value: json['value'],
      contentKey: json['contentKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'text': text,
    };
    
    if (sequenceId != null) {
      json['sequenceId'] = sequenceId!;
      // When switching sequences, don't include nextMessageId as we always start at message 1
    } else if (nextMessageId != null) {
      json['nextMessageId'] = nextMessageId!;
    }
    
    if (value != null) {
      json['value'] = value;
    }
    
    if (contentKey != null) {
      json['contentKey'] = contentKey;
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
        other.value == value &&
        other.contentKey == contentKey;
  }

  @override
  int get hashCode => text.hashCode ^ nextMessageId.hashCode ^ sequenceId.hashCode ^ value.hashCode ^ contentKey.hashCode;
}