import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/models/user_model.dart';
import 'package:tristopher_app/models/toRemove_message_model.dart';
import 'package:tristopher_app/services/user_service.dart';
import 'package:tristopher_app/services/onboarding_service.dart';

// Service providers
final userServiceProvider = Provider<UserService>((ref) => UserService());

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final userService = ref.watch(userServiceProvider);
  return OnboardingService(userService);
});

// User data providers
final userProvider = FutureProvider<UserModel?>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.getCurrentUser();
});

final completionHistoryProvider = FutureProvider<List<bool>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.getCompletionHistory();
});

final needsOnboardingProvider = FutureProvider<bool>((ref) {
  final onboardingService = ref.watch(onboardingServiceProvider);
  return onboardingService.needsOnboarding();
});

final currentOnboardingStageProvider = FutureProvider<OnboardingStage>((ref) {
  final onboardingService = ref.watch(onboardingServiceProvider);
  return onboardingService.getCurrentOnboardingStage();
});

// Chat messages state provider
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<MessageModel>>((ref) {
  return ChatMessagesNotifier();
});



class ChatMessagesNotifier extends StateNotifier<List<MessageModel>> {
  ChatMessagesNotifier() : super([]);
  
  void addMessage(MessageModel message) {
    state = [...state, message];
    
    // We'll handle the scroll notification in the UI
  }
  
  void addTristopherMessage(String content) {
    final message = MessageModel.fromTristopher(content);
    addMessage(message);
  }
  
  void addUserMessage(String content) {
    final message = MessageModel.fromUser(content);
    addMessage(message);
  }
  
  void addOptionsMessage(String content, List<MessageOption> options) {
    final message = MessageModel.withOptions(
      content: content,
      sender: MessageSender.tristopher,
      options: options,
    );
    addMessage(message);
  }
  
  void addInputMessage(String content, Function onInputSubmit, {String? inputHint}) {
    final message = MessageModel.withInput(
      content: content,
      sender: MessageSender.tristopher,
      onInputSubmit: onInputSubmit,
      inputHint: inputHint,
    );
    addMessage(message);
  }
  
  void addSystemMessage(String content) {
    final message = MessageModel.fromSystem(content);
    addMessage(message);
  }
  
  void addAchievementMessage(String achievement) {
    final message = MessageModel.achievement(achievement);
    addMessage(message);
  }
  
  void addStreakMessage(String content) {
    final message = MessageModel.streak(content);
    addMessage(message);
  }
  
  void clearMessages() {
    state = [];
  }
}

// Daily check-in state provider
final needsDailyCheckinProvider = FutureProvider<bool>((ref) async {
  final userService = ref.watch(userServiceProvider);
  final user = await userService.getCurrentUser();
  if (user == null) return false;
  return user.needsDailyCheckin;
});

// UI state providers
final showStakeFailureAnimationProvider = StateProvider<bool>((ref) => false);
