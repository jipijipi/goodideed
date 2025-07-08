import 'package:flutter/material.dart';
import 'chat_screen/chat_state_manager.dart';
import 'chat_screen/chat_app_bar.dart';
import 'chat_screen/chat_message_list.dart';
import 'chat_screen/user_panel_overlay.dart';
import 'user_variables_panel.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  
  const ChatScreen({super.key, this.onThemeToggle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatStateManager _stateManager;
  final GlobalKey<UserVariablesPanelState> _panelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _stateManager = ChatStateManager();
    _stateManager.addListener(_onStateChanged);
    _stateManager.initialize();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when state manager notifies changes
      });
      
      // Refresh panel data when it becomes visible
      if (_stateManager.isPanelVisible) {
        _panelKey.currentState?.refreshData();
      }
    }
  }


  @override
  void dispose() {
    _stateManager.removeListener(_onStateChanged);
    _stateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        onThemeToggle: widget.onThemeToggle,
        onPanelToggle: _stateManager.togglePanel,
        currentSequenceId: _stateManager.currentSequenceId,
        onSequenceChanged: _stateManager.switchSequence,
      ),
      body: Stack(
        children: [
          // Main chat content
          ChatMessageList(
            messages: _stateManager.displayedMessages,
            scrollController: _stateManager.scrollController,
            onChoiceSelected: _stateManager.onChoiceSelected,
            onTextSubmitted: _stateManager.onTextInputSubmitted,
            currentTextInputMessage: _stateManager.currentTextInputMessage,
          ),
          
          // User panel overlay
          UserPanelOverlay(
            isVisible: _stateManager.isPanelVisible,
            onToggle: _stateManager.togglePanel,
            userDataService: _stateManager.userDataService,
            panelKey: _panelKey,
          ),
        ],
      ),
    );
  }


}