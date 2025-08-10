import '../../../services/chat_service.dart';
import '../../../services/user_data_service.dart';
import '../../../services/text_templating_service.dart';
import '../../../services/text_variants_service.dart';
import '../../../services/message_queue.dart';

/// Manages initialization and coordination of all chat services
class ServiceManager {
  late final UserDataService _userDataService;
  late final TextTemplatingService _templatingService;
  late final TextVariantsService _variantsService;
  late final ChatService _chatService;
  late final MessageQueue _messageQueue;

  bool _initialized = false;

  /// Get the user data service
  UserDataService get userDataService => _userDataService;

  /// Get the chat service
  ChatService get chatService => _chatService;

  /// Get the message queue
  MessageQueue get messageQueue => _messageQueue;

  /// Check if services are initialized
  bool get isInitialized => _initialized;

  /// Initialize all required services
  void initializeServices() {
    if (_initialized) return;

    _userDataService = UserDataService();
    _templatingService = TextTemplatingService(_userDataService);
    _variantsService = TextVariantsService();
    _chatService = ChatService(
      userDataService: _userDataService,
      templatingService: _templatingService,
      variantsService: _variantsService,
    );
    _messageQueue = MessageQueue();

    _initialized = true;

    // Note: Sequence switching is now handled entirely by ChatService message accumulation
    // No callback needed - this prevents duplicate message processing
  }

  /// Dispose of all services
  void dispose() {
    if (!_initialized) return;

    _messageQueue.dispose();
    _initialized = false;
  }
}
