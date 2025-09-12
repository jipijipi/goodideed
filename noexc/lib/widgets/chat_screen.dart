import 'package:flutter/material.dart';
import 'chat_screen/chat_state_manager.dart';
import 'chat_screen/chat_message_list.dart';
import 'chat_screen/user_panel_overlay.dart';
import 'chat_screen/frosted_glass_overlay.dart';
import 'chat_screen/rive_overlay_layer.dart';
import 'user_variables_panel.dart';
import '../services/service_locator.dart';

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
    // Reduce noise: avoid print; rely on LoggerService where necessary
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
      body: Stack(
        key: const ValueKey('chat_screen_stack'),
        children: [
          // Rive overlay layers behind UI (zones 3, 4)
          RiveOverlayLayerBehindUI(
            service: ServiceLocator.instance.riveOverlayService,
          ),

          // Main chat content
          ChatMessageList(
            messages: _stateManager.displayedMessages,
            scrollController: _stateManager.scrollController,
            onChoiceSelected: _stateManager.onChoiceSelected,
            onTextSubmitted: _stateManager.onTextInputSubmitted,
            currentTextInputMessage: _stateManager.currentTextInputMessage,
            animatedListKey: _stateManager.animatedListKey,
          ),

          // Mid-ground Rive overlay layer (zone 4) above messages, below panels
          RiveOverlayLayerMidUI(
            service: ServiceLocator.instance.riveOverlayService,
          ),

          // User panel overlay
          UserPanelOverlay(
            isVisible: _stateManager.isPanelVisible,
            onToggle: _stateManager.togglePanel,
            userDataService: _stateManager.userDataService,
            panelKey: _panelKey,
            currentSequenceId: _stateManager.currentSequenceId,
            totalMessages: _stateManager.displayedMessages.length,
            stateManager: _stateManager,
          ),

          // Frosted glass overlay in upper area
          const FrostedGlassOverlay(),

          // Rive overlay layer above UI (zone 2)
          RiveOverlayLayerFrontUI(
            service: ServiceLocator.instance.riveOverlayService,
          ),

          // Floating Action Buttons in top-right corner
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: "theme_toggle",
                  onPressed: widget.onThemeToggle,
                  tooltip: 'Toggle Theme',
                  child: const Icon(Icons.brightness_6),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "debug_panel",
                  onPressed: _stateManager.togglePanel,
                  tooltip: 'Debug Panel',
                  child: const Icon(Icons.bug_report),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
