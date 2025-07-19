import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import '../services/chat_service.dart';
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
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}