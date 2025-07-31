# CLI Conversation Testing Guide

A comprehensive guide for testing conversation flows without loading the UI.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation & Setup](#installation--setup)
3. [Basic Usage](#basic-usage)
4. [Advanced Testing](#advanced-testing)
5. [Scenarios & User States](#scenarios--user-states)
6. [Debugging & Troubleshooting](#debugging--troubleshooting)
7. [Test Automation](#test-automation)
8. [Best Practices](#best-practices)
9. [Reference](#reference)

## Quick Start

### Test a conversation in 30 seconds:

```bash
# 1. Quick sequence test (standalone)
dart tool/conversation_cli_standalone.dart --sequence welcome_seq

# 2. Full conversation test (with Flutter services)
flutter test test/cli/conversation_test.dart --name "welcome_seq"

# 3. Test with user scenario
flutter test test/cli/conversation_test.dart --name "Returning User"
```

## Installation & Setup

### Prerequisites

- Flutter SDK installed
- Dart SDK (comes with Flutter)
- Access to the noexc project repository

### Verify Installation

```bash
# Check Flutter is working
flutter doctor

# Verify CLI tools exist
ls tool/conversation_cli_standalone.dart
ls test/cli/conversation_runner.dart

# Run a quick test
dart tool/conversation_cli_standalone.dart --help
```

## Basic Usage

### 1. Standalone CLI (Basic Testing)

The standalone CLI provides quick testing without Flutter dependencies:

```bash
# Show help
dart tool/conversation_cli_standalone.dart --help

# List available sequences
dart tool/conversation_cli_standalone.dart --list-sequences

# List available scenarios  
dart tool/conversation_cli_standalone.dart --list-scenarios

# Test a sequence
dart tool/conversation_cli_standalone.dart --sequence onboarding_seq --verbose
```

**Note**: Standalone CLI shows what *would* happen but doesn't run actual conversations.

### 2. Full Conversation Testing

For complete conversation testing with actual Flutter services:

```bash
# Run specific conversation test
flutter test test/cli/conversation_test.dart --name "should run welcome_seq"

# Test with scenario
flutter test test/cli/conversation_test.dart --name "Returning User"

# Run all conversation tests
flutter test test/cli/conversation_test.dart

# Run workflow demonstration
flutter test test/cli/conversation_test.dart --name "workflow"
```

### 3. Understanding Test Output

**Colored Output**: Bot messages in cyan, user responses in green, system info in yellow
**Routing Info**: Shows autoroute decisions and condition evaluations
**Content Resolution**: Displays semantic content loading and fallbacks
**Performance**: Shows execution time and message counts

Example output:
```
🚀 Initializing conversation runner...
📋 Sequence: welcome_seq
🤖 Hello! I'm Tristopher
👤 Nice to meet you!
✅ Conversation completed (15 messages, 1.2s)
```

## Advanced Testing

### Testing Specific User States

```bash
# Test new user flow
flutter test test/cli/conversation_test.dart --name "new_user"

# Test returning user with existing task
flutter test test/cli/conversation_test.dart --name "returning_user"

# Test weekend user (inactive day)
flutter test test/cli/conversation_test.dart --name "weekend_user"

# Test user past deadline
flutter test test/cli/conversation_test.dart --name "past_deadline"
```

### Custom Test Creation

Create custom tests in `test/cli/conversation_test.dart`:

```dart
test('Custom user scenario', () async {
  final result = await runConversation(
    sequenceId: 'welcome_seq',
    userState: {
      'user.name': 'Custom User',
      'user.streak': 15,
      'session.visitCount': 10,
      'task.isActiveDay': true,
    },
    interactive: false,
    verbose: true,
  );
  
  expect(result.completed, isTrue);
  expect(result.finalUserState['user.name'], equals('Custom User'));
});
```

### Testing with Auto-Responses

Test non-interactive flows with predetermined responses:

```dart
test('Automated conversation flow', () async {
  final result = await runConversation(
    sequenceId: 'onboarding_seq',
    autoResponses: [
      'choice:1',           // Select first choice
      'text:My daily task', // Enter text input
      'choice:2',           // Select second choice
    ],
    interactive: false,
    verbose: true,
  );
  
  expect(result.completed, isTrue);
});
```

## Scenarios & User States

### Built-in Test Scenarios

| Scenario | Description | Key Variables |
|----------|-------------|---------------|
| **New User** | First-time app user | `user.name: null`, `user.isOnboarded: false` |
| **Returning User** | Active user with history | `session.visitCount: 3`, `task.status: pending` |
| **Weekend User** | User on inactive day | `session.isWeekend: true`, `task.isActiveDay: false` |
| **Past Deadline** | User who missed deadline | `task.status: overdue`, `task.isPastDeadline: true` |

### Creating Custom Scenarios

1. **Edit built-in scenarios** in `test/cli/conversation_runner.dart`:

```dart
final customScenarios = {
  'power_user': {
    'user.name': 'Power User',
    'user.streak': 50,
    'session.totalVisitCount': 100,
    'task.status': 'completed',
  },
};
```

2. **Use scenarios in tests**:

```dart
final scenario = await loadScenario('power_user');
final result = await runConversation(
  sequenceId: 'welcome_seq',
  userState: scenario,
);
```

### Variable Reference

#### User Variables
- `user.name` - User's display name
- `user.isOnboarded` - Onboarding completion status
- `user.streak` - Current completion streak
- `user.task` - Current daily task

#### Session Variables  
- `session.visitCount` - Daily visit count (resets daily)
- `session.totalVisitCount` - Lifetime visit count
- `session.timeOfDay` - Time period (1=morning, 2=afternoon, 3=evening, 4=night)
- `session.isWeekend` - Weekend detection

#### Task Variables
- `task.currentDate` - Current task date (YYYY-MM-DD)
- `task.status` - Task status (pending, completed, failed, overdue)
- `task.deadlineTime` - Deadline option (1-4 integer)
- `task.isActiveDay` - Computed: Is today an active day?
- `task.isPastDeadline` - Computed: Is current time past deadline?

## Debugging & Troubleshooting

### Enable Verbose Output

```bash
# Show detailed logging
flutter test test/cli/conversation_test.dart --name "welcome_seq" -- --verbose

# Or in test code
await runConversation(
  sequenceId: 'welcome_seq',
  verbose: true,  // Shows routing decisions, content resolution, etc.
);
```

### Common Issues

#### ❌ "Sequence not found"
**Problem**: Invalid sequence ID
**Solution**: Check available sequences with `--list-sequences`

#### ❌ "Condition evaluation failed"  
**Problem**: Invalid condition syntax in JSON
**Solution**: Check sequence JSON for proper condition format

#### ❌ "Template variable not found"
**Problem**: Template references undefined variable
**Solution**: Ensure user state includes required variables

#### ❌ "Content resolution failed"
**Problem**: Missing semantic content files
**Solution**: Check `assets/content/` directory structure

### Debug Output Interpretation

```
🚏 AUTOROUTE: Processing autoroute message ID: 1
🔍 CONDITION_EVAL: Evaluating "user.isOnboarded == true"
✅ CONDITION_EVAL: Result: true
🔍 SEMANTIC_CONTENT: Resolving "bot.acknowledge.completion.positive"
✅ SEMANTIC_CONTENT: Success! Found content at path: content/bot/acknowledge/completion_positive.txt
```

**Symbols**:
- 🚏 Autoroute processing
- 🔍 Condition evaluation or content lookup
- ✅ Success
- ❌ Failure/Error
- ⚡ Cache hit
- 🔄 Fallback used

## Test Automation

### CI/CD Integration

Add to your CI pipeline:

```yaml
# .github/workflows/test.yml
- name: Run Conversation Tests
  run: |
    flutter test test/cli/conversation_test.dart
    dart tool/conversation_cli_standalone.dart --list-sequences
```

### Batch Testing

Test multiple sequences:

```bash
# Test core sequences
for seq in welcome_seq onboarding_seq active_seq; do
  echo "Testing $seq..."
  flutter test test/cli/conversation_test.dart --name "$seq"
done
```

### Performance Testing

```dart
test('Performance benchmark', () async {
  final stopwatch = Stopwatch()..start();
  
  for (int i = 0; i < 10; i++) {
    await runConversation(
      sequenceId: 'welcome_seq',
      interactive: false,
    );
  }
  
  stopwatch.stop();
  final avgTime = stopwatch.elapsedMilliseconds / 10;
  
  expect(avgTime, lessThan(2000)); // Should average < 2 seconds
});
```

## Best Practices

### 1. Test Design
- **Start with basic flows** before testing edge cases
- **Use descriptive test names** that explain the scenario
- **Test both happy paths and error conditions**
- **Include performance expectations**

### 2. Scenario Management
- **Keep scenarios realistic** - mirror actual user states
- **Document scenario purposes** in test comments
- **Group related scenarios** for batch testing
- **Update scenarios** when app logic changes

### 3. Debugging Strategy
- **Use verbose mode** for failing tests
- **Check one sequence at a time** when debugging
- **Verify user state setup** before testing logic
- **Compare with UI behavior** to validate accuracy

### 4. Maintenance
- **Run tests regularly** during development
- **Update tests** when sequences change
- **Add tests** for new conversation features
- **Keep documentation current** with code changes

## Reference

### Available Sequences

| Sequence ID | Purpose | Typical User State |
|-------------|---------|-------------------|
| `welcome_seq` | Entry point with routing | Any |
| `onboarding_seq` | New user setup | `user.isOnboarded: false` |
| `active_seq` | Active day management | `task.isActiveDay: true` |
| `inactive_seq` | Inactive day handling | `task.isActiveDay: false` |
| `pending_seq` | Pending task check | `task.status: pending` |
| `completed_seq` | Task completion flow | `task.status: completed` |
| `failed_seq` | Task failure handling | `task.status: failed` |
| `deadline_seq` | Deadline configuration | New task setup |
| `reminders_seq` | Reminder preferences | Configuration flow |
| `sendoff_seq` | Session conclusion | End of conversation |

### Command Reference

#### Standalone CLI
```bash
dart tool/conversation_cli_standalone.dart [OPTIONS]

Options:
  -s, --sequence <id>      Sequence to run (default: welcome_seq)
  --scenario <name>        Load predefined user scenario
  -a, --auto [responses]   Non-interactive mode with auto responses
  --verbose                Show detailed logging and state changes
  --list-sequences         List all available sequences
  --list-scenarios         List all available scenarios
  -v, --version           Show version information
  -h, --help              Show help message
```

#### Flutter Test CLI
```bash
flutter test test/cli/conversation_test.dart [OPTIONS]

Options:
  --name <pattern>         Run tests matching pattern
  --verbose               Show detailed output
  --coverage              Generate coverage report
```

### File Structure

```
test/cli/
├── conversation_runner.dart    # Core conversation engine
└── conversation_test.dart      # Test suite

tool/
├── chat_cli.dart              # Full CLI wrapper
└── conversation_cli_standalone.dart  # Standalone CLI

assets/
├── sequences/                 # JSON conversation files
├── content/                   # Semantic content files
└── debug/
    └── scenarios.json         # Predefined test scenarios
```

### Getting Help

- **Documentation**: See `CLAUDE.md` for architecture details
- **Code Examples**: Check `test/cli/conversation_test.dart` for patterns
- **Debugging**: Use `--verbose` flag for detailed output
- **Issues**: Report bugs or feature requests to the development team

---

**Happy Testing!** 🚀

This CLI testing system provides comprehensive coverage of conversation flows while maintaining 100% compatibility with the production Flutter app.