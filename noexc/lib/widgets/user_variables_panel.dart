import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import '../services/chat_service.dart';
import '../services/scenario_manager.dart';
import '../constants/ui_constants.dart';
import '../config/chat_config.dart';
import 'chat_screen/chat_state_manager.dart';
import 'debug_panel/data_display_widget.dart';
import 'debug_panel/chat_controls_widget.dart';
import 'debug_panel/sequence_selector_widget.dart';
import 'debug_panel/user_data_manager.dart';
import 'debug_panel/date_time_picker_widget.dart';

/// Main user variables panel that orchestrates the display of user data and debug controls
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
  late final UserDataManager _dataManager;
  
  // Scenario-related state
  Map<String, dynamic> _scenarios = {};
  String? _selectedScenario;
  bool _isApplyingScenario = false;

  @override
  void initState() {
    super.initState();
    _dataManager = UserDataManager(
      userDataService: widget.userDataService,
      chatService: widget.chatService,
      currentSequenceId: widget.currentSequenceId,
      totalMessages: widget.totalMessages,
    );
    _loadUserData();
    _loadScenarios();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _dataManager.loadAllData();
      
      if (mounted) {
        setState(() {
          _userData = data.userData;
          _debugData = data.debugData;
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

  void refreshData() {
    _loadUserData();
  }

  Future<void> _loadScenarios() async {
    try {
      final scenarios = await ScenarioManager.loadScenarios();
      if (mounted) {
        setState(() {
          _scenarios = scenarios;
        });
      }
    } catch (e) {
      print('Failed to load scenarios: $e');
    }
  }

  Future<void> _applyScenario() async {
    if (_selectedScenario == null) return;

    setState(() {
      _isApplyingScenario = true;
    });

    try {
      await ScenarioManager.applyScenario(_selectedScenario!, widget.userDataService);
      
      // Refresh the data to show updated values
      refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied scenario: ${_scenarios[_selectedScenario!]['name']}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply scenario: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingScenario = false;
        });
      }
    }
  }

  Widget _buildScenarioSection() {
    if (_scenarios.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Scenarios',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a scenario...'),
                    value: _selectedScenario,
                    items: _scenarios.entries.map((entry) {
                      final scenario = entry.value as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              scenario['name'] ?? entry.key,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (scenario['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  scenario['description'],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedScenario = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedScenario != null && !_isApplyingScenario 
                      ? _applyScenario 
                      : null,
                  child: _isApplyingScenario
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
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
            color: Colors.black.withValues(alpha: UIConstants.shadowOpacity),
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
                          ChatControlsWidget(
                            stateManager: widget.stateManager,
                            onDataRefresh: refreshData,
                          ),
                          
                          // Test Scenarios Section
                          _buildScenarioSection(),
                          
                          // Sequence Selector
                          SequenceSelectorWidget(
                            currentSequenceId: widget.currentSequenceId,
                            stateManager: widget.stateManager,
                          ),
                          
                          // Date/Time Picker Section
                          DateTimePickerWidget(
                            userDataService: widget.userDataService,
                            onDataChanged: refreshData,
                          ),
                          
                          // Data Display Section
                          DataDisplayWidget(
                            userData: _userData,
                            debugData: _debugData,
                            userDataService: widget.userDataService,
                            onDataChanged: refreshData,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}