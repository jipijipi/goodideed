import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/models/message_model.dart';
import 'package:tristopher_app/models/user_model.dart';
import 'package:tristopher_app/providers/providers.dart';
import 'package:tristopher_app/services/story_service.dart';
import 'package:tristopher_app/services/user_service.dart';
import 'package:tristopher_app/widgets/chat_bubble.dart';
import 'package:tristopher_app/widgets/common/paper_background_widget.dart';
//import 'package:tristopher_app/widgets/stake_display.dart';

class MainChatScreen extends ConsumerStatefulWidget {
  const MainChatScreen({super.key});

  @override
  ConsumerState<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends ConsumerState<MainChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final StoryService _storyService = StoryService();
  late UserService _userService;
  double _scrollOffset = 0.0; // Re-add for synchronized scrolling
  @override
  void initState() {
    super.initState();
    _userService = ref.read(userServiceProvider);
    
    // Listen to scroll changes for tracking scroll position and auto-scroll behavior
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
      
      if (_scrollController.hasClients) {
        // Check if we're near the bottom (within 20 pixels)
        final isAtBottom = _scrollController.position.maxScrollExtent - _scrollController.offset <= 20;
        
        // If user scrolled and now we're at the bottom, reset the user scrolled flag
        if (isAtBottom && _userHasScrolled) {
          setState(() {
            _userHasScrolled = false;
            _autoScrollEnabled = true;
          });
        } else if (!isAtBottom && !_userHasScrolled) {
          // User has scrolled away from the bottom
          setState(() {
            _userHasScrolled = true;
          });
        }
      }
    });
    
    // Initialize chat on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Variables to track user scroll behavior
  bool _userHasScrolled = false;
  bool _autoScrollEnabled = true;

  // Scroll to bottom of chat when new message is added
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Only auto-scroll if the user hasn't manually scrolled up
        // or if they're already near the bottom
        if (_autoScrollEnabled) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }
  
  // Auto-scroll functionality is retained without parallax

  // Initialize the chat based on user state
  Future<void> _initializeChat() async {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    final needsCheckin = await ref.read(needsDailyCheckinProvider.future);
    final user = await _userService.getCurrentUser();
    
    if (user == null) return;
    
    // If first time today, show Tristopher greeting
    if (needsCheckin) {
      _handleDailyCheckin(user, chatNotifier);
    } else {
      // Just show a greeting if already checked in
      chatNotifier.addTristopherMessage(
        "Welcome back. Your next check-in will be available tomorrow."
      );
      
      // Show current status
      _showCurrentStatus(user, chatNotifier);
    }
  }

  // Handle the daily check-in flow
  void _handleDailyCheckin(UserModel user, ChatMessagesNotifier chatNotifier) {
    final checkInMessage = _storyService.getDailyCheckInMessage(user);
    
    // Add check-in message with yes/no options
    chatNotifier.addOptionsMessage(
      checkInMessage,
      [
        MessageOption(
          id: 'yes',
          text: 'Yes, I did it.',
          onTap: () => _handleCompletionResponse(true, user),
        ),
        MessageOption(
          id: 'no',
          text: 'No, I failed.',
          onTap: () => _handleCompletionResponse(false, user),
        ),
      ],
    );
  }

  // Handle the user's response to whether they completed their goal
  Future<void> _handleCompletionResponse(bool completed, UserModel user) async {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Add user's response as a message
    chatNotifier.addUserMessage(completed ? 'Yes, I did it.' : 'No, I failed.');
    
    // Log the completion
    await _userService.logDailyCompletion(user.uid, completed);
    
    // Get updated user
    final updatedUser = await _userService.getCurrentUser();
    if (updatedUser == null) return;
    
    // Show appropriate response
    if (completed) {
      // Success response
      chatNotifier.addTristopherMessage(
        _storyService.getSuccessResponseMessage(updatedUser),
      );
      
      // Ask if they want to increase stake
      _askAboutIncreasingStake(updatedUser, chatNotifier);
    } else {
      // Failure response
      chatNotifier.addTristopherMessage(
        _storyService.getFailureResponseMessage(updatedUser),
      );
      
      // Show stake loss animation
      ref.read(showStakeFailureAnimationProvider.notifier).state = true;
      
      // Ask about setting a new stake
      _askAboutNewStake(chatNotifier);
    }
    
    // Check for achievements
    //_checkForAchievements();
    
    // Show updated status
    _showCurrentStatus(updatedUser, chatNotifier);
  }

  // Ask if user wants to increase their stake after success
  void _askAboutIncreasingStake(UserModel user, ChatMessagesNotifier chatNotifier) {
    chatNotifier.addOptionsMessage(
      _storyService.getIncreaseStakeMessage(user),
      [
        MessageOption(
          id: 'increase',
          text: 'Yes, increase it.',
          onTap: () => _handleIncreaseStake(user),
        ),
        MessageOption(
          id: 'keep',
          text: 'No, keep it the same.',
          onTap: () => _handleKeepSameStake(),
        ),
      ],
    );
  }

  // Handle user wanting to increase their stake
  void _handleIncreaseStake(UserModel user) {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    chatNotifier.addUserMessage('Yes, increase it.');
    
    chatNotifier.addInputMessage(
      'Enter your new stake amount:',
      (input) => _updateStakeAmount(double.tryParse(input) ?? 0),
      inputHint: 'Enter amount (e.g., 10.00)',
    );
  }

  // Handle user wanting to keep the same stake
  void _handleKeepSameStake() {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    chatNotifier.addUserMessage('No, keep it the same.');
    
    chatNotifier.addTristopherMessage(
      "Fine. Playing it safe. Typical.",
    );
  }

  // Ask if user wants to set a new stake after failure
  void _askAboutNewStake(ChatMessagesNotifier chatNotifier) {
    chatNotifier.addOptionsMessage(
      _storyService.getSetNewStakeAfterFailureMessage(),
      [
        MessageOption(
          id: 'new_stake',
          text: 'Set a new stake.',
          onTap: () => _handleSetNewStake(),
        ),
        MessageOption(
          id: 'no_stake',
          text: 'No stake for now.',
          onTap: () => _handleNoStake(),
        ),
      ],
    );
  }

  // Handle user wanting to set a new stake
  void _handleSetNewStake() {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    chatNotifier.addUserMessage('Set a new stake.');
    
    chatNotifier.addInputMessage(
      'Enter your new stake amount:',
      (input) => _updateStakeAmount(double.tryParse(input) ?? 0),
      inputHint: 'Enter amount (e.g., 10.00)',
    );
  }

  // Handle user not wanting a stake
  void _handleNoStake() {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    chatNotifier.addUserMessage('No stake for now.');
    
    chatNotifier.addTristopherMessage(
      "No consequences, no motivation. A recipe for continued failure. Perfect.",
    );
    
    // Set stake to 0
    _updateStakeAmount(0);
  }

  // Update the user's stake amount
  Future<void> _updateStakeAmount(double amount) async {
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    // Add user's input as a message
    chatNotifier.addUserMessage(amount.toString());
    
    // Get current user
    final user = await _userService.getCurrentUser();
    if (user == null) return;
    
    // Update user with new stake amount
    final updatedUser = user.copyWith(currentStakeAmount: amount);
    await _userService.updateUser(updatedUser);
    
    // Response message
    chatNotifier.addTristopherMessage(
      _storyService.getStakeAmountResponseMessage(amount),
    );
    
    // Update the UI to show new stake amount
    ref.invalidate(userProvider);
  }

  // Show current user status (streak, etc.)
  Future<void> _showCurrentStatus(UserModel user, ChatMessagesNotifier chatNotifier) async {
    // Show streak info
    final completionHistory = await _userService.getCompletionHistory();
    
    // Add streak message
    chatNotifier.addStreakMessage(
      'Current streak: ${user.streakCount} days\nLongest streak: ${user.longestStreak} days',
    );
    
    _scrollToBottom();
  }

  // Check for and display new achievements
  /* Future<void> _checkForAchievements() async {
    final achievements = await ref.read(checkAchievementsProvider.future);
    final chatNotifier = ref.read(chatMessagesProvider.notifier);
    
    for (final achievement in achievements) {
      chatNotifier.addAchievementMessage(achievement);
      _scrollToBottom();
    }
  } */

  @override
  Widget build(BuildContext context) {
    // Watch the messages to detect changes
    final messages = ref.watch(chatMessagesProvider);
    final userAsync = ref.watch(userProvider);
    
    // Listen for changes in the messages list
    ref.listen(chatMessagesProvider, (previous, current) {
      // If messages were added (list got longer), scroll to bottom if auto-scroll is enabled
      if (previous != null && previous.length < current.length && _autoScrollEnabled) {
        _scrollToBottom();
      }
    });
    
    return PaperBackgroundScaffold(
      scrollController: _scrollController,
      appBar: AppBar(
        title: Text(
          'Tristopher',
          style: AppTextStyles.header(size: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
/*         actions: [
          userAsync.when(
            data: (user) {
              final showAnimation = ref.watch(showStakeFailureAnimationProvider);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: StakeDisplay(
                  stakeAmount: user?.currentStakeAmount,
                  showFailureAnimation: showAnimation,
                  onAnimationComplete: () {
                    ref.read(showStakeFailureAnimationProvider.notifier).state = false;
                  },
                ),
              );
            },
            loading: () => const SizedBox(width: 100),
            error: (_, __) => const SizedBox(width: 100),
          ),
        ], */
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        setState(() {
                          _scrollOffset = _scrollController.offset;
                        });
                        
                        // If it's a user-initiated scroll (not programmatic)
                        if (scrollNotification.dragDetails != null) {
                          // Check if scrolling up
                          if (scrollNotification.metrics.maxScrollExtent - _scrollController.offset > 20) {
                            setState(() {
                              _userHasScrolled = true;
                              _autoScrollEnabled = false;
                            });
                          }
                        }
                      } else if (scrollNotification is ScrollEndNotification) {
                        // If user scrolled to bottom, re-enable auto-scroll
                        if (_scrollController.position.maxScrollExtent - _scrollController.offset <= 20) {
                          setState(() {
                            _userHasScrolled = false;
                            _autoScrollEnabled = true;
                          });
                        }
                      }
                      return true;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: messages.length,
                      physics: const AlwaysScrollableScrollPhysics(), // Ensure scrolling works even with few items
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return ChatBubble(message: message);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushNamed(AppRoutes.goalStake);
          } else if (index == 2) {
            Navigator.of(context).pushNamed(AppRoutes.account);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            label: 'Goal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
