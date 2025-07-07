import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import '../constants/ui_constants.dart';
import '../config/chat_config.dart';

class UserVariablesPanel extends StatefulWidget {
  final UserDataService userDataService;

  const UserVariablesPanel({
    super.key,
    required this.userDataService,
  });

  @override
  State<UserVariablesPanel> createState() => UserVariablesPanelState();
}

class UserVariablesPanelState extends State<UserVariablesPanel> {
  Map<String, dynamic> _userData = {};
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
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userData = {};
          _isLoading = false;
        });
      }
    }
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
                : _userData.isEmpty
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
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: UIConstants.panelContentPadding,
                        itemCount: _userData.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final entry = _userData.entries.elementAt(index);
                          return Padding(
                            padding: UIConstants.variableItemPadding,
                            child: Row(
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}