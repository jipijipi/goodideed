import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import '../../services/user_data_service.dart';

/// Widget responsible for displaying user data and debug information in a formatted way
class DataDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> debugData;
  final UserDataService? userDataService;
  final VoidCallback? onDataChanged;

  const DataDisplayWidget({
    super.key,
    required this.userData,
    required this.debugData,
    this.userDataService,
    this.onDataChanged,
  });

  @override
  State<DataDisplayWidget> createState() => _DataDisplayWidgetState();
}

class _DataDisplayWidgetState extends State<DataDisplayWidget> {

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

  final Map<String, bool> _editingStates = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _savingStates = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isStringValue(dynamic value) {
    return value is String && !value.startsWith('[') && !value.startsWith('{');
  }

  bool _isIntValue(dynamic value) {
    return value is int;
  }

  bool _isBoolValue(dynamic value) {
    return value is bool;
  }

  bool _isEditableValue(dynamic value) {
    return _isStringValue(value) || _isIntValue(value) || _isBoolValue(value);
  }

  bool _isReadOnlyKey(String key) {
    // Read-only computed values
    return key.contains('isActiveDay') || 
           key.contains('isPastDeadline') || 
           key.contains('visitCount') ||
           key.contains('daysSince');
  }

  Future<void> _saveStringValue(String key, String newValue) async {
    if (widget.userDataService == null) return;
    
    setState(() {
      _savingStates[key] = true;
    });

    try {
      await widget.userDataService!.storeValue(key, newValue);
      await _finalizeSave(key);
    } catch (e) {
      await _handleSaveError(key, e);
    }
  }

  Future<void> _saveIntValue(String key, String newValue) async {
    if (widget.userDataService == null) return;
    
    setState(() {
      _savingStates[key] = true;
    });

    try {
      final intValue = int.parse(newValue);
      await widget.userDataService!.storeValue(key, intValue);
      await _finalizeSave(key);
    } catch (e) {
      await _handleSaveError(key, e);
    }
  }

  Future<void> _saveBoolValue(String key, bool newValue) async {
    if (widget.userDataService == null) return;
    
    setState(() {
      _savingStates[key] = true;
    });

    try {
      await widget.userDataService!.storeValue(key, newValue);
      await _finalizeSave(key);
    } catch (e) {
      await _handleSaveError(key, e);
    }
  }

  Future<void> _finalizeSave(String key) async {
    setState(() {
      _editingStates[key] = false;
      _savingStates[key] = false;
    });
    
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $key'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _handleSaveError(String key, dynamic error) async {
    setState(() {
      _savingStates[key] = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save $key: $error'),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _startEditing(String key, dynamic value) {
    final controller = TextEditingController(text: value.toString());
    _controllers[key] = controller;
    
    setState(() {
      _editingStates[key] = true;
    });
  }

  void _cancelEditing(String key) {
    _controllers[key]?.dispose();
    _controllers.remove(key);
    
    setState(() {
      _editingStates[key] = false;
    });
  }

  Widget _buildInputWidget(BuildContext context, String key, dynamic value) {
    if (_isBoolValue(value)) {
      return Switch(
        value: value as bool,
        onChanged: (newValue) {
          _saveBoolValue(key, newValue);
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else if (_isIntValue(value)) {
      return TextField(
        controller: _controllers[key],
        style: Theme.of(context).textTheme.bodyMedium,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onSubmitted: (newValue) {
          _saveIntValue(key, newValue);
        },
      );
    } else {
      // String input
      return TextField(
        controller: _controllers[key],
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onSubmitted: (newValue) {
          _saveStringValue(key, newValue);
        },
      );
    }
  }

  Widget _buildDataRow(BuildContext context, MapEntry<String, dynamic> entry) {
    final isEditing = _editingStates[entry.key] ?? false;
    final isSaving = _savingStates[entry.key] ?? false;
    final isIntValue = _isIntValue(entry.value);
    final isBoolValue = _isBoolValue(entry.value);
    final isReadOnly = _isReadOnlyKey(entry.key);
    final canEdit = _isEditableValue(entry.value) && !isReadOnly && widget.userDataService != null;

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
                child: (isBoolValue && canEdit)
                    ? _buildInputWidget(context, entry.key, entry.value)
                    : isEditing
                        ? _buildInputWidget(context, entry.key, entry.value)
                        : Text(
                            _formatValue(entry.value),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
              ),
              if (canEdit && !isBoolValue) ...[
                const SizedBox(width: 8),
                if (isSaving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.save, size: 16),
                    onPressed: () {
                      final value = _controllers[entry.key]?.text ?? '';
                      if (isIntValue) {
                        _saveIntValue(entry.key, value);
                      } else {
                        _saveStringValue(entry.key, value);
                      }
                    },
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Save',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, size: 16),
                    onPressed: () => _cancelEditing(entry.key),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Cancel',
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _startEditing(entry.key, entry.value),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Edit',
                  ),
              ],
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
        if (widget.debugData.isNotEmpty) ...[
          _buildSectionHeader(context, 'Debug Information'),
          ...widget.debugData.entries.map((entry) => _buildDataRow(context, entry)),
          const SizedBox(height: 16),
        ],
        
        // User Data Section
        if (widget.userData.isNotEmpty) ...[
          _buildSectionHeader(context, 'User Data'),
          ...widget.userData.entries.map((entry) => _buildDataRow(context, entry)),
        ],
      ],
    );
  }
}