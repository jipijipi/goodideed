# Conversation Flows

**← [Documentation Index](../README.md) | [Content Authoring](.)**

## Overview

Conversation flows are the backbone of the noexc app, defining how users interact with the system through structured JSON sequences. This guide covers creating, organizing, and managing conversation flows.

## Flow Structure

### Basic Flow Format
Each conversation flow is a JSON file containing an array of messages:

```json
{
  "sequence": [
    {
      "id": "welcome_1",
      "type": "bot",
      "text": "Hello {user.name|there}! Ready to start your day?"
    },
    {
      "id": "response_1",
      "type": "choice",
      "text": "How are you feeling?",
      "choices": [
        {"text": "Ready to go!", "value": "motivated"},
        {"text": "Need some encouragement", "value": "hesitant"}
      ]
    }
  ]
}
```

### Message Flow Types

#### 1. Linear Flows
Simple sequential conversations:
```
Message 1 → Message 2 → Message 3 → End
```

#### 2. Branching Flows
Conditional routing based on user choices:
```
Message 1 → Choice → Branch A / Branch B → Continuation
```

#### 3. Dynamic Flows
Auto-routing based on user data:
```
Message 1 → Autoroute → Different paths based on user.streak, task.status, etc.
```

#### 4. Cross-Sequence Flows
Navigation between different conversation files:
```
Sequence A → Choice with sequenceId → Sequence B
```

## Message Types Reference

### Bot Messages
AI responses with rich formatting:

```json
{
  "id": "greeting_enthusiastic",
  "type": "bot",
  "text": "Great to see you again! You've been on a {user.streak} day streak!",
  "contentKey": "bot.greet.enthusiastic",
  "animation": {
    "asset": "assets/animations/wave.riv",
    "autoHideMs": 2000
  }
}
```

**Features:**
- Template substitution: `{user.name|fallback}`
- Multi-text with `|||` separator
- Semantic content keys for dynamic variants
- Inline animations
- Custom styling options

### Choice Interactions
Multiple choice with data persistence:

```json
{
  "id": "task_intensity",
  "type": "choice",
  "text": "How intense should your reminders be?",
  "choices": [
    {
      "text": "Gentle nudges",
      "value": 1,
      "key": "task.remindersIntensity"
    },
    {
      "text": "Firm reminders",
      "value": 2,
      "key": "task.remindersIntensity"
    },
    {
      "text": "Maximum motivation",
      "value": 3,
      "key": "task.remindersIntensity"
    }
  ]
}
```

**Advanced Features:**
- Cross-sequence navigation: `"sequenceId": "taskSetting_seq"`
- Custom data values: `"value": [1,2,3,4,5]` for arrays
- Multiple data keys per choice
- Conditional choice display

### Text Input
Free text input with validation:

```json
{
  "id": "task_name_input",
  "type": "textInput",
  "text": "What would you like to work on?",
  "placeholder": "e.g., Exercise, Read, Study...",
  "key": "user.task",
  "validation": {
    "required": true,
    "minLength": 2,
    "maxLength": 50
  }
}
```

### Auto-routing
Conditional flow control:

```json
{
  "id": "check_user_status",
  "type": "autoroute",
  "routes": [
    {
      "condition": "session.visitCount == 1",
      "target": "onboarding_welcome"
    },
    {
      "condition": "task.currentStatus == 'pending' && task.isActiveDay == true",
      "target": "task_reminder"
    },
    {
      "condition": "user.streak >= 7",
      "target": "streak_celebration"
    },
    {
      "default": true,
      "target": "general_checkin"
    }
  ]
}
```

### Data Actions
Direct data manipulation:

```json
{
  "id": "increment_streak",
  "type": "dataAction",
  "action": {
    "type": "increment",
    "key": "user.streak",
    "value": 1
  }
}
```

**Action Types:**
- `set` - Set value: `"value": "completed"`
- `increment` - Add number: `"value": 1`
- `decrement` - Subtract number: `"value": 1`
- `reset` - Reset to default: `"key": "user.streak"`
- `trigger` - Fire event: `"event": "show_celebration"`

## Flow Design Patterns

### 1. Onboarding Flow
First-time user experience:

```
Welcome → Name Input → Task Setup → Schedule Configuration → Confirmation → Tutorial
```

### 2. Daily Check-in Flow
Returning user experience:

```
Greeting → Auto-route → Task Status Check → Success/Failure Handling → Next Steps
```

### 3. Task Configuration Flow
Setting up or modifying tasks:

```
Current Settings → Change Prompts → Input Collection → Validation → Confirmation
```

### 4. Celebration Flow
Positive reinforcement:

```
Achievement Recognition → Celebration Animation → Streak Update → Motivation
```

### 5. Recovery Flow
Handling missed tasks:

```
Acknowledgment → No Judgment → Understanding → Reset Options → Re-motivation
```

## Conditional Logic

### Basic Conditions
```json
"condition": "user.streak > 5"
"condition": "task.currentStatus == 'pending'"
"condition": "session.isWeekend == true"
```

### Compound Conditions
```json
"condition": "session.visitCount > 1 && task.isActiveDay == true"
"condition": "user.streak >= 7 || session.timeOfDay == 4"
```

### Template-Based Conditions
```json
"condition": "task.activeDays contains {TODAY_WEEKDAY}"
"condition": "{session.timeOfDay:timeOfDay} == 'morning'"
```

## Template Integration

### Basic Templates
- `{user.name|Anonymous}` - User data with fallback
- `{task.startTime|10:00}` - Configuration values
- `{session.visitCount|1}` - Session tracking

### Formatted Templates
- `{session.timeOfDay:timeOfDay|morning}` - Time formatting
- `{task.activeDays:activeDays|weekdays}` - Day formatting
- `{user.streak:increment}` - Dynamic calculations

### Advanced Templates
- `{task.activeDays:activeDays:join:upper}` - Array joining with case transformation
- `{task.startTime:timePeriod|morning}` - Complex formatting
- `{TODAY_DATE}` - Template functions

## Content Management

### Semantic Content Keys
Use semantic keys for dynamic content variation:

```json
{
  "text": "Well done!",
  "contentKey": "bot.acknowledge.completion.positive"
}
```

**Content Structure:**
```
bot.acknowledge.completion.positive → "Excellent work!"
bot.acknowledge.completion.neutral → "Task completed."
bot.acknowledge.effort.high → "You really went all out!"
```

### Multi-text Messages
Create multiple chat bubbles:

```json
{
  "text": "That's a great choice!|||Let me help you set that up.|||This will only take a moment."
}
```

## Cross-Sequence Navigation

### Sequence Targeting
Navigate between conversation files:

```json
{
  "text": "Let's set up your task",
  "sequenceId": "taskSetting_seq"
}
```

### Sequence Management
Current available sequences:
- `welcome_seq` - Entry point and routing
- `onboarding_seq` - New user setup
- `taskChecking_seq` - Daily task checking
- `taskSetting_seq` - Task configuration
- `sendoff_seq` - Session conclusion
- `success_seq` - Success celebration
- `failure_seq` - Failure handling

## Animation Integration

### Inline Animations
Add animations to messages:

```json
{
  "text": "Congratulations!",
  "animation": {
    "asset": "assets/animations/celebration.riv",
    "autoHideMs": 3000
  }
}
```

### Triggered Animations
Use data actions to trigger overlay animations:

```json
{
  "type": "dataAction",
  "action": {
    "type": "trigger",
    "event": "overlay_rive",
    "data": {
      "asset": "assets/animations/achievement.riv",
      "zone": 2,
      "autoHideMs": 2500
    }
  }
}
```

## Testing Flows

### Debug Panel Testing
Use the in-app debug panel to:
- Switch between sequences manually
- Modify user variables in real-time
- Test different routing conditions
- Simulate various user states

### Scenario Testing
Create test scenarios in `assets/debug/scenarios.json`:

```json
{
  "new_user": {
    "session.visitCount": 1,
    "user.isOnboarded": false,
    "user.name": ""
  },
  "returning_motivated": {
    "session.visitCount": 10,
    "user.streak": 5,
    "task.currentStatus": "pending"
  }
}
```

## Best Practices

### 1. Flow Design
- Keep conversations focused and purposeful
- Provide clear choices and options
- Use consistent language and tone
- Plan for edge cases and error states

### 2. Content Writing
- Write in character voice (enthusiastic but not pushy)
- Use templates for personalization
- Provide meaningful choices
- Include encouraging fallbacks

### 3. Data Management
- Store meaningful user preferences
- Use semantic data keys
- Validate all inputs
- Handle missing data gracefully

### 4. Performance
- Keep sequences reasonably sized
- Use cross-sequence navigation for organization
- Optimize for common paths
- Test on actual devices

## Common Patterns

### Greeting Patterns
```json
{
  "text": "Good {session.timeOfDay:timeOfDay}, {user.name}! Ready for day {user.streak:increment} of your {user.task} journey?"
}
```

### Status Check Patterns
```json
{
  "condition": "task.currentStatus == 'pending' && task.isPastDeadline == false",
  "target": "gentle_reminder"
}
```

### Celebration Patterns
```json
{
  "text": "Amazing! That's {user.streak} days in a row!",
  "animation": {
    "asset": "assets/animations/success.riv"
  }
}
```

## See Also

- **[Content Authoring Guide](CONTENT_AUTHORING_GUIDE.md)** - Writing effective content
- **[Formatter Guide](FORMATTER_AUTHORING_GUIDE.md)** - Template syntax and formatting
- **[Authoring Tool](AUTHORING_TOOL_README.md)** - Visual conversation designer
- **[Chat System Architecture](../architecture/chat-system.md)** - Technical implementation details