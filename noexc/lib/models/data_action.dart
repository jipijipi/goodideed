enum DataActionType { set, increment, decrement, reset, trigger, append, remove }

class DataAction {
  final DataActionType type;
  final String key;
  final dynamic value;
  final String? event;
  final Map<String, dynamic>? data;

  DataAction({
    required this.type,
    required this.key,
    this.value,
    this.event,
    this.data,
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
      event: json['event'] as String?,
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'type': type.name, 'key': key};

    if (value != null) {
      json['value'] = value;
    }

    if (event != null) {
      json['event'] = event;
    }

    if (data != null) {
      json['data'] = data;
    }

    return json;
  }
}
