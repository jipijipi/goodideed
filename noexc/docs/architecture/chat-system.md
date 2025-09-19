# Chat System Architecture

## Overview

The chat system is the core of the noexc application, managing dynamic conversation flows through a sequence-based architecture. It processes user interactions, manages data flow, and orchestrates the entire conversational experience.

## Core Components

### ChatService
Main orchestrator that coordinates all chat functionality through specialized processors.

**Responsibilities:**
- Load and manage conversation sequences
- Process incoming messages and user interactions
- Route conversations based on user data and conditions
- Coordinate with other services (notifications, animations, data storage)

**Key Processors:**
- `SequenceLoader` - Handles JSON sequence loading and validation
- `MessageProcessor` - Manages message rendering and type-specific behavior
- `RouteProcessor` - Determines conversation flow based on routing logic

### Message Processing Pipeline

```
User Input → Input Validation → Message Processing → Data Actions → Route Calculation → Response Generation
```

## Message Types

### 1. Bot Messages (`bot`)
AI/bot responses with rich content support.

**Features:**
- Multi-text support with `|||` separator for multiple bubbles
- Template substitution with `{key|fallback}` syntax
- Inline Rive animations
- Semantic content resolution
- Custom styling and formatting

**Example:**
```json
{
  "id": "welcome_1",
  "type": "bot",
  "text": "Hello {user.name|there}! Ready to tackle your {user.task}?",
  "contentKey": "bot.greet.welcome.enthusiastic",
  "animation": {
    "asset": "assets/animations/wave.riv",
    "autoHideMs": 2000
  }
}
```

### 2. User Responses (`user`)
Simple text responses from the user.

**Behavior:**
- Displays user's text in chat bubble
- Automatically advances to next message
- Can trigger data actions based on content

### 3. Choice Interactions (`choice`)
Multiple choice selections with data persistence.

**Features:**
- Multiple choice options with custom labels
- Optional custom values for data storage
- Cross-sequence navigation support
- Visual styling and icons

**Example:**
```json
{
  "id": "task_frequency",
  "type": "choice",
  "text": "How often do you want to do this?",
  "choices": [
    {
      "text": "Every day",
      "value": [1,2,3,4,5,6,7],
      "key": "task.activeDays"
    },
    {
      "text": "Weekdays only",
      "value": [1,2,3,4,5],
      "key": "task.activeDays"
    }
  ]
}
```

### 4. Text Input (`textInput`)
Free text input with validation and processing.

**Features:**
- Custom prompts and placeholders
- Input validation rules
- Data transformation and storage
- Error handling and retry logic

### 5. Auto-routing (`autoroute`)
Automatic conversation routing based on conditions.

**Features:**
- Conditional logic with user data
- Compound conditions using `&&` and `||`
- Template-based condition evaluation
- Fallback routing for unmatched conditions

**Example:**
```json
{
  "id": "check_first_visit",
  "type": "autoroute",
  "routes": [
    {
      "condition": "session.visitCount == 1",
      "target": "onboarding_start"
    },
    {
      "condition": "task.currentStatus == 'pending'",
      "target": "task_check"
    },
    {
      "default": true,
      "target": "welcome_back"
    }
  ]
}
```

### 6. Data Actions (`dataAction`)
Direct data manipulation operations.

**Operation Types:**
- `set` - Set value or template function
- `increment` - Add to numeric values
- `decrement` - Subtract from numeric values
- `reset` - Reset to default value
- `trigger` - Fire events with custom data

**Example:**
```json
{
  "id": "update_streak",
  "type": "dataAction",
  "action": {
    "type": "increment",
    "key": "user.streak",
    "value": 1
  }
}
```

## Conversation Flow Management

### Sequence System
Conversations are organized into sequences loaded from JSON files.

**Available Sequences:**
- `welcome_seq` - Entry point and routing
- `onboarding_seq` - New user setup
- `taskChecking_seq` - Returning user task checking
- `taskSetting_seq` - Daily planning and configuration
- `sendoff_seq` - Session conclusion
- `success_seq` - Task completion celebration
- `failure_seq` - Task failure handling

### Routing Logic
The system uses conditional routing to determine conversation flow:

**Routing Conditions:**
- User data values (`user.streak > 5`)
- Session information (`session.visitCount == 1`)
- Task status (`task.currentStatus == 'pending'`)
- Time-based conditions (`task.isPastDeadline == true`)
- Complex combinations (`session.visitCount > 1 && task.isActiveDay == true`)

### Cross-Sequence Navigation
Conversations can navigate between sequences using choice targets:

```json
{
  "text": "Let's set up your task",
  "sequenceId": "taskSetting_seq"
}
```

## Data Integration

### Template System
Dynamic content using template substitution:

**Basic Templates:**
- `{user.name|Anonymous}` - User data with fallback
- `{task.startTime|10:00}` - Task configuration
- `{session.timeOfDay:timeOfDay|morning}` - Formatted session data

**Advanced Templates:**
- `{task.activeDays:activeDays:join:upper}` - Formatted array with case transformation
- `{user.streak:increment}` - Dynamic calculations
- `{TODAY_DATE}` - Template functions

### Semantic Content Resolution
Dynamic content selection using semantic keys:

**Content Structure:**
```
assets/content/
├── bot/
│   ├── acknowledge/
│   │   ├── completion/
│   │   │   ├── positive.json
│   │   │   └── neutral.json
│   │   └── effort.json
│   └── greet/
└── user/
```

**Usage:**
```json
{
  "text": "Great job!",
  "contentKey": "bot.acknowledge.completion.positive"
}
```

## State Management

### Chat State
The chat system manages several types of state:

**Message State:**
- Current message queue
- Display state for each message
- Animation triggers and timing

**Conversation State:**
- Current sequence and position
- Route history and navigation stack
- Pending user inputs and validations

**Integration State:**
- Notification scheduling
- Animation coordination
- Data synchronization

### State Synchronization
State changes are coordinated across the system:

1. **User Action** → State Update → Service Notification
2. **Data Change** → Template Re-evaluation → UI Update
3. **Route Change** → Sequence Loading → Message Display

## Animation Integration

### Inline Animations
Messages can include Rive animations directly:

```json
{
  "text": "Congratulations!",
  "animation": {
    "asset": "assets/animations/celebration.riv",
    "zone": 1,
    "autoHideMs": 3000
  }
}
```

### Triggered Animations
Data actions can trigger overlay animations:

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

## Error Handling

### Graceful Degradation
The system handles errors gracefully:

**Missing Content:**
- Fallback to default content
- Log warning but continue conversation
- Use hardcoded fallbacks if needed

**Invalid Routes:**
- Default to safe conversation paths
- Log routing errors for debugging
- Maintain conversation continuity

**Data Errors:**
- Validate all user inputs
- Sanitize template substitutions
- Handle missing data gracefully

### Debug Support
Comprehensive debugging through UserPanelOverlay:

**Features:**
- Live conversation state inspection
- Manual sequence switching
- Variable editing and testing
- Route testing with different conditions

## Performance Considerations

### Lazy Loading
- Sequences loaded on demand
- Animation assets cached efficiently
- Template compilation optimized

### Memory Management
- Message history pruning
- Animation cleanup after display
- Efficient state storage

### Responsive Design
- Smooth animation transitions
- Instant response to user input
- Background processing for route calculation

## See Also

- **[Task Calculation System](task-calculation-system.md)** - Task status logic used in routing
- **[Notification Scheduling](notification-scheduling.md)** - Integration with notification system
- **[Rive Animation Zones](../reference/rive-animation-zones.md)** - Animation system integration
- **[Content Authoring Guide](../authoring/CONTENT_AUTHORING_GUIDE.md)** - Creating conversation content