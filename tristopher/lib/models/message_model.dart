enum MessageSender {
  tristopher,
  user,
  system
}

enum MessageType {
  text,
  options,
  input,
  achievement,
  streak,
}

class MessageOption {
  final String id;
  final String text;
  final Function onTap;

  MessageOption({
    required this.id,
    required this.text,
    required this.onTap,
  });
}

class MessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final MessageType type;
  final DateTime timestamp;
  final List<MessageOption>? options;
  final Function? onInputSubmit;
  final String? inputHint;

  MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.type,
    required this.timestamp,
    this.options,
    this.onInputSubmit,
    this.inputHint,
  });

  // Create a text message from Tristopher
  factory MessageModel.fromTristopher(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.tristopher,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );
  }

  // Create a text message from the user
  factory MessageModel.fromUser(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );
  }

  // Create a system message
  factory MessageModel.fromSystem(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.system,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );
  }

  // Create a message with options
  factory MessageModel.withOptions({
    required String content,
    required MessageSender sender,
    required List<MessageOption> options,
  }) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: sender,
      type: MessageType.options,
      timestamp: DateTime.now(),
      options: options,
    );
  }

  // Create a message with input field
  factory MessageModel.withInput({
    required String content,
    required MessageSender sender,
    required Function onInputSubmit,
    String? inputHint,
  }) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: sender,
      type: MessageType.input,
      timestamp: DateTime.now(),
      onInputSubmit: onInputSubmit,
      inputHint: inputHint,
    );
  }

  // Create an achievement message
  factory MessageModel.achievement(String achievement) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: achievement,
      sender: MessageSender.system,
      type: MessageType.achievement,
      timestamp: DateTime.now(),
    );
  }

  // Create a streak display message
  factory MessageModel.streak(String content) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.system,
      type: MessageType.streak,
      timestamp: DateTime.now(),
    );
  }
}
