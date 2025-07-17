import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../config/chat_config.dart';

/// Widget for selecting different chat sequences
class SequenceSelector extends StatelessWidget {
  final String currentSequenceId;
  final Function(String) onSequenceSelected;

  const SequenceSelector({
    super.key,
    required this.currentSequenceId,
    required this.onSequenceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_book),
      tooltip: ChatConfig.sequenceSelectorTooltip,
      onSelected: onSequenceSelected,
      itemBuilder: (BuildContext context) {
        return AppConstants.availableSequences.map((String sequenceId) {
          final displayName = ChatConfig.sequenceDisplayNames[sequenceId] ?? sequenceId;
          final isSelected = sequenceId == currentSequenceId;
          
          return PopupMenuItem<String>(
            value: sequenceId,
            child: Row(
              children: [
                Icon(
                  _getSequenceIcon(sequenceId),
                  color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).iconTheme.color,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                    size: 20.0,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

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
}