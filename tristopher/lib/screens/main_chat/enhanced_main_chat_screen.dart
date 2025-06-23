import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/models/conversation/enhanced_message_model.dart';
import 'package:tristopher_app/providers/conversation/conversation_provider.dart';
import 'package:tristopher_app/widgets/conversation/enhanced_chat_bubble.dart';
import 'package:tristopher_app/widgets/common/drawer/app_drawer.dart';
import 'package:tristopher_app/widgets/common/paper_background_widget.dart';
import 'package:tristopher_app/widgets/debug/conversation_debug_panel.dart';
import 'package:tristopher_app/utils/database/conversation_database.dart';

/// Enhanced Main Chat Screen with the new conversation system.
/// 
/// DAILY CONVERSATION UI FLOW:
/// This screen orchestrates the entire daily interaction with Tristopher through
/// a series of numbered steps that create the "brutally honest companion" experience:
///
/// STEP 1: CONVERSATION INITIALIZATION
/// - Screen loads and triggers ConversationProvider initialization
/// - Provider checks user state (onboarded, task set, deadline status)
/// - Conversation engine selects appropriate daily event variant
///
/// STEP 2: MESSAGE STREAM HANDLING
/// - Engine streams messages based on user's current state
/// - Messages displayed as chat bubbles with Tristopher's pessimistic personality
/// - Auto-scroll keeps conversation flowing smoothly
///
/// STEP 3: INTERACTIVE MESSAGE PROCESSING
/// - Options messages: User selects from pre-defined choices (e.g., task status)
/// - Input messages: User provides free text (e.g., name, task description)
/// - Conversation pauses and waits for user response at each interactive message
///
/// STEP 4: RESPONSE HANDLING & FLOW CONTINUATION
/// - User selections trigger option callbacks and variable updates
/// - Engine processes response and continues with follow-up messages
/// - Flow branches based on user choices (success/failure/excuse paths)
///
/// STEP 5: STATE PERSISTENCE & CONSEQUENCE EXECUTION
/// - All responses saved to database for streak tracking
/// - Wager consequences executed for failures
/// - Updated user state determines next day's conversation variant
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
  /// 
  /// STEP 6: MESSAGE FLOW VISUALIZATION
  /// This ensures users see Tristopher's responses appear naturally,
  /// maintaining the illusion of a real conversation with the pessimistic robot.
  void _setupAutoScroll() {
    // Listen for changes in messages from the conversation engine
    ref.listenManual(conversationMessagesProvider, (previous, next) {
      if (previous != null && previous.length < next.length) {
        // New message added from Tristopher, scroll to bottom to show it
        // This creates the natural chat experience as new messages appear
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
                
              // STEP 7: MAIN CONVERSATION DISPLAY AREA
              // This is where the entire daily conversation unfolds
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
                Builder(
                  builder: (BuildContext context) {
                    return FloatingActionButton(
                      heroTag: "menu_fab",
                      mini: true,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: const Icon(
                        Icons.menu,
                        color: Colors.black87,
                      ),
                    );
                  },
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
  /// 
  /// STEP 8: MESSAGE RENDERING & INTERACTION HANDLING
  /// Each message in the conversation is rendered as a chat bubble.
  /// Interactive messages (options/input) pause the conversation flow
  /// until user responds, then trigger the next phase of the conversation.
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
        // STEP 9: USER INTERACTION POINTS
        // These callbacks handle the critical moments where user responses
        // determine the conversation flow and consequences
        return EnhancedChatBubble(
          key: ValueKey(message.id),
          message: message,
          onOptionSelected: (option) {
            // STEP 9A: Option Selection (e.g., "I completed it!", "I failed...")
            // This triggers consequence logic in the conversation engine
            notifier.selectOption(message.id, option);
          },
          onInputSubmitted: (input) {
            // STEP 9B: Text Input Submission (e.g., user name, task description)
            // This captures user data that personalizes the experience
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
