import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import '../../constants/app_constants.dart';
import '../../config/chat_config.dart';
import '../chat_screen/chat_state_manager.dart';

/// Widget responsible for sequence selection dropdown and related functionality
class SequenceSelectorWidget extends StatelessWidget {
  final String? currentSequenceId;
  final ChatStateManager? stateManager;

  const SequenceSelectorWidget({
    super.key,
    this.currentSequenceId,
    this.stateManager,
  });

  IconData _getSequenceIcon(String sequenceId) {
    switch (sequenceId) {
      case 'welcome_seq':
        return Icons.waving_hand;
      case 'onboarding_seq':
        return Icons.person_add;
      case 'taskChecking_seq':
        return Icons.check_circle_outline;
      case 'taskSetting_seq':
        return Icons.assignment;
      case 'sendoff_seq':
        return Icons.logout;
      case 'success_seq':
        return Icons.celebration;
      case 'failure_seq':
        return Icons.support_agent;
      default:
        return Icons.chat;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (stateManager == null) return const SizedBox.shrink();
    
    return Padding(
      padding: UIConstants.variableItemPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Sequence',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentSequenceId,
                isExpanded: true,
                items: AppConstants.availableSequences.map((String sequenceId) {
                  final displayName = ChatConfig.sequenceDisplayNames[sequenceId] ?? sequenceId;
                  return DropdownMenuItem<String>(
                    value: sequenceId,
                    child: Row(
                      children: [
                        Icon(
                          _getSequenceIcon(sequenceId),
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newSequenceId) {
                  if (newSequenceId != null && newSequenceId != currentSequenceId) {
                    stateManager?.switchSequence(newSequenceId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched to $newSequenceId sequence')),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}