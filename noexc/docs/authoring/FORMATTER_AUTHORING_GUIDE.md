# Formatter Authoring Guide

This guide covers all available formatters for use in conversation sequences and content authoring.

## Template Syntax

### Basic Usage
```
{key:formatter}           # Apply formatter to stored value
{key:formatter|fallback}  # Apply formatter with fallback if key not found
{key:formatter:join}      # Apply formatter and join arrays with grammar
```

### Examples
```
{session.timeOfDay:timeOfDay}                    # "morning"
{task.deadlineTime:timePeriod}                   # "evening deadline"
{task.activeDays:activeDays|daily}               # "weekdays" or "daily" if not set
{task.remindersIntensity:intensity|off}          # "high" or "off" if not set
{task.activeDays:activeDays:join}                # "Monday, Tuesday and Wednesday"
{task.activeDays:activeDays:join|daily}          # Array joining with fallback
```

### Array Joining with `:join` Flag

The `:join` flag enables smart conversion of arrays into grammatically correct sentences:

**Array Formats Supported:**
- `[1,2,4]` → `"Monday, Tuesday and Thursday"`
- `"[1,2,4]"` → `"Monday, Tuesday and Thursday"`
- `"1,3,5"` → `"Monday, Wednesday and Friday"`

**Grammar Rules:**
- Single element: `[1]` → `"Monday"`
- Two elements: `[1,2]` → `"Monday and Tuesday"`
- Three+ elements: `[1,2,3]` → `"Monday, Tuesday and Wednesday"`

**Fallback Behavior:**
- If the string has a direct mapping (like `"6,7"` → `"weekends"`), uses that
- If elements don't map, skips them gracefully
- If formatter doesn't exist, returns null

## Available Formatters

### 1. `timeOfDay`
**Purpose:** Convert session time periods (integers) to readable text

**Input → Output:**
- `1` → `"morning"`
- `2` → `"afternoon"` 
- `3` → `"evening"`
- `4` → `"night"`

**Common Usage:**
```
"Good {session.timeOfDay:timeOfDay}!"
"It's {session.timeOfDay:timeOfDay} time to check in."
```

**Data Source:** `session.timeOfDay` (automatically set by SessionService)

---

### 2. `timePeriod` 
**Purpose:** Convert time strings to readable periods for deadlines and start times

**Input → Output:**
- `"10:00"` → `"morning deadline"`
- `"14:00"` → `"afternoon deadline"`
- `"18:00"` → `"evening deadline"`
- `"23:00"` → `"night deadline"`
- `"08:00"` → `"morning start"`
- `"12:00"` → `"afternoon start"`
- `"16:00"` → `"evening start"`
- `"21:00"` → `"night start"`

**Common Usage:**
```
"Your {task.deadlineTime:timePeriod} is at {task.deadlineTime}."
"You can start your {task.startTime:timePeriod} at {task.startTime}."
```

**Data Source:** `task.deadlineTime`, `task.startTime`

---

### 3. `intensity`
**Purpose:** Convert reminder intensity values to readable levels

**Input → Output:**
- `0` / `"none"` → `"off"`
- `1` / `"mild"` → `"low"`
- `2` / `"severe"` → `"high"`
- `3` / `"extreme"` → `"maximum"`

**Common Usage:**
```
"Your reminder intensity is set to {task.remindersIntensity:intensity}."
"I'll remind you with {task.remindersIntensity:intensity} intensity."
```

**Data Source:** `task.remindersIntensity`

---

### 4. `activeDays`
**Purpose:** Convert weekday arrays to human-readable schedules

#### Standard Formatting
**Input → Output:**
- `"1,2,3,4,5"` / `"[1,2,3,4,5]"` → `"weekdays"`
- `"6,7"` / `"[6,7]"` → `"weekends"`
- `"1,2,3,4,5,6,7"` / `"[1,2,3,4,5,6,7]"` → `"daily"`
- `"1"` → `"Monday"`
- `"2"` → `"Tuesday"`
- `"3"` → `"Wednesday"`
- `"4"` → `"Thursday"`
- `"5"` → `"Friday"`
- `"6"` → `"Saturday"`
- `"7"` → `"Sunday"`
- `"1,3,5"` → `"Monday, Wednesday, Friday"`
- `"2,4"` → `"Tuesday and Thursday"`

#### Array Joining with `:join` Flag
**Array Input → Grammatical Output:**
- `[1,2,4]` → `"Monday, Tuesday and Thursday"`
- `[6,7]` → `"Saturday and Sunday"`
- `[1,3,5,7]` → `"Monday, Wednesday, Friday and Sunday"`
- `[2]` → `"Tuesday"`

**Priority Rules:**
1. Direct mappings take precedence (e.g., `"6,7"` → `"weekends"`)
2. Arrays without direct mappings get parsed and joined
3. Unknown day numbers are skipped gracefully

**Common Usage:**
```
"Your active days are {task.activeDays:activeDays}."           # "weekdays"
"Come back on {task.activeDays:activeDays}."                  # "weekends"
"Your schedule is {task.activeDays:activeDays:join}."         # "Monday, Tuesday and Thursday"
"Train on {task.activeDays:activeDays:join|any day}."         # With fallback
```

**Data Source:** `task.activeDays`

## Template Best Practices

### 1. Always Use Fallbacks for Optional Data
```
✅ Good: {user.name|there}
❌ Bad:  {user.name}
```

### 2. Combine Formatters with Fallbacks
```
✅ Good: {task.deadlineTime:timePeriod|evening}
❌ Bad:  {task.deadlineTime:timePeriod}
```

**Important**: Fallbacks work consistently for both missing data AND missing/failed formatters. If a formatter doesn't exist or fails to format a value, the fallback will be used instead of showing raw data.

### 3. Use Appropriate Formatters for Data Types
```
✅ Good: {session.timeOfDay:timeOfDay}        # For session periods
✅ Good: {task.deadlineTime:timePeriod}       # For specific times
❌ Bad:  {task.deadlineTime:timeOfDay}        # Wrong formatter type
```

## Common Use Cases

### Greeting Messages
```
"Good {session.timeOfDay:timeOfDay}! Ready for your task?"
```

### Deadline Reminders
```
"Your {task.deadlineTime:timePeriod} is approaching at {task.deadlineTime}."
```

### Schedule Information
```
"Your task schedule is {task.activeDays:activeDays} with {task.remindersIntensity:intensity} reminders."
"You're scheduled for {task.activeDays:activeDays:join}."
"Train {task.activeDays:activeDays:join|every day} this week."
```

### Array Joining Examples
```
"Your workout days are {task.activeDays:activeDays:join}."        # "Monday, Tuesday and Thursday"
"Complete your habits on {task.activeDays:activeDays:join}."      # "weekdays" (direct mapping)
"Available periods: {session.availableTimes:timeOfDay:join}."     # "morning and evening"
```

### Time Range Messages
```
"You can work on this from {task.startTime:timePeriod} until your {task.deadlineTime:timePeriod}."
```

## Troubleshooting

### Formatter Not Working?
1. **Check formatter name spelling** - Must match exactly (`timeOfDay`, not `timeofday`)
2. **Verify data exists** - Use fallbacks for optional values
3. **Check data format** - Ensure input matches expected format

### Common Issues
- **`{key:formatter}` shows literally**: Formatter name misspelled/doesn't exist AND no fallback provided
- **Shows fallback instead of formatted value**: Data key doesn't exist, formatter missing, or formatting failed (consistent behavior)
- **Empty output**: Data exists but doesn't match any formatter mappings
- **`:join` not working**: Check that data is in array format or contains commas
- **Getting direct mapping instead of joined**: String has exact match in formatter (intended behavior)

### Fallback Behavior (Updated)
**Consistent Rule**: Fallbacks are used whenever the final formatted result cannot be determined, whether due to:
- Missing data key
- Missing/invalid formatter
- Formatter exists but fails to format the value

**Examples:**
```
{missing.key|fallback}           → "fallback" (missing data)
{existing.key:badFormatter|safe} → "safe" (bad formatter)
{existing.key:goodFormatter}     → formatted result (success)
{missing.key:badFormatter}       → {missing.key:badFormatter} (no fallback)
```

### Testing Formatters
Use debug scenarios to test formatter behavior:
```json
{
  "test_scenario": {
    "variables": {
      "session.timeOfDay": 2,
      "task.deadlineTime": "18:00",
      "task.activeDays": "1,2,3,4,5"
    }
  }
}
```

## Adding New Formatters

To add a new formatter:

1. **Create JSON file** in `assets/content/formatters/yourFormatter.json`
2. **Add test cases** in `test/services/formatter_service_test.dart` 
3. **Update this guide** with documentation
4. **Test in sequences** using debug scenarios

**Example formatter file:**
```json
{
  "input1": "output1",
  "input2": "output2",
  "input3": "output3"
}
```