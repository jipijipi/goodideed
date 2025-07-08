import 'package:flutter/material.dart';
import '../../config/chat_config.dart';
import '../sequence_selector.dart';

/// A custom app bar for the chat screen
/// Provides sequence selection, theme toggle and user info panel access
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onThemeToggle;
  final VoidCallback? onPanelToggle;
  final String currentSequenceId;
  final Function(String) onSequenceChanged;

  const ChatAppBar({
    super.key,
    this.onThemeToggle,
    this.onPanelToggle,
    required this.currentSequenceId,
    required this.onSequenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(ChatConfig.chatScreenTitle),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        _buildSequenceSelector(),
        _buildThemeToggleButton(),
        _buildUserInfoButton(),
      ],
    );
  }

  /// Builds the sequence selector
  Widget _buildSequenceSelector() {
    return SequenceSelector(
      currentSequenceId: currentSequenceId,
      onSequenceSelected: onSequenceChanged,
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

  /// Builds the user info panel button
  Widget _buildUserInfoButton() {
    return IconButton(
      icon: const Icon(Icons.person),
      onPressed: onPanelToggle,
      tooltip: ChatConfig.userInfoTooltip,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}