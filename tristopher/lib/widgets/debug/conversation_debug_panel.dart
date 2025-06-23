import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../models/conversation/enhanced_message_model.dart';
import '../../models/conversation/conversation_engine.dart';
import '../../providers/conversation/conversation_provider.dart';
import '../../utils/database/conversation_database.dart';

/// Comprehensive Debug Panel for Conversation Variables
/// 
/// This panel displays and allows manipulation of all conversation variables
/// from the script for easier debugging and testing of conversation flows.
class ConversationDebugPanel extends ConsumerStatefulWidget {
  const ConversationDebugPanel({super.key});

  @override
  ConsumerState<ConversationDebugPanel> createState() => _ConversationDebugPanelState();
}

class _ConversationDebugPanelState extends ConsumerState<ConversationDebugPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _conversationVariables = {};
  Map<String, dynamic> _globalVariables = {};
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Controllers for variable editing
  final Map<String, TextEditingController> _controllers = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVariables();
    
    // Auto-refresh variables every 2 seconds
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadVariables();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadVariables() async {
    try {
      // Get variables from the conversation provider (live data)
      final notifier = ref.read(conversationProvider.notifier);
      final variables = notifier.userVariables;
      
      if (mounted) {
        setState(() {
          _conversationVariables = Map<String, dynamic>.from(variables);
          _globalVariables = _getGlobalVariablesFromScript();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to database if provider fails
      try {
        final db = ConversationDatabase();
        final conversationState = await db.getUserState('conversation_state');
        
        if (conversationState != null && conversationState is Map<String, dynamic>) {
          final variables = conversationState['variables'] as Map<String, dynamic>? ?? {};
          
          if (mounted) {
            setState(() {
              _conversationVariables = Map<String, dynamic>.from(variables);
              _globalVariables = _getGlobalVariablesFromScript();
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _conversationVariables = {};
              _globalVariables = _getGlobalVariablesFromScript();
              _isLoading = false;
            });
          }
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        print('Error loading variables: $e, fallback error: $e2');
      }
    }
  }

  /// Get default global variables from the script structure
  Map<String, dynamic> _getGlobalVariablesFromScript() {
    return {
      'robot_personality_level': 5,
      'default_delay_ms': 1000,
      'is_onboarded': false,
      'has_task_set': false,
      'is_overdue': false,
      'is_on_notice': false,
      'has_visited_today': false,
      'current_streak': 0,
      'wager_amount': 0,
      'user_name': '',
      'current_task': '',
      'daily_deadline': '',
      'notification_intensity': 'medium',
      'wager_target': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title and controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Conversation Debug Panel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 8),
                          const SizedBox(width: 4),
                          const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadVariables,
                      tooltip: 'Refresh Variables',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search variables...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Variables', icon: Icon(Icons.data_object, size: 16)),
              Tab(text: 'State', icon: Icon(Icons.psychology, size: 16)),
              Tab(text: 'Actions', icon: Icon(Icons.play_arrow, size: 16)),
              Tab(text: 'Flow', icon: Icon(Icons.timeline, size: 16)),
            ],
          ),
          
          const Divider(height: 1),
          
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVariablesTab(),
                      _buildStateTab(conversationState),
                      _buildActionsTab(),
                      _buildFlowTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesTab() {
    // Get live variables from provider
    final liveVariables = ref.watch(userVariablesProvider);
    final allVariables = {..._globalVariables, ...liveVariables};
    final filteredVariables = _searchQuery.isEmpty
        ? allVariables
        : Map.fromEntries(allVariables.entries.where(
            (entry) => entry.key.toLowerCase().contains(_searchQuery) ||
                       entry.value.toString().toLowerCase().contains(_searchQuery),
          ));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          _buildStatsRow(allVariables),
          const SizedBox(height: 20),
          
          // Core State Variables
          _buildVariableSection(
            'Core State Variables',
            Colors.blue,
            Icons.psychology,
            [
              'is_onboarded',
              'has_task_set',
              'is_overdue',
              'is_on_notice',
              'has_visited_today',
            ],
            filteredVariables,
          ),
          
          // User Information
          _buildVariableSection(
            'User Information',
            Colors.green,
            Icons.person,
            [
              'user_name',
              'current_task',
              'daily_deadline',
              'notification_intensity',
            ],
            filteredVariables,
          ),
          
          // Progress & Streaks
          _buildVariableSection(
            'Progress & Streaks',
            Colors.orange,
            Icons.trending_up,
            [
              'current_streak',
              'total_completions',
              'total_failures',
              'longest_streak',
            ],
            filteredVariables,
          ),
          
          // Wager System
          _buildVariableSection(
            'Wager System',
            Colors.red,
            Icons.attach_money,
            [
              'wager_amount',
              'wager_target',
              'total_lost',
              'total_saved',
            ],
            filteredVariables,
          ),
          
          // System Variables
          _buildVariableSection(
            'System Variables',
            Colors.purple,
            Icons.settings,
            [
              'robot_personality_level',
              'default_delay_ms',
              'last_input',
              'script_version',
              'day_in_journey',
            ],
            filteredVariables,
          ),
          
          // Other Variables
          ...(() {
            final otherKeys = filteredVariables.keys.where((key) => ![
              'is_onboarded', 'has_task_set', 'is_overdue', 'is_on_notice', 'has_visited_today',
              'user_name', 'current_task', 'daily_deadline', 'notification_intensity',
              'current_streak', 'total_completions', 'total_failures', 'longest_streak',
              'wager_amount', 'wager_target', 'total_lost', 'total_saved',
              'robot_personality_level', 'default_delay_ms', 'last_input', 'script_version', 'day_in_journey',
            ].contains(key)).toList();
            if (otherKeys.isNotEmpty) {
              return [
                _buildVariableSection(
                  'Other Variables',
                  Colors.grey,
                  Icons.more_horiz,
                  otherKeys,
                  filteredVariables,
                ),
              ];
            } else {
              return [];
            }
          })(),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> variables) {
    final boolVars = variables.entries.where((e) => e.value is bool).length;
    final stringVars = variables.entries.where((e) => e.value is String).length;
    final numVars = variables.entries.where((e) => e.value is num).length;
    final totalVars = variables.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalVars.toString(), Icons.data_object),
          _buildStatItem('Boolean', boolVars.toString(), Icons.toggle_on),
          _buildStatItem('String', stringVars.toString(), Icons.text_fields),
          _buildStatItem('Number', numVars.toString(), Icons.numbers),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVariableSection(
    String title,
    Color color,
    IconData icon,
    List<String> variableKeys,
    Map<String, dynamic> allVariables,
  ) {
    final sectionVariables = Map.fromEntries(
      variableKeys.where(allVariables.containsKey).map((key) => MapEntry(key, allVariables[key])),
    );

    if (sectionVariables.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sectionVariables.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...sectionVariables.entries.map((entry) => _buildVariableRow(entry.key, entry.value)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVariableRow(String key, dynamic value) {
    final isEditable = value is String || value is num || value is bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Variable type indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getTypeColor(value),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Variable name
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _getTypeString(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Variable value
          Expanded(
            flex: 3,
            child: isEditable
                ? _buildEditableValue(key, value)
                : _buildReadOnlyValue(value),
          ),
          
          // Actions
          if (isEditable) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyToClipboard(value.toString()),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: () => _resetVariable(key),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableValue(String key, dynamic value) {
    if (value is bool) {
      return Switch(
        value: value,
        onChanged: (newValue) => _updateVariable(key, newValue),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
    
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value.toString());
    }
    
    return TextField(
      controller: _controllers[key],
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        isDense: true,
      ),
      onSubmitted: (newValue) => _updateVariableFromText(key, newValue, value.runtimeType),
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildReadOnlyValue(dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        _formatValue(value),
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getTypeColor(dynamic value) {
    if (value is bool) return Colors.purple;
    if (value is String) return Colors.green;
    if (value is num) return Colors.blue;
    return Colors.grey;
  }

  String _getTypeString(dynamic value) {
    if (value is bool) return 'boolean';
    if (value is String) return 'string';
    if (value is int) return 'integer';
    if (value is double) return 'decimal';
    return value.runtimeType.toString().toLowerCase();
  }

  String _formatValue(dynamic value) {
    if (value is String && value.isEmpty) return '(empty)';
    if (value == null) return '(null)';
    return value.toString();
  }

  Widget _buildStateTab(ConversationState conversationState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStateSection(
            'Conversation State',
            [
              ('Messages Count', conversationState.messages.length.toString()),
              ('Language', conversationState.language),
              ('Is Loading', conversationState.isLoading.toString()),
              ('Is Processing', conversationState.isProcessing.toString()),
              ('Awaiting Response', conversationState.awaitingResponse.toString()),
              ('Current Interaction ID', conversationState.currentInteractionId ?? 'none'),
              ('Error', conversationState.error ?? 'none'),
            ],
          ),
          
          _buildStateSection(
            'Engine State',
            [
              ('Engine Awaiting Response', ref.read(conversationProvider.notifier).isEngineAwaitingResponse.toString()),
              ('Awaiting Message ID', ref.read(conversationProvider.notifier).awaitingResponseForMessageId ?? 'none'),
              ('User Variables Count', ref.read(conversationProvider.notifier).userVariables.length.toString()),
              ('Day in Journey', ref.read(conversationProvider.notifier).userState.dayInJourney.toString()),
            ],
          ),
          
          _buildStateSection(
            'Recent Messages',
            conversationState.messages.take(3).map((msg) => (
              '${msg.sender.name} (${msg.type.name})',
              msg.content?.substring(0, 50) ?? 'No content',
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStateSection(String title, List<(String, String)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.$1,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.$2,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conversation Actions
          _buildActionSection(
            'Conversation Actions',
            Colors.blue,
            Icons.chat,
            [
              ('Start Daily Conversation', Icons.play_arrow, () {
                ref.read(conversationProvider.notifier).startDailyConversation();
                Navigator.of(context).pop();
              }),
              ('Clear History', Icons.delete_sweep, () {
                ref.read(conversationProvider.notifier).clearHistory();
                _showSuccess('Conversation history cleared');
              }),
              ('Reset All Data', Icons.delete_forever, () {
                _showResetConfirmation();
              }),
            ],
          ),
          
          // State Manipulation
          _buildActionSection(
            'State Manipulation',
            Colors.orange,
            Icons.psychology,
            [
              ('Set User as Onboarded', Icons.person_add, () {
                _updateVariable('is_onboarded', true);
                _updateVariable('user_name', 'Debug User');
                _showSuccess('User set as onboarded');
              }),
              ('Set Task Complete', Icons.check_circle, () {
                _updateVariable('has_task_set', true);
                _updateVariable('current_task', 'Debug Task');
                _updateVariable('is_overdue', false);
                _showSuccess('Task set as complete');
              }),
              ('Trigger Overdue State', Icons.schedule, () {
                _updateVariable('is_overdue', true);
                _updateVariable('has_task_set', true);
                _showSuccess('Set to overdue state');
              }),
              ('Put User On Notice', Icons.warning, () {
                _updateVariable('is_on_notice', true);
                _showSuccess('User put on notice');
              }),
            ],
          ),
          
          // Simulation Actions
          _buildActionSection(
            'Simulation Actions',
            Colors.green,
            Icons.science,
            [
              ('Simulate Success', Icons.emoji_events, () {
                _simulateSuccess();
              }),
              ('Simulate Failure', Icons.error_outline, () {
                _simulateFailure();
              }),
              ('Add Streak Days', Icons.trending_up, () {
              final liveVariables = ref.read(userVariablesProvider);
              final current = liveVariables['current_streak'] ?? 0;
              _updateVariable('current_streak', current + 5);
                _showSuccess('Added 5 streak days');
                }),
              ('Reset Streak', Icons.restore, () {
                _updateVariable('current_streak', 0);
                _showSuccess('Streak reset to 0');
              }),
            ],
          ),
          
          // Wager Testing
          _buildActionSection(
            'Wager Testing',
            Colors.red,
            Icons.attach_money,
            [
              ('Set Wager \$20', Icons.money, () {
                _updateVariable('wager_amount', 20);
                _updateVariable('wager_target', 'opposing political party');
                _showSuccess('Wager set to \$20');
              }),
              ('Trigger Wager Loss', Icons.money_off, () {
                _simulateWagerLoss();
              }),
              ('Clear Wager', Icons.money_off_csred, () {
                _updateVariable('wager_amount', 0);
                _updateVariable('wager_target', '');
                _showSuccess('Wager cleared');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(
    String title,
    Color color,
    IconData icon,
    List<(String, IconData, VoidCallback)> actions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: action.$3,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(action.$2, size: 20),
                  const SizedBox(width: 12),
                  Text(action.$1),
                ],
              ),
            ),
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFlowTab() {
    final liveVariables = ref.watch(userVariablesProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversation Flow Visualization',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Flow states
          _buildFlowState('New User', !(liveVariables['is_onboarded'] ?? false)),
          _buildFlowState('Onboarded', (liveVariables['is_onboarded'] ?? false) && !(liveVariables['has_task_set'] ?? false)),
          _buildFlowState('Task Set', (liveVariables['has_task_set'] ?? false) && !(liveVariables['is_overdue'] ?? false)),
          _buildFlowState('Overdue', liveVariables['is_overdue'] ?? false),
          _buildFlowState('On Notice', liveVariables['is_on_notice'] ?? false),
          
          const SizedBox(height: 24),
          
          // Current path
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Conversation Path',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_getCurrentConversationPath()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowState(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentConversationPath() {
    final liveVariables = ref.read(userVariablesProvider);
    final isOnboarded = liveVariables['is_onboarded'] ?? false;
    final hasTaskSet = liveVariables['has_task_set'] ?? false;
    final isOverdue = liveVariables['is_overdue'] ?? false;
    final isOnNotice = liveVariables['is_on_notice'] ?? false;

    if (!isOnboarded) {
      return 'not_onboarded → Will trigger onboarding flow';
    } else if (!hasTaskSet) {
      return 'onboarded_no_task → Will ask for task setup';
    } else if (isOverdue && isOnNotice) {
      return 'onboarded_with_task_overdue + on_notice → Strict failure handling';
    } else if (isOverdue) {
      return 'onboarded_with_task_overdue → Will check task status';
    } else {
      return 'onboarded_with_task_current → Normal daily check-in';
    }
  }

  // Helper methods
  Future<void> _updateVariable(String key, dynamic value) async {
    try {
      // Update through the conversation engine for immediate effect
      final engine = ref.read(conversationProvider.notifier);
      
      // Update the database directly for persistence
      final db = ConversationDatabase();
      final currentState = await db.getUserState('conversation_state') ?? {};
      final variables = currentState['variables'] as Map<String, dynamic>? ?? {};
      
      variables[key] = value;
      currentState['variables'] = variables;
      
      await db.saveUserState('conversation_state', currentState);
      
      // Update controller if exists
      if (_controllers.containsKey(key)) {
        _controllers[key]!.text = value.toString();
      }
      
      // Force a refresh of the live variables
      _loadVariables();
      
    } catch (e) {
      _showError('Failed to update variable: $e');
    }
  }

  void _updateVariableFromText(String key, String value, Type expectedType) {
    dynamic convertedValue;
    
    if (expectedType == int) {
      convertedValue = int.tryParse(value) ?? 0;
    } else if (expectedType == double) {
      convertedValue = double.tryParse(value) ?? 0.0;
    } else if (expectedType == bool) {
      convertedValue = value.toLowerCase() == 'true';
    } else {
      convertedValue = value;
    }
    
    _updateVariable(key, convertedValue);
  }

  void _resetVariable(String key) {
    final defaultValue = _globalVariables[key];
    if (defaultValue != null) {
      _updateVariable(key, defaultValue);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Copied to clipboard');
  }

  void _simulateSuccess() {
    final liveVariables = ref.read(userVariablesProvider);
    _updateVariable('current_streak', (liveVariables['current_streak'] ?? 0) + 1);
    _updateVariable('total_completions', (liveVariables['total_completions'] ?? 0) + 1);
    _updateVariable('is_on_notice', false);
    _updateVariable('last_completion_status', true);
    
    final message = EnhancedMessageModel.tristopherText(
      "Well, well. ${liveVariables['user_name'] ?? 'User'} actually followed through. I'm genuinely surprised.",
      style: BubbleStyle.normal,
    );
    
    _addMessageToConversation(message);
    _showSuccess('Success simulated - streak incremented!');
  }

  void _simulateFailure() {
    final liveVariables = ref.read(userVariablesProvider);
    _updateVariable('current_streak', 0);
    _updateVariable('total_failures', (liveVariables['total_failures'] ?? 0) + 1);
    _updateVariable('last_completion_status', false);
    
    final messages = [
      EnhancedMessageModel.tristopherText(
        "And there it is. Another failure. Shocking.",
        style: BubbleStyle.shake,
      ),
    ];
    
    if ((liveVariables['wager_amount'] ?? 0) > 0) {
      messages.add(EnhancedMessageModel.tristopherText(
        "\${liveVariables['wager_amount']} has been transferred to ${liveVariables['wager_target'] ?? 'your anti-charity'}. I hope it stings.",
        style: BubbleStyle.error,
        delayMs: 2000,
      ));
    }
    
    for (final message in messages) {
      _addMessageToConversation(message);
    }
    
    _showSuccess('Failure simulated - streak reset!');
  }

  void _simulateWagerLoss() {
    final liveVariables = ref.read(userVariablesProvider);
    final amount = liveVariables['wager_amount'] ?? 0;
    final target = liveVariables['wager_target'] ?? 'your anti-charity';
    
    if (amount > 0) {
      _updateVariable('total_lost', (liveVariables['total_lost'] ?? 0) + amount);
      
      final message = EnhancedMessageModel.tristopherText(
        "Congratulations. Your \$amount is now going to $target. Hope it was worth it.",
        style: BubbleStyle.error,
      );
      
      _addMessageToConversation(message);
      _showSuccess('Wager loss simulated - \$amount lost!');
    } else {
      _showError('No wager amount set');
    }
  }

  void _addMessageToConversation(EnhancedMessageModel message) {
    final currentMessages = ref.read(conversationProvider).messages;
    ref.read(conversationProvider.notifier).state = ref.read(conversationProvider).copyWith(
      messages: [...currentMessages, message],
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete:\n'
          '\u2022 All conversation history\n'
          '\u2022 User preferences and state\n'
          '\u2022 Cached scripts\n'
          '\u2022 All local data\n\n'
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close debug panel
              
              try {
                await ref.read(conversationProvider.notifier).resetAllData();
                _showSuccess('All data reset successfully!');
              } catch (e) {
                _showError('Failed to reset data: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }
}
