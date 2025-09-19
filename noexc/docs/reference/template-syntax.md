# Template Syntax Reference

## Overview

The noexc template system provides dynamic content substitution using `{key|fallback}` syntax with support for formatters, case transformations, and array operations.

## Basic Syntax

### Simple Templates
```
{user.name}              # User's name (empty if missing)
{user.name|Anonymous}    # User's name with fallback
{task.startTime|10:00}   # Task start time with default
```

### Template Structure
```
{key:formatter:modifier|fallback}
 │   │         │         │
 │   │         │         └─ Fallback value if key missing
 │   │         └─ Additional modifier (case, join, etc.)
 │   └─ Formatter function
 └─ Data key path
```

## Available Data Keys

### Session Variables
- `session.visitCount` - Daily visit counter (resets each day)
- `session.totalVisitCount` - Total visits (never resets)
- `session.timeOfDay` - Time period (1=morning, 2=afternoon, 3=evening, 4=night)
- `session.lastVisitDate` - Last visit date (YYYY-MM-DD format)
- `session.firstVisitDate` - First app visit date
- `session.daysSinceFirstVisit` - Days since first visit
- `session.isWeekend` - Boolean for Saturday/Sunday

### User Variables
- `user.name` - User's display name
- `user.task` - Current task description
- `user.streak` - Current streak count
- `user.isOnboarded` - Onboarding completion status
- `user.intensity` - Reminder intensity (0-3)

### Task Variables
- `task.currentDate` - Current task date (YYYY-MM-DD)
- `task.currentStatus` - Task status (pending/completed/failed/overdue)
- `task.startTime` - Daily start time (HH:MM format)
- `task.deadlineTime` - Daily deadline time (HH:MM format)
- `task.activeDays` - Array of active weekdays [1,2,3,4,5]
- `task.remindersIntensity` - Notification intensity (0-3)
- `task.isActiveDay` - Boolean if today matches scheduled days
- `task.isBeforeStart` - Boolean if current time < start time
- `task.isInTimeRange` - Boolean if between start and deadline
- `task.isPastDeadline` - Boolean if current time > deadline

## Formatters

### Time Formatters

#### timeOfDay
Formats numeric time periods to readable strings:
```
{session.timeOfDay:timeOfDay}
1 → "morning"
2 → "afternoon"
3 → "evening"
4 → "night"
```

#### timePeriod
Formats time strings with context:
```
{task.startTime:timePeriod}
"10:00" → "morning deadline"
"14:00" → "afternoon deadline"
"18:00" → "evening deadline"
"22:00" → "night deadline"
```

### Array Formatters

#### activeDays
Formats weekday arrays to readable strings:
```
{task.activeDays:activeDays}
[1,2,3,4,5] → "weekdays"
[6,7] → "weekends"
[1,3,5] → "Monday, Wednesday and Friday"
[2,4] → "Tuesday and Thursday"
```

#### join
Joins arrays with grammatical formatting:
```
{task.activeDays:join}
[1,2,3] → "Monday, Tuesday and Wednesday"
[1] → "Monday"
[1,2] → "Monday and Tuesday"
```

### Intensity Formatters

#### intensity
Formats intensity levels:
```
{task.remindersIntensity:intensity}
0 → "off"
1 → "low"
2 → "high"
3 → "maximum"
```

## Case Transformations

### Available Cases
- `upper` - ALL UPPERCASE
- `lower` - all lowercase
- `proper` - First Letter Of Each Word Capitalized
- `sentence` - First letter only capitalized

### Basic Case Usage
```
{user.name:upper}        → "JOHN DOE"
{user.name:lower}        → "john doe"
{user.name:proper}       → "John Doe"
{user.name:sentence}     → "John doe"
```

### Case with Formatters
```
{session.timeOfDay:timeOfDay:upper}           → "MORNING"
{task.activeDays:activeDays:proper}           → "Weekdays"
{task.activeDays:activeDays:join:upper}       → "MONDAY, TUESDAY AND WEDNESDAY"
```

### Case with Fallbacks
```
{user.name:upper|ANONYMOUS}                   → "ANONYMOUS" (if user.name missing)
{missing.key:lower|default text}              → "default text"
```

## Advanced Features

### Compound Formatting
Combine multiple formatters and modifiers:
```
{task.activeDays:activeDays:join:proper}      → "Monday, Tuesday And Wednesday"
{session.timeOfDay:timeOfDay:sentence}        → "Morning"
{task.remindersIntensity:intensity:upper}     → "HIGH"
```

### Template Functions
Special template functions for dynamic values:
```
{TODAY_DATE}                 → Current date (YYYY-MM-DD)
{NEXT_ACTIVE_DATE}          → Next date matching user's active days
{NEXT_ACTIVE_WEEKDAY}       → Weekday number of next active date
```

### Nested Data Access
Access nested data structures:
```
{nested.object.property|fallback}
{array.0.property|fallback}      # First array element
```

## Processing Order

Templates are processed in this order:
1. **Extract key** from storage
2. **Apply base formatter** (timeOfDay, activeDays, etc.)
3. **Apply join modifier** (if array, create grammatical sentence)
4. **Apply case transformation** (upper, lower, proper, sentence)
5. **Use fallback** (if any step failed, case transformation applied to fallback)

## Usage Examples

### Greeting Messages
```
"Good {session.timeOfDay:timeOfDay}, {user.name}!"
→ "Good morning, John!"

"Welcome back for day {user.streak:increment} of your {user.task} journey!"
→ "Welcome back for day 6 of your exercise journey!"
```

### Task Status Messages
```
"Your task is {task.currentStatus} and you have {task.activeDays:activeDays} scheduled."
→ "Your task is pending and you have weekdays scheduled."

"You're set to start at {task.startTime:timePeriod} with {task.remindersIntensity:intensity} reminders."
→ "You're set to start at morning deadline with high reminders."
```

### Conditional Content
```
"Today is {session.isWeekend|not} a weekend day."
→ "Today is not a weekend day." (for weekdays)
→ "Today is a weekend day." (for weekends - using boolean true conversion)
```

### Complex Formatting
```
"Your {task.activeDays:activeDays:join:upper} schedule runs from {task.startTime} to {task.deadlineTime}."
→ "Your MONDAY, TUESDAY AND WEDNESDAY schedule runs from 10:00 to 18:00."
```

## Error Handling

### Missing Keys
- Returns empty string if no fallback provided
- Returns fallback value if key missing
- Case transformations applied to fallback values

### Invalid Formatters
- Ignored if formatter doesn't exist
- Original value passed through
- Error logged but processing continues

### Type Mismatches
- Formatters gracefully handle wrong types
- Arrays converted to strings when needed
- Numbers formatted as strings

## Best Practices

### Always Provide Fallbacks
```
{user.name|Guest}           # Good - has fallback
{user.name}                 # Risky - no fallback
```

### Use Appropriate Formatters
```
{session.timeOfDay:timeOfDay|morning}     # Good - formatted
{session.timeOfDay|morning}               # Less clear
```

### Combine Features Logically
```
{task.activeDays:activeDays:join:proper|Weekdays}    # Good combination
{user.name:activeDays:join}                          # Doesn't make sense
```

### Test Edge Cases
- Missing data scenarios
- Empty arrays
- Boundary values (e.g., timeOfDay = 0 or 5)

## Debugging Templates

### Common Issues
1. **Key not found**: Check UserDataService has the data
2. **Formatter not working**: Verify formatter name and data type
3. **Case not applied**: Ensure case modifier is last in chain
4. **Fallback not showing**: Check fallback syntax with `|`

### Testing Templates
Use the debug panel to:
- View current data values
- Test template resolution
- Modify data to test different scenarios
- Verify formatter behavior

## See Also

- **[Content Authoring Guide](../authoring/CONTENT_AUTHORING_GUIDE.md)** - Using templates in content
- **[Formatter Authoring Guide](../authoring/FORMATTER_AUTHORING_GUIDE.md)** - Detailed formatter documentation
- **[Conversation Flows](../authoring/conversation-flows.md)** - Template usage in conversations
- **[Troubleshooting](../development/troubleshooting.md)** - Template debugging