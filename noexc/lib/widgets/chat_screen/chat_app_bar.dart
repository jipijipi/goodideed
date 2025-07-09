import 'package:flutter/material.dart';
import '../../config/chat_config.dart';

/// A custom app bar for the chat screen
/// Provides theme toggle and debug panel access
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onThemeToggle;
  final VoidCallback? onPanelToggle;

  const ChatAppBar({
    super.key,
    this.onThemeToggle,
    this.onPanelToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(ChatConfig.chatScreenTitle),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        _buildThemeToggleButton(),
        _buildUserInfoButton(),
      ],
    );
  }

  /// Builds the theme toggle button
  Widget _buildThemeToggleButton() {
    return IconButton(
      icon: const Icon(Icons.brightness_6),
      onPressed: onThemeToggle,
      tooltip: ChatConfig.toggleThemeTooltip,
    );
  }

  /// Builds the debug panel button
  Widget _buildUserInfoButton() {
    return IconButton(
      icon: const Icon(Icons.bug_report),
      onPressed: onPanelToggle,
      tooltip: ChatConfig.userInfoTooltip,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}