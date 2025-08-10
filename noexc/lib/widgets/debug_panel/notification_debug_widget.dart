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

      if (mounted) {
        setState(() {
          _notificationStatus = status;
          _scheduledNotifications = scheduled;
          _platformInfo = platform;
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
                    label: const Text('Check Permissions'),
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