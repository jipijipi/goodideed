import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';
import '../../constants/design_tokens.dart';
import '../user_variables_panel.dart';

/// A widget that manages the debug panel overlay
/// Handles panel visibility, animations, and user interactions
class UserPanelOverlay extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  final UserDataService userDataService;
  final GlobalKey<UserVariablesPanelState>? panelKey;
  final String? currentSequenceId;
  final int? totalMessages;
  final dynamic stateManager; // ChatStateManager

  const UserPanelOverlay({
    super.key,
    required this.isVisible,
    required this.onToggle,
    required this.userDataService,
    this.panelKey,
    this.currentSequenceId,
    this.totalMessages,
    this.stateManager,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay
        if (isVisible) _buildOverlay(),
        
        // Sliding panel
        _buildSlidingPanel(),
      ],
    );
  }

  /// Builds the semi-transparent overlay background
  Widget _buildOverlay() {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        color: Colors.black.withValues(alpha: DesignTokens.overlayOpacity),
        child: const SizedBox.expand(),
      ),
    );
  }

  /// Builds the animated sliding panel
  Widget _buildSlidingPanel() {
    return AnimatedPositioned(
      duration: DesignTokens.panelAnimationDuration,
      curve: DesignTokens.panelAnimationCurve,
      bottom: isVisible ? 0 : -DesignTokens.panelHeight,
      left: 0,
      right: 0,
      height: DesignTokens.panelHeight,
      child: GestureDetector(
        onTap: () {}, // Prevent tap from closing panel
        child: UserVariablesPanel(
          key: panelKey,
          userDataService: userDataService,
          currentSequenceId: currentSequenceId,
          totalMessages: totalMessages,
          stateManager: stateManager,
        ),
      ),
    );
  }
}