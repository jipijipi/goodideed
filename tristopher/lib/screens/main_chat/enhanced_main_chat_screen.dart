import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/models/conversation/enhanced_message_model.dart';
import 'package:tristopher_app/providers/conversation/conversation_provider.dart';
import 'package:tristopher_app/widgets/conversation/enhanced_chat_bubble.dart';
import 'package:tristopher_app/widgets/common/drawer/app_drawer.dart';
import 'package:tristopher_app/widgets/common/paper_background_widget.dart';
import 'package:tristopher_app/utils/database/conversation_database.dart';

/// Enhanced Main Chat Screen with the new conversation system.
/// 
/// This implementation seamlessly integrates the new conversation engine
/// while maintaining the existing app structure and design patterns.
class MainChatScreen extends ConsumerStatefulWidget {
  const MainChatScreen({super.key});

  @override
  ConsumerState<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends ConsumerState<MainChatScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Set up auto-scroll behavior
    _setupAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Set up automatic scrolling when new messages arrive.
  void _setupAutoScroll() {
    // Listen for changes in messages
    ref.listenManual(conversationMessagesProvider, (previous, next) {
      if (previous != null && previous.length < next.length) {
        // New message added, scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationProvider);
    final conversationNotifier = ref.read(conversationProvider.notifier);
    
    return PaperBackgroundScaffold(
      scrollController: _scrollController,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Error banner
              if (conversationState.error != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conversationState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // Clear error
                          ref.read(conversationProvider.notifier).clearError();
                        },
                      ),
                    ],
                  ),
                ),
                
              // Main message area
              Expanded(
                child: _buildMessageList(conversationState, conversationNotifier),
              ),
              
              // Bottom status area
              //_buildBottomStatus(conversationState),
            ],
          ),
          
          // Floating action buttons positioned on the right side
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              children: [
                // Menu button
                FloatingActionButton(
                  heroTag: "menu_fab",
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Debug button (remove in production)
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  FloatingActionButton(
                    heroTag: "debug_fab",
                    mini: true,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    onPressed: () => _showDebugPanel(context),
                    child: const Icon(
                      Icons.bug_report,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
    );
  }

  /// Build the main message list.
  Widget _buildMessageList(
    ConversationState state,
    ConversationNotifier notifier,
  ) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing Tristopher...',
              style: AppTextStyles.body(),
            ),
          ],
        ),
      );
    }
    
    if (state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No messages yet. Tristopher is preparing his first insult...',
            style: AppTextStyles.body(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return EnhancedChatBubble(
          key: ValueKey(message.id),
          message: message,
          onOptionSelected: (option) {
            // Handle option selection
            notifier.selectOption(message.id, option);
          },
          onInputSubmitted: (input) {
            // Handle input submission
            notifier.submitInput(message.id, input);
          },
        );
      },
    );
  }

  /// Build the bottom status area.
  /* Widget _buildBottomStatus(ConversationState state) {
    if (!state.isProcessing && !state.awaitingResponse) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(
          top: BorderSide(
            color: AppColors.backgroundColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (state.isProcessing) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tristopher is thinking...',
              style: AppTextStyles.body().copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (state.awaitingResponse && !state.isProcessing)
            Text(
              'Waiting for your response...',
              style: AppTextStyles.body(),
            ),
        ],
      ),
    );
  } */

  /// Show debug panel for testing (development only).
  void _showDebugPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConversationDebugPanel(),
    );
  }
}

/// Debug panel for testing the conversation system.
/// 
/// This widget provides quick access to test different scenarios
/// and states during development.
class ConversationDebugPanel extends ConsumerWidget {
  const ConversationDebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationState = ref.watch(conversationProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conversation Debug Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // State Info
                  _buildSection(
                    'Current State',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Messages', '${conversationState.messages.length}'),
                        _buildInfoRow('Language', conversationState.language),
                        _buildInfoRow('Processing', conversationState.isProcessing.toString()),
                        _buildInfoRow('Awaiting Response', conversationState.awaitingResponse.toString()),
                      ],
                    ),
                  ),
                  
                  // Test Actions
                  _buildSection(
                    'Test Actions',
                    Column(
                      children: [
                        _buildActionButton(
                          'Start Daily Conversation',
                          Icons.play_arrow,
                          () {
                            ref.read(conversationProvider.notifier).startDailyConversation();
                            Navigator.of(context).pop();
                          },
                        ),
                        _buildActionButton(
                          'Clear History',
                          Icons.delete_sweep,
                          () {
                            ref.read(conversationProvider.notifier).clearHistory();
                            Navigator.of(context).pop();
                          },
                        ),
                        _buildActionButton(
                          'Switch to Spanish',
                          Icons.language,
                          () {
                            ref.read(conversationProvider.notifier).changeLanguage('es');
                            Navigator.of(context).pop();
                          },
                        ),
                        _buildActionButton(
                          'Simulate Achievement',
                          Icons.emoji_events,
                          () {
                            _simulateAchievement(ref);
                            Navigator.of(context).pop();
                          },
                        ),
                        _buildActionButton(
                          'Simulate Failure',
                          Icons.error_outline,
                          () {
                            _simulateFailure(ref);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // User State
                  _buildSection(
                    'User State Variables',
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getUserState(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        
                        final state = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.entries.map((entry) {
                            return _buildInfoRow(entry.key, entry.value.toString());
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserState() async {
    final db = ConversationDatabase();
    final state = await db.getUserState('conversation_state');
    if (state != null && state is Map<String, dynamic>) {
      return state['variables'] ?? {};
    }
    return {};
  }

  void _simulateAchievement(WidgetRef ref) {
    final message = EnhancedMessageModel.achievement(
      '🏆 Test Achievement Unlocked!',
      achievementData: {
        'id': 'test_achievement',
        'points': 100,
      },
    );
    
    // Add directly to state for testing
    final currentMessages = ref.read(conversationProvider).messages;
    ref.read(conversationProvider.notifier).state = ref.read(conversationProvider).copyWith(
      messages: [...currentMessages, message],
    );
  }

  void _simulateFailure(WidgetRef ref) {
    final messages = [
      EnhancedMessageModel.tristopherText(
        "And there it is. Another failure. Shocking.",
        style: BubbleStyle.shake,
      ),
      EnhancedMessageModel.tristopherText(
        "\$10.00 has been transferred to your anti-charity. I hope it stings.",
        style: BubbleStyle.error,
        delayMs: 2000,
      ),
    ];
    
    // Add messages with delays
    final currentMessages = ref.read(conversationProvider).messages;
    ref.read(conversationProvider.notifier).state = ref.read(conversationProvider).copyWith(
      messages: [...currentMessages, ...messages],
    );
  }
}
