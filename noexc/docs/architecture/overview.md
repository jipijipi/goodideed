# Architecture Overview

**← [Documentation Index](../README.md)**

## System Architecture

The noexc app uses a layered architecture built around Flutter with several key systems working together to create a conversational habit tracking experience.

## Core Components

### 1. Chat System
The heart of the application, managing conversational flows and user interactions.

**Key Services:**
- `ChatService` - Main orchestrator with focused processors
- `SequenceLoader` - Loads and validates conversation JSON
- `MessageProcessor` - Handles message rendering and types
- `RouteProcessor` - Manages conversation flow routing

**Message Types:**
- `bot` - Bot responses with optional animations
- `user` - User text input responses
- `choice` - Multiple choice interactions with data persistence
- `textInput` - Free text input with validation
- `autoroute` - Automatic routing based on user data conditions
- `dataAction` - Data modification operations (set, increment, etc.)

### 2. Data Management
Local-first data storage with template-driven dynamic content.

**Services:**
- `UserDataService` - SharedPreferences-based local storage
- `SessionService` - Session tracking with daily reset functionality
- `SemanticContentService` - Dynamic content resolution with graceful fallbacks

**Data Flow:**
```
User Input → UserDataService → Template Processing → Content Resolution → UI Update
```

### 3. Notification System
Comprehensive notification management with cross-platform support.

**Components:**
- `NotificationService` - Platform notification handling
- `AppStateService` - Cross-session state management
- Rich notification payloads with JSON parsing
- 5-state permission model (granted, denied, notRequested, restricted, unknown)

**Notification Types:**
- Daily reminders with task context
- Achievement notifications
- System alerts and warnings

### 4. Animation System
Multi-zone Rive animation system for interactive experiences.

**Zone Layout:**
1. **Zone 1**: Inline chat bubble animations
2. **Zone 2**: Overlay animations (achievements, trophies) - Top layer
3. **Zone 3**: Background animations - Behind messages
4. **Zone 4**: Interactive animations - Above messages, below UI panels

**Features:**
- Data-bound animations with template integration
- Script-triggered overlay effects
- Real-time parameter updates

### 5. Content Authoring
Visual authoring system for creating conversation flows.

**Tools:**
- React Flow-based authoring interface
- Group-based sequence organization
- Cross-sequence navigation with auto-detection
- Direct Flutter JSON export

## Data Architecture

### Storage Strategy
- **Local Storage**: SharedPreferences for user data persistence
- **Asset Storage**: JSON files for conversation sequences and semantic content
- **Session Management**: Daily reset with visit tracking

### Template System
Dynamic content using `{key|fallback}` syntax with formatter support:

```
{user.name|Anonymous}              # Basic template
{task.startTime:timeOfDay|morning} # With formatter
{task.activeDays:activeDays:join:upper|WEEKDAYS} # Complex formatting
```

### Content Resolution
8-level fallback chain for semantic content:
1. Exact match: `bot.acknowledge.completion.positive`
2. Drop last segment: `bot.acknowledge.completion`
3. Drop two segments: `bot.acknowledge`
4. Continue until base: `bot`
5. Fallback to generic content
6. Fallback to legacy variants
7. Fallback to hardcoded defaults
8. Error state handling

## Service Architecture

### Service Dependencies
```
ChatService
├── SequenceLoader
├── MessageProcessor
├── RouteProcessor
└── UserDataService
    ├── SessionService
    ├── SemanticContentService
    └── NotificationService
        └── AppStateService
```

### Logging Architecture
Centralized logging with component-specific methods:
- `LoggerService` - Main logging service (NEVER use print!)
- Component methods: `logger.route()`, `logger.semantic()`, `logger.ui()`
- Log levels: debug, info, warning, error, critical

## UI Architecture

### Screen Structure
```
ChatScreen (Main Container)
├── ChatStateManager
│   ├── ServiceManager - Service coordination
│   ├── MessageDisplayManager - Message rendering
│   └── UserInteractionHandler - Input processing
├── RiveOverlaySystem - Multi-zone animations
└── UserPanelOverlay - Debug panel
```

### State Management
- Service-based state management
- Reactive updates through service notifications
- Local state for UI-specific concerns

## Testing Architecture

### Test Organization (350+ tests)
```
test/
├── models/          # Data model validation
├── services/        # Business logic testing
├── ui/             # Widget and interaction tests
└── integration/    # Cross-component testing
```

### Testing Strategy
- **Test-Driven Development** (Red-Green-Refactor)
- Mock services for isolated testing
- Comprehensive notification system testing (67 tests)
- Platform-specific test handling

## Security & Privacy

### Data Privacy
- Local-first data storage (no cloud sync)
- User data never leaves device
- Anonymous usage patterns only

### Security Measures
- Input validation on all user data
- Template injection protection
- Secure notification payload handling

## Platform Considerations

### Cross-Platform Support
- **iOS**: Native notification handling with permission management
- **Android**: Platform-specific notification scheduling
- **macOS**: Desktop notification support
- **Web**: Limited notification support with graceful degradation

### Performance Optimizations
- Lazy loading of conversation sequences
- Efficient animation rendering with zone-based management
- Minimal memory footprint with local storage

## Integration Points

### External Systems
- **Rive Runtime**: Animation rendering and data binding
- **Platform Notifications**: iOS/Android notification systems
- **SharedPreferences**: Cross-platform local storage

### Internal APIs
- Service-to-service communication through defined interfaces
- Event-driven updates for UI synchronization
- Template engine integration across all content

## Development Workflow

### Key Principles
1. **Test-Driven Development** - Write tests before implementation
2. **Service-Oriented Design** - Clear separation of concerns
3. **Template-Driven Content** - Dynamic content resolution
4. **Local-First Architecture** - No external dependencies

### File Organization
```
lib/
├── models/         # Data structures and enums
├── services/       # Core business logic
├── ui/            # User interface components
└── utils/         # Shared utilities and helpers
```

## See Also

- **[Chat System](chat-system.md)** - Detailed conversation flow architecture
- **[Task Calculation System](task-calculation-system.md)** - Task status and timing logic
- **[Notification Scheduling](notification-scheduling.md)** - Notification system details
- **[Rive Animation Zones](../reference/rive-animation-zones.md)** - Animation system reference