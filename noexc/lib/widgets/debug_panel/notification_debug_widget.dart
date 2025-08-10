import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import 'debug_status_area.dart';

/// Debug widget for displaying and controlling notification state
class NotificationDebugWidget extends StatefulWidget {
  final DebugStatusController? statusController;
  final VoidCallback? onDataRefresh;

  const NotificationDebugWidget({
    super.key,
    this.statusController,
    this.onDataRefresh,
  });

  @override
  State<NotificationDebugWidget> createState() => _NotificationDebugWidgetState();
}

class _NotificationDebugWidgetState extends State<NotificationDebugWidget> {
  Map<String, dynamic> _notificationStatus = {};
  List<Map<String, dynamic>> _scheduledNotifications = [];
  Map<String, dynamic> _platformInfo = {};
  Map<String, dynamic> _permissionStatus = {};
  Map<String, dynamic> _appState = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotificationData();
  }

  Future<void> _loadNotificationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!ServiceLocator.instance.isInitialized) {
        throw Exception('Service locator not initialized');
      }

      final notificationService = ServiceLocator.instance.notificationService;
      
      final status = await notificationService.getNotificationStatus();
      final scheduled = await notificationService.getScheduledNotificationDetails();
      final platform = notificationService.getPlatformInfo();
      
      // Get detailed permission status
      final permissionStatus = await notificationService.getPermissionStatus();
      final permissionData = {
        'status': permissionStatus.name,
        'description': permissionStatus.description,
        'canScheduleNotifications': permissionStatus.canScheduleNotifications,
        'shouldRequestPermissions': permissionStatus.shouldRequestPermissions,
        'needsManualSettings': permissionStatus.needsManualSettings,
      };
      
      // Get app state if available
      Map<String, dynamic> appStateData = {};
      try {
        final appStateService = ServiceLocator.instance.appStateService;
        appStateData = await appStateService.getNotificationState();
      } catch (e) {
        appStateData = {'error': 'AppStateService not available: $e'};
      }

      if (mounted) {
        setState(() {
          _notificationStatus = status;
          _scheduledNotifications = scheduled;
          _platformInfo = platform;
          _permissionStatus = permissionData;
          _appState = appStateData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      await notificationService.cancelAllNotifications();
      
      widget.statusController?.addSuccess('All notifications canceled');
      widget.onDataRefresh?.call();
      _loadNotificationData();
    } catch (e) {
      widget.statusController?.addError('Failed to cancel notifications: $e');
    }
  }

  Future<void> _forceReschedule() async {
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      await notificationService.forceReschedule();
      
      widget.statusController?.addSuccess('Notifications rescheduled');
      widget.onDataRefresh?.call();
      _loadNotificationData();
    } catch (e) {
      widget.statusController?.addError('Failed to reschedule notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      final granted = await notificationService.requestPermissions();
      
      if (granted) {
        widget.statusController?.addSuccess('Notification permissions granted');
      } else {
        widget.statusController?.addInfo('Notification permissions denied or unavailable');
      }
      
      _loadNotificationData();
    } catch (e) {
      widget.statusController?.addError('Failed to request permissions: $e');
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final notificationService = ServiceLocator.instance.notificationService;
      final status = await notificationService.getPermissionStatus();
      
      widget.statusController?.addInfo('Permission Status: ${status.description}');
      _loadNotificationData();
    } catch (e) {
      widget.statusController?.addError('Failed to check permission status: $e');
    }
  }

  Future<void> _clearAppState() async {
    try {
      final appStateService = ServiceLocator.instance.appStateService;
      await appStateService.clearNotificationState();
      
      widget.statusController?.addSuccess('App notification state cleared');
      _loadNotificationData();
    } catch (e) {
      widget.statusController?.addError('Failed to clear app state: $e');
    }
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

  Widget _buildStatusSection() {
    if (_notificationStatus.isEmpty) return const SizedBox.shrink();

    final isEnabled = _notificationStatus['isEnabled'] ?? false;
    final lastScheduled = _notificationStatus['lastScheduled'];
    final intensity = _notificationStatus['remindersIntensity'] ?? 0;
    final deadlineTime = _notificationStatus['deadlineTime'] ?? 'Not set';
    final pendingCount = _notificationStatus['pendingCount'] ?? 0;
    final timezone = _notificationStatus['timezone'] ?? 'Unknown';
    final currentTime = _notificationStatus['currentTime'] ?? 'Unknown';
    final permissions = _notificationStatus['permissions'] ?? 'Unknown';
    final platform = _notificationStatus['platform'] ?? 'Unknown';
    final isIOSSimulator = _notificationStatus['isIOSSimulator'] ?? false;
    final fallbackDate = _notificationStatus['fallbackDate'];
    final fallbackReason = _notificationStatus['fallbackReason'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header with warning for iOS simulator
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: isEnabled ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.green : Colors.red,
                  ),
                ),
                if (isIOSSimulator) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Simulator',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '$pendingCount pending',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: pendingCount > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Basic info
            _buildInfoRow('Platform:', platform),
            _buildInfoRow('Intensity:', intensity.toString()),
            _buildInfoRow('Deadline Time:', deadlineTime),
            
            // Timezone info
            _buildInfoRow('Timezone:', timezone),
            _buildInfoRow('Current Time:', currentTime.length > 25 ? currentTime.substring(0, 25) + '...' : currentTime),
            
            // Permission info
            _buildInfoRow('Permissions:', permissions),
            
            if (lastScheduled != null) 
              _buildInfoRow('Last Scheduled:', DateTime.parse(lastScheduled).toLocal().toString().substring(0, 19)),
              
            // Fallback information if available
            if (fallbackDate != null)
              _buildInfoRow('Fallback Date:', fallbackDate),
            if (fallbackReason != null)
              _buildInfoRow('Fallback Reason:', fallbackReason),
              
            // iOS Simulator warning
            if (isIOSSimulator)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'iOS Simulator detected. Notifications may not work properly. Test on a real device for accurate results.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_scheduledNotifications.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'No scheduled notifications',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduled Notifications (${_scheduledNotifications.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...(_scheduledNotifications.map((notification) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('ID:', notification['id'].toString()),
                    _buildInfoRow('Title:', notification['title'] ?? 'No title'),
                    _buildInfoRow('Body:', notification['body'] ?? 'No body'),
                    _buildInfoRow('Scheduled:', notification['scheduledTime'] ?? 'Unknown'),
                    if (notification['timeUntil'] != null && notification['timeUntil'].isNotEmpty)
                      _buildInfoRow('Time Until:', notification['timeUntil']),
                    _buildInfoRow('Type:', notification['type'] ?? 'Unknown'),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionStatusSection() {
    if (_permissionStatus.isEmpty) return const SizedBox.shrink();

    final status = _permissionStatus['status'] ?? 'unknown';
    final description = _permissionStatus['description'] ?? 'No description';
    final canSchedule = _permissionStatus['canScheduleNotifications'] ?? false;
    final shouldRequest = _permissionStatus['shouldRequestPermissions'] ?? false;
    final needsManual = _permissionStatus['needsManualSettings'] ?? false;

    // Color coding based on status
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    
    switch (status) {
      case 'granted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'denied':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'notRequested':
        statusColor = Colors.blue;
        statusIcon = Icons.notifications_none;
        break;
      case 'restricted':
        statusColor = Colors.orange;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Permission Status',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Status:', status.toUpperCase()),
            _buildInfoRow('Description:', description),
            _buildInfoRow('Can Schedule:', canSchedule ? 'Yes' : 'No'),
            _buildInfoRow('Should Request:', shouldRequest ? 'Yes' : 'No'),
            _buildInfoRow('Needs Manual:', needsManual ? 'Yes' : 'No'),
            
            // Show helpful actions based on status
            if (shouldRequest || needsManual) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shouldRequest 
                          ? 'Ready to request permissions - use "Request Permissions" button'
                          : 'Permission denied - user must enable in Settings manually',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor == Colors.grey ? Colors.grey.shade800 : 
                                statusColor == Colors.green ? Colors.green.shade800 :
                                statusColor == Colors.red ? Colors.red.shade800 :
                                statusColor == Colors.blue ? Colors.blue.shade800 :
                                statusColor == Colors.orange ? Colors.orange.shade800 :
                                Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppStateSection() {
    if (_appState.isEmpty) return const SizedBox.shrink();

    final cameFromNotification = _appState['cameFromNotification'] ?? false;
    final hasNotificationTapEvent = _appState['hasNotificationTapEvent'] ?? false;
    final cameFromDailyReminder = _appState['cameFromDailyReminder'] ?? false;
    final currentSessionEvent = _appState['currentSessionEvent'];
    final persistedEvent = _appState['persistedEvent'];
    final error = _appState['error'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  cameFromNotification ? Icons.touch_app : Icons.app_shortcut,
                  color: cameFromNotification ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'App State Tracking',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (error != null) ...[
              _buildInfoRow('Error:', error),
            ] else ...[
              _buildInfoRow('Came From Notification:', cameFromNotification ? 'Yes' : 'No'),
              _buildInfoRow('Has Tap Event:', hasNotificationTapEvent ? 'Yes' : 'No'),
              _buildInfoRow('From Daily Reminder:', cameFromDailyReminder ? 'Yes' : 'No'),
              
              if (currentSessionEvent != null)
                _buildInfoRow('Current Event:', currentSessionEvent.toString()),
              if (persistedEvent != null)
                _buildInfoRow('Persisted Event:', persistedEvent.toString()),
                
              // Show state actions
              if (hasNotificationTapEvent) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notification tap event detected - use "Clear State" to reset',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _forceReschedule,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _cancelAllNotifications,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _requestPermissions,
                    icon: const Icon(Icons.security, size: 16),
                    label: const Text('Request Perms'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _checkPermissionStatus,
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Check Status'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _clearAppState,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear State'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loadNotificationData,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformInfo() {
    if (_platformInfo.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Info',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Platform:', _platformInfo['platform'] ?? 'Unknown'),
            _buildInfoRow('Channel ID:', _platformInfo['channelId'] ?? 'N/A'),
            _buildInfoRow('Channel Name:', _platformInfo['channelName'] ?? 'N/A'),
            
            // Timezone information
            if (_platformInfo['timezone'] != null)
              _buildInfoRow('Timezone:', _platformInfo['timezone']),
            if (_platformInfo['timezoneStatus'] != null)
              _buildInfoRow('Timezone Status:', _platformInfo['timezoneStatus']),
              
            // iOS-specific info
            if (_platformInfo['isIOSSimulator'] != null)
              _buildInfoRow('iOS Simulator:', _platformInfo['isIOSSimulator'].toString()),
            if (_platformInfo['simulatorLimitations'] != null)
              _buildInfoRow('Note:', _platformInfo['simulatorLimitations']),
            if (_platformInfo['permissionNote'] != null)
              _buildInfoRow('Settings:', _platformInfo['permissionNote']),
              
            if (_platformInfo['error'] != null)
              _buildInfoRow('Error:', _platformInfo['error']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Notifications Debug'),
        
        if (_isLoading)
          const Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading notification data...'),
                ],
              ),
            ),
          )
        else ...[
          // Show error message if there is one
          if (_errorMessage != null)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error: $_errorMessage',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Show data sections (if no error) or just controls (if error)
          if (_errorMessage == null) ...[
            _buildPermissionStatusSection(),
            _buildAppStateSection(),
            _buildStatusSection(),
            _buildNotificationsList(),
            _buildPlatformInfo(),
          ],
          
          // Always show controls for debugging
          _buildControlsSection(),
        ],
      ],
    );
  }
}