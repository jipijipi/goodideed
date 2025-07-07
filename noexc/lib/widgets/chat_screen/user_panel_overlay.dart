import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';
import '../../constants/ui_constants.dart';
import '../user_variables_panel.dart';

/// A widget that manages the user variables panel overlay
/// Handles panel visibility, animations, and user interactions
class UserPanelOverlay extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  final UserDataService userDataService;
  final GlobalKey<UserVariablesPanelState>? panelKey;

  const UserPanelOverlay({
    super.key,
    required this.isVisible,
    required this.onToggle,
    required this.userDataService,
    this.panelKey,
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
        color: Colors.black.withOpacity(UIConstants.overlayOpacity),
        child: const SizedBox.expand(),
      ),
    );
  }

  /// Builds the animated sliding panel
  Widget _buildSlidingPanel() {
    return AnimatedPositioned(
      duration: UIConstants.panelAnimationDuration,
      curve: UIConstants.panelAnimationCurve,
      bottom: isVisible ? 0 : -UIConstants.panelHeight,
      left: 0,
      right: 0,
      height: UIConstants.panelHeight,
      child: GestureDetector(
        onTap: () {}, // Prevent tap from closing panel
        child: UserVariablesPanel(
          key: panelKey,
          userDataService: userDataService,
        ),
      ),
    );
  }
}