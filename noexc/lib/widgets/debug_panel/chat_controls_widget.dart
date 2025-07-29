import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';
import '../chat_screen/chat_state_manager.dart';
import 'debug_status_area.dart';

/// Widget responsible for chat control actions (reset, clear, reload, clear all data)
class ChatControlsWidget extends StatelessWidget {
  final ChatStateManager? stateManager;
  final VoidCallback? onDataRefresh;
  final DebugStatusController? statusController;

  const ChatControlsWidget({
    super.key,
    this.stateManager,
    this.onDataRefresh,
    this.statusController,
  });

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<bool?> _showClearDataConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will permanently delete all stored user information. '
            'This action cannot be undone.\n\nAre you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (stateManager == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Chat Controls'),
        
        // First row with main chat controls
        Padding(
          padding: DesignTokens.variableItemPadding,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await stateManager!.resetChat();
                    statusController?.addSuccess('Chat reset successfully');
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    stateManager!.clearMessages();
                    statusController?.addSuccess('Messages cleared');
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await stateManager!.reloadSequence();
                    statusController?.addSuccess('Sequence reloaded');
                  },
                  icon: const Icon(Icons.file_download, size: 16),
                  label: const Text('Reload'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Second row with Clear All Data button
        Padding(
          padding: DesignTokens.variableItemPadding,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await _showClearDataConfirmation(context);
                    if (confirmed == true) {
                      await stateManager!.clearAllUserData();
                      if (context.mounted) {
                        // Refresh the panel to show empty user data
                        onDataRefresh?.call();
                        statusController?.addSuccess('All user data cleared');
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, size: 16),
                  label: const Text('Clear All Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()), // Take up remaining space
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}