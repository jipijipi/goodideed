# Notification Reference

## Overview

The notification system provides comprehensive notification management with cross-platform support, rich tap events, and sophisticated permission handling.

## Notification Types

### Daily Reminder (ID: 1001)
Task deadline notifications with scheduling context.

**Payload Structure:**
```json
{
  "type": "dailyReminder",
  "taskDate": "2024-01-15",
  "startTime": "10:00",
  "deadlineTime": "18:00",
  "taskName": "Exercise",
  "intensity": 2
}
```

**Scheduling:**
- Sent at start time (encouragement)
- Sent at midpoint (reminder)
- Sent at deadline (completion check)

### Achievement Notifications (ID: 2000+)
Milestone and progress celebration notifications.

**Payload Structure:**
```json
{
  "type": "achievement",
  "achievementType": "streak",
  "value": 7,
  "title": "Week Warrior",
  "description": "7 days in a row!"
}
```

**Triggers:**
- Streak milestones (3, 7, 14, 30 days)
- Task completion patterns
- Special accomplishments

### Warning Notifications (ID: 3000+)
Alert notifications for important events.

**Payload Structure:**
```json
{
  "type": "warning",
  "warningType": "deadline_missed",
  "taskDate": "2024-01-15",
  "message": "Don't give up! Tomorrow is a new day."
}
```

**Use Cases:**
- Missed deadlines
- System issues
- Important reminders

### System Notifications (ID: 4000+)
Maintenance and system-level notifications.

**Payload Structure:**
```json
{
  "type": "system",
  "systemType": "maintenance",
  "message": "App updated with new features!",
  "actionRequired": false
}
```

## Permission Management

### Permission States

#### Granted
```dart
NotificationPermissionStatus.granted
```
- Notifications enabled and can be scheduled
- All notification types available
- No user action required

#### Denied
```dart
NotificationPermissionStatus.denied
```
- User explicitly denied permissions
- Requires manual Settings app enable
- Guide user to Settings for manual enable

#### Not Requested
```dart
NotificationPermissionStatus.notRequested
```
- Ready to request permissions from user
- Show permission request dialog
- Explain notification benefits first

#### Restricted
```dart
NotificationPermissionStatus.restricted
```
- System policy prevents notifications
- Parental controls or enterprise policy
- Cannot request permissions

#### Unknown
```dart
NotificationPermissionStatus.unknown
```
- Unable to determine status (error condition)
- Fallback to conservative approach
- Log error for debugging

### Permission Workflow

```dart
// Check current status
final status = await NotificationService.getPermissionStatus();

// Handle based on status
switch (status) {
  case NotificationPermissionStatus.granted:
    // Schedule notifications
    break;
  case NotificationPermissionStatus.notRequested:
    // Request permissions
    final granted = await NotificationService.requestPermissions();
    break;
  case NotificationPermissionStatus.denied:
    // Guide to Settings
    break;
  // ... handle other cases
}
```

## Tap Event Handling

### NotificationTapEvent Model

```dart
class NotificationTapEvent {
  final int notificationId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final NotificationType type;
  final String? userInput;
}
```

### Event Processing

```dart
// Check for pending tap events on app start
final pendingEvent = await AppStateService.consumePendingNotification();
if (pendingEvent != null) {
  await handleNotificationTap(pendingEvent);
}

// Handle tap event
Future<void> handleNotificationTap(NotificationTapEvent event) async {
  switch (event.type) {
    case NotificationType.dailyReminder:
      // Navigate to task check-in
      await navigateToTaskCheckin(event);
      break;
    case NotificationType.achievement:
      // Show celebration
      await showAchievementCelebration(event);
      break;
    // ... handle other types
  }
}
```

### Cross-Session Persistence

The system automatically persists notification tap events across app launches:

```dart
// Automatically stored when notification tapped
await AppStateService.storeNotificationTapEvent(event);

// Retrieved on next app launch
final pendingEvent = await AppStateService.consumePendingNotification();
```

## Platform Differences

### iOS Behavior
- Cannot check permission status without requesting
- Relies on stored status from previous requests
- Limited background notification scheduling
- Rich notification support with actions

### Android Behavior
- Similar limitations to iOS for permission checking
- Uses stored status for accurate state tracking
- Background scheduling restrictions vary by version
- Channel-based notification management

### macOS Behavior
- Supports permission checking without requesting
- Treat as "other platform" in permission logic
- Desktop notification center integration
- Full scheduling capabilities

## Scheduling System

### Daily Reminder Scheduling

```dart
// Schedule daily reminder for active days
await NotificationService.scheduleNotification(
  NotificationRequest(
    id: AppConstants.DAILY_REMINDER_ID,
    title: "Time to {user.task}!",
    body: "Your {task.startTime:timePeriod} reminder is here.",
    scheduledDate: nextActiveDate,
    payload: {
      "type": "dailyReminder",
      "taskDate": nextActiveDate.toIso8601String(),
      "startTime": task.startTime,
      "deadlineTime": task.deadlineTime,
    },
  ),
);
```

### Fallback Logic

For past dates, automatically calculate next valid date:

```dart
// If scheduled date is in the past, find next active day
if (scheduledDate.isBefore(DateTime.now())) {
  scheduledDate = calculateNextActiveDate(user.activeDays);
}
```

## Test Notification System

### Demo Notification Trigger

```json
{
  "id": "demo_notification",
  "type": "dataAction",
  "action": {
    "type": "trigger",
    "event": "show_test_notification",
    "data": {
      "title": "Demo Notification",
      "body": "This is how notifications look on your device!",
      "delaySeconds": 3
    }
  }
}
```

**Parameters:**
- `title` (optional): Notification title, defaults to "Demo Notification"
- `body` (optional): Notification body, defaults to demo text
- `delaySeconds` (optional): Delay before showing, defaults to 3 seconds

**Requirements:**
- Must test on real device (not simulator)
- User must have notification permissions granted
- Works while app is running or in background

## Debugging Notifications

### Debug Panel Features

**Permission Status Display:**
- Visual indicators with color-coded states
- Actionable suggestions based on current state
- Permission request history tracking

**Tap Event Monitoring:**
- Real-time notification tap event tracking
- Cross-session persistence verification
- Payload inspection and type detection

**Enhanced Controls:**
- Manual permission checking
- Pending notification state clearing
- Comprehensive notification management

### Debug Commands

```dart
// Check current permission status
final status = await NotificationService.getPermissionStatus();
logger.notification('Permission status: $status');

// View pending tap events
final pending = await AppStateService.consumePendingNotification();
logger.notification('Pending event: ${pending?.toJson()}');

// Clear all notifications
await NotificationService.cancelAllNotifications();
logger.notification('All notifications cleared');
```

## Best Practices

### Permission Requests
1. **Explain before requesting** - Tell users why notifications are useful
2. **Request at appropriate time** - During task setup, not app launch
3. **Handle all states gracefully** - Don't assume permissions granted
4. **Provide fallback experiences** - App should work without notifications

### Content Guidelines
1. **Personalize messages** - Use templates with user data
2. **Match user tone** - Respect personality preferences
3. **Provide context** - Include relevant task information
4. **Keep it brief** - Mobile notifications have limited space

### Scheduling Considerations
1. **Respect active days** - Only send on user's scheduled days
2. **Handle time zones** - Use local time for scheduling
3. **Avoid spam** - Limit frequency based on intensity settings
4. **Clean up old notifications** - Cancel outdated scheduled notifications

### Error Handling
1. **Log all errors** - Use LoggerService for debugging
2. **Graceful degradation** - Continue without notifications if needed
3. **User feedback** - Inform users of notification issues
4. **Retry mechanisms** - Attempt to recover from temporary failures

## Integration Examples

### Task Completion Flow

```dart
// User completes task
await userDataService.setValue('task.currentStatus', 'completed');
await userDataService.setValue('user.streak', currentStreak + 1);

// Schedule achievement notification if milestone reached
if (newStreak % 7 == 0) {
  await NotificationService.scheduleNotification(
    NotificationRequest(
      id: AppConstants.ACHIEVEMENT_BASE_ID + newStreak,
      title: "Week ${newStreak ~/ 7} Complete!",
      body: "You've maintained your ${user.task} habit for $newStreak days!",
      scheduledDate: DateTime.now().add(Duration(seconds: 2)),
      payload: {
        "type": "achievement",
        "achievementType": "streak",
        "value": newStreak,
      },
    ),
  );
}
```

### Comeback Notifications

```dart
// Schedule comeback notification after missed tasks
if (taskStatus == 'failed' && daysSinceLast > 1) {
  await NotificationService.scheduleNotification(
    NotificationRequest(
      id: AppConstants.DAILY_REMINDER_ID,
      title: "Ready for a fresh start?",
      body: "Your {user.task} journey is waiting for you!",
      scheduledDate: nextActiveDate,
      payload: {
        "type": "dailyReminder",
        "isComeback": true,
        "taskDate": nextActiveDate.toIso8601String(),
      },
    ),
  );
}
```

## See Also

- **[Notification Scheduling](../architecture/notification-scheduling.md)** - Scheduling system details
- **[Local Reminders Implementation](LOCAL_REMINDERS_IMPLEMENTATION_GUIDE.md)** - Implementation guide
- **[API Reference](api-reference.md)** - Service API documentation
- **[Troubleshooting](../development/troubleshooting.md)** - Debugging notifications