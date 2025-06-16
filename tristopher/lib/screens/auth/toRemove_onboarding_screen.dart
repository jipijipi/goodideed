import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/models/message_model.dart';
import 'package:tristopher_app/providers/providers.dart';
import 'package:tristopher_app/services/toRemove_onboarding_service.dart';
import 'package:tristopher_app/services/toRemove_story_service.dart';
import 'package:tristopher_app/widgets/toRemove_chat_bubble.dart';
import 'package:tristopher_app/widgets/common/paper_background_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final ScrollController _scrollController = ScrollController();
  final StoryService _storyService = StoryService();
  late OnboardingService _onboardingService;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _onboardingService = ref.read(onboardingServiceProvider);
    
    // Start the onboarding process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOnboarding();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll to bottom of chat when new message is added
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Initialize the onboarding flow
  Future<void> _initializeOnboarding() async {
    if (_isInitialized) return;
    
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    chatNotifier.clearMessages();
    
    // Get current onboarding stage
    final stage = await _onboardingService.getCurrentOnboardingStage();
    
    // Start from the beginning if new user
    if (stage == OnboardingStage.introduction) {
      _startIntroduction(chatNotifier);
    } else {
      // Resume from current stage
      _continueFromStage(stage, chatNotifier);
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  // Start the introduction
  void _startIntroduction(ChatMessagesNotifier chatNotifier) {
    // Add introduction messages with delays between them
    final introMessages = _storyService.getIntroductionMessages();
    
    // Add first message immediately
    chatNotifier.addTristopherMessage(introMessages[0]);
    _scrollToBottom();
    
    // Add remaining messages with slight delays
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      chatNotifier.addTristopherMessage(introMessages[1]);
      _scrollToBottom();
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        chatNotifier.addTristopherMessage(introMessages[2]);
        _scrollToBottom();
        
        // Move to asking for name
        _askForName(chatNotifier);
      });
    });
  }

  // Continue onboarding from a specific stage
  void _continueFromStage(OnboardingStage stage, ChatMessagesNotifier chatNotifier) {
    switch (stage) {
      case OnboardingStage.displayName:
        _askForName(chatNotifier);
        break;
      case OnboardingStage.goalTitle:
        _askForGoal(chatNotifier);
        break;
      case OnboardingStage.stake:
        _askAboutStake(chatNotifier);
        break;
      case OnboardingStage.challenge:
        _askAbout66DayChallenge(chatNotifier);
        break;
      case OnboardingStage.complete:
      case OnboardingStage.introduction:
        // Should not happen, but handle anyway
        _startIntroduction(chatNotifier);
        break;
    }
  }

  // Ask for the user's name
  void _askForName(ChatMessagesNotifier chatNotifier) {
    final nameMessage = _storyService.getAskNameMessage();
    
    chatNotifier.addInputMessage(
      nameMessage,
      (name) => _handleNameSubmit(name),
      inputHint: 'Enter your name',
    );
    
    _scrollToBottom();
  }

  // Handle name submission
  Future<void> _handleNameSubmit(String name) async {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Add user's name as a message
    chatNotifier.addUserMessage(name);
    
    // Save name
    await _onboardingService.setDisplayName(name);
    
    // Welcome message
    chatNotifier.addTristopherMessage(_storyService.getWelcomeMessage(name));
    _scrollToBottom();
    
    // Move to next step
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _askForGoal(chatNotifier);
    });
  }

  // Ask for the user's goal
  void _askForGoal(ChatMessagesNotifier chatNotifier) {
    // Explain the concept first
    chatNotifier.addTristopherMessage(_storyService.getExplainOneThingMessage());
    _scrollToBottom();
    
    // Then ask for their goal
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      chatNotifier.addInputMessage(
        _storyService.getAskGoalMessage(),
        (goal) => _handleGoalSubmit(goal),
        inputHint: 'Enter your daily goal',
      );
      
      _scrollToBottom();
    });
  }

  // Handle goal submission
  Future<void> _handleGoalSubmit(String goal) async {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Add user's goal as a message
    chatNotifier.addUserMessage(goal);
    
    // Save goal
    await _onboardingService.setGoalTitle(goal);
    
    // Set default goal days (all days of the week)
    await _onboardingService.setGoalDaysOfWeek([1, 2, 3, 4, 5, 6, 7]);
    
    // Response to goal
    chatNotifier.addTristopherMessage(_storyService.getGoalResponseMessage(goal));
    _scrollToBottom();
    
    // Move to next step
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _askAboutStake(chatNotifier);
    });
  }

  // Ask about setting a stake
  void _askAboutStake(ChatMessagesNotifier chatNotifier) {
    // Explain the anti-charity concept
    chatNotifier.addTristopherMessage(_storyService.getExplainAntiCharityMessage());
    _scrollToBottom();
    
    // Then ask if they want to set a stake
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      chatNotifier.addOptionsMessage(
        _storyService.getAskAboutStakeMessage(),
        [
          MessageOption(
            id: 'yes_stake',
            text: 'Yes, I\'ll set a stake.',
            onTap: () => _handleStakeChoice(true),
          ),
          MessageOption(
            id: 'no_stake',
            text: 'No, not right now.',
            onTap: () => _handleStakeChoice(false),
          ),
        ],
      );
      
      _scrollToBottom();
    });
  }

  // Handle stake choice
  void _handleStakeChoice(bool wantsStake) {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Add user's choice as a message
    chatNotifier.addUserMessage(
      wantsStake ? 'Yes, I\'ll set a stake.' : 'No, not right now.'
    );
    
    if (wantsStake) {
      // Ask for stake amount
      chatNotifier.addInputMessage(
        _storyService.getAskStakeAmountMessage(),
        (amount) => _handleStakeAmount(double.tryParse(amount) ?? 1.0),
        inputHint: 'Enter amount (e.g., 10.00)',
      );
    } else {
      // Skip stake, set a default minimal amount
      _handleStakeAmount(0);
    }
    
    _scrollToBottom();
  }

  // Handle stake amount submission
  void _handleStakeAmount(double amount) {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Add amount as a message
    chatNotifier.addUserMessage(amount.toString());
    
    // Response to amount
    chatNotifier.addTristopherMessage(_storyService.getStakeAmountResponseMessage(amount));
    _scrollToBottom();
    
    // If amount > 0, ask for anti-charity choice
    if (amount > 0) {
      _askForAntiCharityChoice(chatNotifier, amount);
    } else {
      // Use default anti-charity for skipped choice
      _completeStakeSetup(amount, AntiCharities.options[0]['id']!);
    }
  }

  // Ask user to choose an anti-charity
  void _askForAntiCharityChoice(ChatMessagesNotifier chatNotifier, double stakeAmount) {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      
      final options = AntiCharities.options.map((charity) => 
        MessageOption(
          id: charity['id']!,
          text: charity['name']!,
          onTap: () => _handleAntiCharityChoice(charity['id']!, stakeAmount),
        )
      ).toList();
      
      chatNotifier.addOptionsMessage(
        _storyService.getChooseAntiCharityMessage(),
        options,
      );
      
      _scrollToBottom();
    });
  }

  // Handle anti-charity choice
  void _handleAntiCharityChoice(String charityId, double stakeAmount) {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Find the selected charity name
    final selectedCharity = AntiCharities.options.firstWhere(
      (charity) => charity['id'] == charityId,
      orElse: () => AntiCharities.options[0],
    );
    
    // Add user's choice as a message
    chatNotifier.addUserMessage(selectedCharity['name']!);
    
    // Complete stake setup
    _completeStakeSetup(stakeAmount, charityId);
  }

  // Save stake and anti-charity information
  Future<void> _completeStakeSetup(double amount, String charityId) async {
    // Save stake information
    await _onboardingService.setStakeInformation(amount, charityId);
    
    // Move to next step
    _askAbout66DayChallenge(ref.read(chatMessagesProvider.notifier));
  }

  // Ask about enrolling in 66-day challenge
  void _askAbout66DayChallenge(ChatMessagesNotifier chatNotifier) {
    chatNotifier.addOptionsMessage(
      _storyService.get66DayChallengeMessage(),
      [
        MessageOption(
          id: 'yes_challenge',
          text: 'Yes, I\'ll take the challenge.',
          onTap: () => _handle66DayChallengeChoice(true),
        ),
        MessageOption(
          id: 'no_challenge',
          text: 'No, not interested.',
          onTap: () => _handle66DayChallengeChoice(false),
        ),
      ],
    );
    
    _scrollToBottom();
  }

  // Handle 66-day challenge choice
  Future<void> _handle66DayChallengeChoice(bool wantsChallenge) async {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Add user's choice as a message
    chatNotifier.addUserMessage(
      wantsChallenge ? 'Yes, I\'ll take the challenge.' : 'No, not interested.'
    );
    
    if (wantsChallenge) {
      // Enroll user in challenge
      await _onboardingService.enroll66DayChallenge();
      
      chatNotifier.addTristopherMessage(
        "Enrolled in the 66-day challenge. I'll be tracking your inevitable failure daily."
      );
    } else {
      chatNotifier.addTristopherMessage(
        "Smart. Setting yourself up for less disappointment. Predictable."
      );
    }
    
    _scrollToBottom();
    
    // Complete onboarding
    _completeOnboarding(chatNotifier);
  }

  // Complete the onboarding process
  void _completeOnboarding(ChatMessagesNotifier chatNotifier) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      chatNotifier.addTristopherMessage(_storyService.getOnboardingCompleteMessage());
      _scrollToBottom();
      
      // Navigate to main screen
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainChat);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    
    return PaperBackgroundScaffold(
      scrollController: _scrollController,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '•‿•',
          style: AppTextStyles.header(size: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatBubble(message: message);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
