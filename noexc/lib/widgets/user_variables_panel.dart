import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import '../services/chat_service.dart';
import '../constants/ui_constants.dart';
import '../config/chat_config.dart';
import 'chat_screen/chat_state_manager.dart';

class UserVariablesPanel extends StatefulWidget {
  final UserDataService userDataService;
  final ChatService? chatService;
  final String? currentSequenceId;
  final int? totalMessages;
  final ChatStateManager? stateManager;

  const UserVariablesPanel({
    super.key,
    required this.userDataService,
    this.chatService,
    this.currentSequenceId,
    this.totalMessages,
    this.stateManager,
  });

  @override
  State<UserVariablesPanel> createState() => UserVariablesPanelState();
}

class UserVariablesPanelState extends State<UserVariablesPanel> {
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _debugData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await widget.userDataService.getAllData();
      final debugInfo = _getDebugInfo();
      
      if (mounted) {
        setState(() {
          _userData = data;
          _debugData = debugInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userData = {};
          _debugData = {};
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getDebugInfo() {
    final debugInfo = <String, dynamic>{};
    
    // Chat System Info
    if (widget.currentSequenceId != null) {
      debugInfo['Current Sequence'] = widget.currentSequenceId!;
    }
    
    if (widget.chatService?.currentSequence != null) {
      debugInfo['Sequence Name'] = widget.chatService!.currentSequence!.name;
      debugInfo['Sequence Description'] = widget.chatService!.currentSequence!.description;
    }
    
    if (widget.totalMessages != null) {
      debugInfo['Total Messages'] = widget.totalMessages!;
    }
    
    // App Info
    debugInfo['Flutter Framework'] = 'Flutter 3.29.3';
    debugInfo['Dart SDK'] = '^3.7.2';
    
    return debugInfo;
  }

  void refreshData() {
    _loadUserData();
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return '[${value.join(', ')}]';
    }
    return value.toString();
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildDataRow(MapEntry<String, dynamic> entry) {
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

  Widget _buildChatControls() {
    if (widget.stateManager == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Chat Controls'),
        Padding(
          padding: UIConstants.variableItemPadding,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await widget.stateManager!.resetChat();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat reset successfully')),
                      );
                    }
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
                    widget.stateManager!.clearMessages();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Messages cleared')),
                      );
                    }
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
                    await widget.stateManager!.reloadSequence();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sequence reloaded')),
                      );
                    }
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
          padding: UIConstants.variableItemPadding,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await _showClearDataConfirmation();
                    if (confirmed == true) {
                      await widget.stateManager!.clearAllUserData();
                      if (mounted) {
                        // Refresh the panel to show empty user data
                        refreshData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All user data cleared')),
                        );
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

  Future<bool?> _showClearDataConfirmation() {
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.panelTopRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(UIConstants.shadowOpacity),
            blurRadius: UIConstants.shadowBlurRadius,
            offset: UIConstants.shadowOffset,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: UIConstants.panelHeaderPadding,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(UIConstants.panelTopRadius)),
            ),
            child: Row(
              children: [
                Text(
                  ChatConfig.userInfoPanelTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: UIConstants.panelEmptyStatePadding,
                    child: CircularProgressIndicator(),
                  )
                : _debugData.isEmpty && _userData.isEmpty
                    ? Padding(
                        padding: UIConstants.panelEmptyStatePadding,
                        child: Text(
                          ChatConfig.emptyDataMessage,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: UIConstants.panelContentPadding,
                        children: [
                          // Chat Controls Section
                          _buildChatControls(),
                          
                          // Debug Information Section
                          if (_debugData.isNotEmpty) ...[
                            _buildSectionHeader('Debug Information'),
                            ..._debugData.entries.map((entry) => _buildDataRow(entry)),
                            const SizedBox(height: 16),
                          ],
                          
                          // User Data Section
                          if (_userData.isNotEmpty) ...[
                            _buildSectionHeader('User Data'),
                            ..._userData.entries.map((entry) => _buildDataRow(entry)),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}