# Tristopher Conversation Debug Panel

## Overview

The Conversation Debug Panel is a comprehensive development tool for monitoring and debugging the conversation system in Tristopher. It provides real-time access to all conversation variables, state management, and testing capabilities.

## Accessing the Debug Panel

The debug panel is only available in development builds (when `dart.vm.product` is false):

1. Open the main chat screen
2. Look for the orange bug icon in the top-right corner
3. Tap the bug icon to open the debug panel

## Panel Features

### 📊 Variables Tab

**Live Variable Monitoring:**
- Real-time display of all conversation variables
- Automatic refresh every 2 seconds
- Search functionality to quickly find specific variables
- Color-coded variable types (boolean, string, number)

**Variable Categories:**
- **Core State Variables**: `is_onboarded`, `has_task_set`, `is_overdue`, `is_on_notice`, `has_visited_today`
- **User Information**: `user_name`, `current_task`, `daily_deadline`, `notification_intensity`
- **Progress & Streaks**: `current_streak`, `total_completions`, `total_failures`, `longest_streak`
- **Wager System**: `wager_amount`, `wager_target`, `total_lost`, `total_saved`
- **System Variables**: `robot_personality_level`, `default_delay_ms`, `last_input`, `script_version`

**Variable Editing:**
- Click on any editable variable to modify its value
- Boolean variables have toggle switches
- String/number variables have text input fields
- Changes are saved immediately to the database

### 🧠 State Tab

**Conversation State Monitoring:**
- Current message count and language settings
- Processing and response states
- Engine status and interaction tracking
- Recent message preview

**Engine State:**
- Whether engine is awaiting user response
- Message ID being waited for
- User variable count
- Current day in journey

### ⚡ Actions Tab

**Conversation Actions:**
- Start Daily Conversation
- Clear History
- Reset All Data (with confirmation)

**State Manipulation:**
- Set User as Onboarded
- Set Task Complete
- Trigger Overdue State
- Put User On Notice

**Simulation Actions:**
- Simulate Success (increments streak)
- Simulate Failure (resets streak)
- Add Streak Days (+5)
- Reset Streak to 0

**Wager Testing:**
- Set Wager $20
- Trigger Wager Loss
- Clear Wager

### 🔄 Flow Tab

**Visual Flow State:**
- See which conversation path is currently active
- Green indicators show current user state
- Flow path description explains next conversation variant

**Conversation Paths:**
- `not_onboarded` → Onboarding flow
- `onboarded_no_task` → Task setup
- `onboarded_with_task_overdue` → Overdue handling
- `onboarded_with_task_current` → Normal check-in

## Key Variables Reference

### Critical Flow Variables
- `is_onboarded`: Whether user has completed initial setup
- `has_task_set`: Whether user has defined their daily task
- `is_overdue`: Whether task deadline has passed
- `is_on_notice`: Whether user is in "last chance" mode
- `has_visited_today`: Whether user already checked in today

### Personalization Variables
- `user_name`: User's display name for conversation
- `current_task`: Description of daily task
- `daily_deadline`: Time when task is due (e.g., "18:00")
- `notification_intensity`: "low", "medium", or "high"

### Progress Tracking
- `current_streak`: Current consecutive success count
- `total_completions`: All-time task completions
- `total_failures`: All-time task failures
- `longest_streak`: Best streak achieved

### Wager System
- `wager_amount`: Dollar amount at stake (0-99)
- `wager_target`: Where money goes if failed
- `total_lost`: Cumulative money lost to failures
- `total_saved`: Cumulative money saved by success

## Testing Scenarios

### New User Flow
1. Reset all data
2. Variables will show `is_onboarded: false`
3. Start conversation to trigger onboarding

### Task Setup Testing
1. Set `is_onboarded: true` and `has_task_set: false`
2. Start conversation to trigger task setup flow

### Overdue Task Testing
1. Set `has_task_set: true` and `is_overdue: true`
2. Start conversation to trigger overdue handling

### Failure Consequence Testing
1. Set wager amount and target
2. Use "Simulate Failure" to test wager loss
3. Check that streak resets and variables update

### Success Streak Testing
1. Use "Simulate Success" multiple times
2. Watch streak increment in real-time
3. Test different streak milestones

## Tips for Debugging

1. **Use Live Updates**: Variables update automatically every 2 seconds
2. **Search Variables**: Use the search bar to quickly find specific variables
3. **Test Edge Cases**: Use state manipulation to test unusual scenarios
4. **Monitor Flow**: Check the Flow tab to understand current conversation path
5. **Reset When Stuck**: Use "Reset All Data" for clean slate testing

## Security Note

The debug panel is automatically disabled in production builds and only appears in development mode for security reasons.
