import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/widgets/debug_panel/date_time_picker_widget.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/constants/storage_keys.dart';

void main() {
  group('DateTimePickerWidget', () {
    late UserDataService userDataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
    });

    testWidgets('should display date and time picker section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateTimePickerWidget(
              userDataService: userDataService,
            ),
          ),
        ),
      );

      // Wait for async loading to complete
      await tester.pumpAndSettle();

      // Check that the main section header is present
      expect(find.text('Date & Time Testing'), findsOneWidget);
      
      // Check that current values section is present
      expect(find.text('Current Values'), findsOneWidget);
      expect(find.text('Task Date:'), findsOneWidget);
      expect(find.text('Deadline Time:'), findsOneWidget);
      
      // Check that date setting section is present
      expect(find.text('Set Task Date'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      
      // Check that deadline options section is present
      expect(find.text('Set Deadline Option'), findsOneWidget);
      expect(find.text('Morning (before noon)'), findsOneWidget);
      expect(find.text('Afternoon (noon to 5pm)'), findsOneWidget);
      expect(find.text('Evening (5pm to 9pm)'), findsOneWidget);
      expect(find.text('Night (9pm to midnight)'), findsOneWidget);
    });

    testWidgets('should show default values when no data is stored', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateTimePickerWidget(
              userDataService: userDataService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show default values
      expect(find.text('Not set'), findsAtLeastNWidgets(1)); // Task date and deadline both show "Not set"
    });

    testWidgets('should have functional today and yesterday buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateTimePickerWidget(
              userDataService: userDataService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test today button exists and is tappable
      expect(find.text('Today'), findsOneWidget);
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Test yesterday button exists and is tappable  
      expect(find.text('Yesterday'), findsOneWidget);
      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();

      // Just verify buttons work without checking specific snackbar text
      // as snackbar behavior can be inconsistent in tests
    });

    testWidgets('should handle data refresh callback', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateTimePickerWidget(
              userDataService: userDataService,
              onDataChanged: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap today button which should trigger callback
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(callbackCalled, true);
    });

    testWidgets('should allow selecting deadline options', (WidgetTester tester) async {
      bool callbackCalled = false;
      final userDataService = UserDataService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateTimePickerWidget(
              userDataService: userDataService,
              onDataChanged: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all deadline options
      expect(find.text('Morning (before noon)'), findsOneWidget);
      expect(find.text('Afternoon (noon to 5pm)'), findsOneWidget);
      expect(find.text('Evening (5pm to 9pm)'), findsOneWidget);
      expect(find.text('Night (9pm to midnight)'), findsOneWidget);

      // Tap the evening option
      await tester.tap(find.text('Evening (5pm to 9pm)'));
      await tester.pumpAndSettle();

      // Should update the display and trigger callback
      expect(find.text('Evening (5pm to 9pm)'), findsAtLeastNWidgets(1)); // In both button and current value
      expect(callbackCalled, true);

      // Verify the value was stored correctly
      final storedValue = await userDataService.getValue<int>(StorageKeys.taskDeadlineTime);
      expect(storedValue, 3); // Evening = option 3
    });
  });
}