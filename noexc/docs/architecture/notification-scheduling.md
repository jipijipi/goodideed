# Notification Scheduling System

## Overview

The notification system schedules reminders based on user's task configuration, active days, and reminder intensity settings. The system adapts to different start timing scenarios.

## Notification Timeline Examples

### Scenario 1: Start NEXT ACTIVE DAY
User sets task Monday at 11am with:
- Start time: 10:00
- Deadline: 18:00
- Active days: Monday-Friday
- Current date points to Tuesday

**Weekly Schedule:**
- **Monday/present day**: No reminders
- **Tuesday/next active day**: Start time encouragements, reminder around 14:00, completion check at deadline time
- **Wednesday/following active day**: Start time encouragements, reminder around 14:00, completion check at deadline time
- **Thursday/first active day past end date**: First comeback notification/reminder
- **Friday/following active days past end date**: Second comeback notification (rule-dependent)
- **Saturday**: Not an active day, no notifications
- **Sunday**: Not an active day, no notifications

### Scenario 2: Start TODAY
User sets task Monday at 11am, same configuration, current date points to same day.

**Weekly Schedule:**
- **Monday/present day**: SKIP start time encouragements (in the past), reminder around 14:00, completion check at deadline time
- **Tuesday/next active day**: Start time encouragements, reminder around 14:00, completion check at deadline time
- **Wednesday/first active day past end date**: First comeback notification/reminder
- **Thursday/following active days past end date**: Second comeback notification (rule-dependent)
- **Friday/following active days past end date**: Third comeback notification (rule-dependent)
- **Saturday**: Not an active day, no notifications
- **Sunday**: Not an active day, no notifications

## Notification Types

### Daily Active Day Notifications
1. **Start Time Encouragements** - Sent at or near task start time
2. **Mid-Day Reminders** - Sent around midpoint between start and deadline
3. **Completion Check** - Sent at deadline time

### Comeback Notifications
- **First Comeback** - First active day after task period ends
- **Subsequent Comebacks** - Following active days (rule-dependent frequency)

### Intensity-Based Variations
Notification frequency and tone vary based on user's reminder intensity setting:
- **0 (Off)**: No notifications
- **1 (Low)**: Minimal notifications, gentle tone
- **2 (High)**: Regular notifications, motivational tone
- **3 (Maximum)**: Frequent notifications, urgent tone

## Implementation Rules

### Active Day Detection
- Only send notifications on user's configured active days
- Skip notifications on inactive days (weekends for weekday-only tasks)
- Handle cross-week transitions properly

### Time Window Logic
- **Before Start Time**: Send encouragement notifications
- **Between Start and Deadline**: Send reminder notifications
- **After Deadline**: Send completion check notifications
- **Past Task Period**: Send comeback notifications

### Rescheduling Triggers
Notifications are recalculated when:
- User checks in and completes/fails a task
- User modifies task settings
- Task period transitions (e.g., daily reset)

## Integration Points

### With Task Calculation System
- Uses same active day detection logic
- Respects task status transitions
- Coordinates with session timing variables

### With Notification Service
- Leverages NotificationService for platform delivery
- Handles permission states and platform differences
- Manages notification scheduling and cancellation

### With User Data
- Reads reminder intensity settings
- Accesses task configuration (times, active days)
- Updates based on user interactions

## Configuration Variables

### Task Settings
- `task.startTime` - Daily start time
- `task.deadlineTime` - Daily deadline time
- `task.activeDays` - Array of active weekdays
- `task.remindersIntensity` - Intensity level (0-3)

### Timing Calculations
- Current date vs. task.currentDate
- Time remaining until deadline
- Days since last completion
- Active day progression

## Platform Considerations

### iOS/Android Differences
- Handle permission request timing
- Manage background notification limits
- Adapt to platform-specific scheduling constraints

### Notification Content
- Use semantic content system for varied messaging
- Apply user's personality settings
- Include relevant task context in notifications

See `NotificationService` and related services for implementation details.