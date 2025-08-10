import '../../services/user_data_service.dart';
import '../../services/chat_service.dart';

/// Manages user data loading and debug information generation
class UserDataManager {
  final UserDataService userDataService;
  final ChatService? chatService;
  final String? currentSequenceId;
  final int? totalMessages;

  UserDataManager({
    required this.userDataService,
    this.chatService,
    this.currentSequenceId,
    this.totalMessages,
  });

  /// Loads all user data from the service
  Future<Map<String, dynamic>> loadUserData() async {
    try {
      return await userDataService.getAllData();
    } catch (e) {
      return {};
    }
  }

  /// Generates debug information about the current chat state
  Map<String, dynamic> getDebugInfo() {
    final debugInfo = <String, dynamic>{};

    // Chat System Info
    if (currentSequenceId != null) {
      debugInfo['Current Sequence'] = currentSequenceId!;
    }

    if (chatService?.currentSequence != null) {
      debugInfo['Sequence Name'] = chatService!.currentSequence!.name;
      debugInfo['Sequence Description'] =
          chatService!.currentSequence!.description;
    }

    if (totalMessages != null) {
      debugInfo['Total Messages'] = totalMessages!;
    }

    // App Info
    debugInfo['Flutter Framework'] = 'Flutter 3.29.3';
    debugInfo['Dart SDK'] = '^3.7.2';

    return debugInfo;
  }

  /// Loads both user data and debug information
  Future<({Map<String, dynamic> userData, Map<String, dynamic> debugData})>
  loadAllData() async {
    final userData = await loadUserData();
    final debugData = getDebugInfo();

    return (userData: userData, debugData: debugData);
  }
}
