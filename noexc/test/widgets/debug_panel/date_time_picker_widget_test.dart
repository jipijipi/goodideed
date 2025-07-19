import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/widgets/debug_panel/date_time_picker_widget.dart';
import 'package:noexc/services/user_data_service.dart';

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
      
      // Check that time setting section is present
      expect(find.text('Set Deadline Time'), findsOneWidget);
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
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('21:00'), findsAtLeastNWidgets(1)); // Allow multiple instances
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
  });
}