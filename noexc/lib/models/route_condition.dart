class RouteCondition {
  final String? condition;
  final String? sequenceId;
  final int? nextMessageId;
  final bool isDefault;

  RouteCondition({
    this.condition,
    this.sequenceId,
    this.nextMessageId,
    this.isDefault = false,
  });

  factory RouteCondition.fromJson(Map<String, dynamic> json) {
    final sequenceId = json['sequenceId'] as String?;
    return RouteCondition(
      condition: json['condition'] as String?,
      sequenceId: sequenceId,
      nextMessageId: sequenceId != null ? null : json['nextMessageId'] as int?,
      isDefault: json['default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (condition != null) {
      json['condition'] = condition!;
    }

    if (sequenceId != null) {
      json['sequenceId'] = sequenceId!;
      // When switching sequences, don't include nextMessageId as we always start at message 1
    } else if (nextMessageId != null) {
      json['nextMessageId'] = nextMessageId!;
    }

    if (isDefault) {
      json['default'] = isDefault;
    }

    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteCondition &&
        other.condition == condition &&
        other.sequenceId == sequenceId &&
        other.nextMessageId == nextMessageId &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode =>
      condition.hashCode ^
      sequenceId.hashCode ^
      nextMessageId.hashCode ^
      isDefault.hashCode;
}
