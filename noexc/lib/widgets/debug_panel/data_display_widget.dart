import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

/// Widget responsible for displaying user data and debug information in a formatted way
class DataDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> debugData;

  const DataDisplayWidget({
    super.key,
    required this.userData,
    required this.debugData,
  });

  String _formatValue(dynamic value) {
    if (value is List) {
      return '[${value.join(', ')}]';
    }
    return value.toString();
  }

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

  Widget _buildDataRow(BuildContext context, MapEntry<String, dynamic> entry) {
    return Padding(
      padding: UIConstants.variableItemPadding,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: UIConstants.variableKeySpacing),
              Expanded(
                flex: 3,
                child: Text(
                  _formatValue(entry.value),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debug Information Section
        if (debugData.isNotEmpty) ...[
          _buildSectionHeader(context, 'Debug Information'),
          ...debugData.entries.map((entry) => _buildDataRow(context, entry)),
          const SizedBox(height: 16),
        ],
        
        // User Data Section
        if (userData.isNotEmpty) ...[
          _buildSectionHeader(context, 'User Data'),
          ...userData.entries.map((entry) => _buildDataRow(context, entry)),
        ],
      ],
    );
  }
}