# Testing Guide

Test-Driven Development workflow and testing commands for the noexc project.

## TDD Philosophy

The project follows **Test-Driven Development** (TDD):
1. **Red**: Write a failing test
2. **Green**: Write minimal code to pass
3. **Refactor**: Improve code while keeping tests passing

## Test Structure

Tests mirror the `lib/` directory structure:

```
test/
├── models/            # Model tests
├── services/          # Service tests
├── ui/               # Widget tests
├── utils/            # Utility tests
└── test_helpers.dart # Common test utilities
```

## Test Commands

### Standard Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/chat_service_test.dart

# Run tests in directory
flutter test test/services/

# Run tests with pattern
flutter test --name "should handle errors"

# Verbose output
flutter test --verbose
```

### TDD-Optimized Commands

For reduced verbosity during TDD cycles:

```bash
# Single file, minimal output
dart tool/tdd_runner.dart --quiet test/services/specific_test.dart

# Directory testing with minimal noise
dart tool/tdd_runner.dart -q test/models/

# Target specific test patterns
dart tool/tdd_runner.dart --name "specific test pattern"

# Built-in compact reporter
flutter test --reporter compact test/specific_test.dart
```

### Focused Testing

```bash
# Single service test
flutter test test/services/logger_service_test.dart

# Directory with limited concurrency
flutter test test/models/ --concurrency=2

# Pattern-based test selection
flutter test --name "should handle errors"

# Run only TDD-tagged tests
flutter test --tags tdd
```

## Test Categories

### Unit Tests (350+ tests)
- **Models**: Data validation, serialization
- **Services**: Business logic, API calls
- **Utils**: Helper functions, formatters

### Widget Tests
- **UI Components**: Widget behavior
- **State Management**: State changes
- **User Interactions**: Tap, input events

### Integration Tests
- **Service Integration**: Cross-service communication
- **Notification System**: 67 comprehensive tests
- **Template System**: Dynamic content resolution

## Writing Tests

### Test Setup

```dart
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

void main() {
  setUp(() {
    setupQuietTesting(); // Reduces log noise during TDD
    // ... other test setup
  });

  group('ServiceName', () {
    test('should handle valid input', () {
      // Arrange
      final service = ServiceName();

      // Act
      final result = service.process('valid input');

      // Assert
      expect(result, isNotNull);
    });
  });
}
```

### Mock Services

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([UserDataService])
import 'service_test.mocks.dart';

void main() {
  late MockUserDataService mockUserDataService;

  setUp(() {
    mockUserDataService = MockUserDataService();
  });

  test('should use mocked service', () {
    when(mockUserDataService.getValue('key'))
        .thenReturn('mocked value');

    // Test with mock
  });
}
```

### Testing Async Code

```dart
test('should handle async operations', () async {
  final service = AsyncService();

  final result = await service.fetchData();

  expect(result, isNotNull);
});
```

### Testing Streams

```dart
test('should emit correct values', () async {
  final stream = service.dataStream;

  expect(stream, emitsInOrder([
    'first value',
    'second value',
    emitsDone,
  ]));
});
```

## Test Organization

### Naming Conventions

```dart
group('ClassName', () {
  group('methodName', () {
    test('should return expected result when given valid input', () {
      // Test implementation
    });

    test('should throw exception when given invalid input', () {
      // Test implementation
    });
  });
});
```

### Test Categories

```dart
test('should validate user input', () {
  // Implementation
}, tags: ['validation']);

test('should integrate with external service', () {
  // Implementation
}, tags: ['integration']);

test('should perform TDD cycle', () {
  // Implementation
}, tags: ['tdd']);
```

## Notification System Testing

### Permission State Testing

```dart
test('should handle all permission states', () async {
  // Test granted state
  when(mockNotificationService.getPermissionStatus())
      .thenAnswer((_) async => NotificationPermissionStatus.granted);

  // Test denied state
  when(mockNotificationService.getPermissionStatus())
      .thenAnswer((_) async => NotificationPermissionStatus.denied);

  // ... test all 5 states
});
```

### Cross-Session Testing

```dart
test('should persist notification tap events across sessions', () async {
  final event = NotificationTapEvent(
    notificationId: 1001,
    timestamp: DateTime.now(),
    payload: {'type': 'dailyReminder'},
  );

  await appStateService.storeNotificationTapEvent(event);

  // Simulate app restart
  final newService = AppStateService();
  final pendingEvent = await newService.consumePendingNotification();

  expect(pendingEvent, isNotNull);
  expect(pendingEvent!.notificationId, equals(1001));
});
```

## Coverage

### Running Coverage

```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Goals
- **Unit Tests**: 90%+ coverage
- **Critical Services**: 95%+ coverage
- **Models**: 100% coverage (simple data classes)

## Debugging Tests

### Print Debugging (Avoid)
```dart
// DON'T DO THIS
print('Debug value: $value');

// DO THIS INSTEAD
final logger = LoggerService();
logger.debug('Debug value: $value');
```

### Test Debugging

```dart
test('debug failing test', () {
  final service = ServiceName();

  // Add temporary debugging
  debugPrint('Service state: ${service.state}');

  final result = service.process(input);

  expect(result, expectedValue);
});
```

### VS Code Test Debugging

1. Set breakpoints in test files
2. Press F5 to debug current test
3. Use Debug Console for inspection

## Continuous Integration

### GitHub Actions

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

## Best Practices

### Test Structure
1. **Arrange**: Set up test conditions
2. **Act**: Execute the code under test
3. **Assert**: Verify the results

### Test Isolation
- Each test should be independent
- Use `setUp()` and `tearDown()` for common setup
- Mock external dependencies

### Test Readability
- Use descriptive test names
- Keep tests focused on single behavior
- Add comments for complex test logic

### Performance
- Use TDD-optimized commands for fast feedback
- Run subset of tests during development
- Run full suite before commits

## Common Patterns

### Testing Exceptions

```dart
test('should throw exception for invalid input', () {
  final service = ServiceName();

  expect(
    () => service.process(null),
    throwsA(isA<ArgumentError>()),
  );
});
```

### Testing State Changes

```dart
testWidgets('should update UI when state changes', (tester) async {
  await tester.pumpWidget(TestWidget());

  // Initial state
  expect(find.text('Initial'), findsOneWidget);

  // Trigger state change
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Verify new state
  expect(find.text('Updated'), findsOneWidget);
});
```

## See Also

- **[Testing Best Practices](../development/TESTING_BEST_PRACTICES.md)** - Detailed testing guidelines
- **[Development Setup](development-setup.md)** - Environment configuration
- **[Logging Guide](../development/LOGGING_GUIDE.md)** - Debugging and logging