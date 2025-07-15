enum DataActionType {
  set,
  increment,
  decrement,
  reset,
}

class DataAction {
  final DataActionType type;
  final String key;
  final dynamic value;

  DataAction({
    required this.type,
    required this.key,
    this.value,
  });

  factory DataAction.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final actionType = DataActionType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => DataActionType.set,
    );

    return DataAction(
      type: actionType,
      key: json['key'] as String,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'type': type.name,
      'key': key,
    };

    if (value != null) {
      json['value'] = value;
    }

    return json;
  }
}