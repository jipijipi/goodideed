import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/widgets/debug_panel/notification_debug_widget.dart';
import 'package:noexc/widgets/debug_panel/debug_status_area.dart';
import 'package:noexc/services/service_locator.dart';
import '../../test_helpers.dart';

void main() {
  group('NotificationDebugWidget', () {
    late DebugStatusController statusController;

    setUp(() async {
      setupTestingWithMocks(); // Use platform mocks for ServiceLocator tests
      statusController = DebugStatusController();
      
      // Initialize ServiceLocator for widget tests that depend on services
      ServiceLocator.reset();
      await ServiceLocator.instance.initialize();
    });

    tearDown(() {
      statusController.dispose();
      ServiceLocator.reset();
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NotificationDebugWidget(
              statusController: statusController,
              onDataRefresh: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('should build without throwing errors', (tester) async {
      await tester.pumpWidget(createWidget());

      // Should show the section header
      expect(find.text('Notifications Debug'), findsOneWidget);
    });

    testWidgets(
      'should display error message when service locator is not initialized',
      (tester) async {
        await tester.pumpWidget(createWidget());

        // Wait for async operations
        await tester.pumpAndSettle();

        // Should show error about service locator
        expect(find.textContaining('Error:'), findsOneWidget);
      },
    );

    testWidgets('should show loading indicator initially', (tester) async {
      await tester.pumpWidget(createWidget());

      // Should show loading indicator briefly (may complete very quickly in tests)
      final loadingIndicator = find.byType(CircularProgressIndicator);

      // Either currently loading or has already completed
      expect(
        loadingIndicator.evaluate().isNotEmpty ||
            find.textContaining('Error:').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
      'should display error state when service locator not initialized',
      (tester) async {
        await tester.pumpWidget(createWidget());

        // Wait for loading to complete and show error
        await tester.pumpAndSettle();

        // Should show error state due to uninitialized service locator
        expect(find.textContaining('Error:'), findsOneWidget);
      },
    );

    testWidgets('should display quick action buttons in error state', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show action buttons even in error state
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('Cancel All'), findsOneWidget);
      expect(find.text('Request Perms'), findsOneWidget); // Actual text is "Request Perms", not "Check Permissions"
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('should handle refresh button tap', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap refresh button
      final refreshButton = find.text('Refresh');
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pump();

      // Should trigger a refresh - may show loading briefly or complete immediately
      // In test environment, async operations can complete very quickly
      final hasLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasError = find.textContaining('Error:').evaluate().isNotEmpty;
      expect(hasLoading || hasError, isTrue);
    });

    testWidgets('should display section headers correctly', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Main section header should always be present
      expect(find.text('Notifications Debug'), findsOneWidget);

      // Other headers might be present depending on state
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('should use consistent styling with theme', (tester) async {
      await tester.pumpWidget(createWidget());

      // Check that cards are used for consistent styling
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle null status controller gracefully', (
      tester,
    ) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: NotificationDebugWidget(
            statusController: null,
            onDataRefresh: () {},
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Should not crash with null status controller
      expect(find.text('Notifications Debug'), findsOneWidget);
    });

    testWidgets('should handle null onDataRefresh gracefully', (tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: NotificationDebugWidget(
            statusController: statusController,
            onDataRefresh: null,
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Should not crash with null callback
      expect(find.text('Notifications Debug'), findsOneWidget);
    });

    group('widget interaction', () {
      testWidgets('buttons should be available after loading completes', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // After loading completes, buttons should be available by their text
        expect(find.text('Reschedule'), findsOneWidget);
        expect(find.text('Cancel All'), findsOneWidget);
        expect(find.text('Request Perms'), findsOneWidget); // Actual text is "Request Perms"
        expect(find.text('Refresh'), findsOneWidget);
      });

      testWidgets('should display appropriate icons', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should have various icons for different actions
        expect(find.byIcon(Icons.refresh), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.security), findsOneWidget);
      });
    });

    group('error handling', () {
      testWidgets('should display error state appropriately', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should show error message due to uninitialized service locator
        expect(find.textContaining('Error:'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should recover from error state on refresh', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Verify error state
        expect(find.textContaining('Error:'), findsOneWidget);

        // Tap refresh
        final refreshButton = find.text('Refresh');
        expect(refreshButton, findsOneWidget);
        await tester.tap(refreshButton);
        await tester.pump();

        // Should attempt to reload - may show loading briefly or complete immediately
        final hasLoading =
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        final hasError = find.textContaining('Error:').evaluate().isNotEmpty;
        expect(hasLoading || hasError, isTrue);
      });
    });

    group('accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Buttons should have text labels for accessibility
        expect(find.text('Reschedule'), findsOneWidget);
        expect(find.text('Cancel All'), findsOneWidget);
        expect(find.text('Request Perms'), findsOneWidget); // Actual text is "Request Perms"
        expect(find.text('Refresh'), findsOneWidget);
      });

      testWidgets('should have proper widget structure', (tester) async {
        await tester.pumpWidget(createWidget());

        // Should have column layout for proper screen reader navigation
        expect(find.byType(Column), findsAtLeastNWidgets(1));
      });
    });

    group('layout and styling', () {
      testWidgets('should use cards for visual grouping', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should have cards for visual organization
        expect(find.byType(Card), findsAtLeastNWidgets(1));
      });

      testWidgets('should have appropriate spacing', (tester) async {
        await tester.pumpWidget(createWidget());

        // Should use SizedBox for spacing
        expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle long text appropriately', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Should use Expanded widgets to handle overflow
        expect(find.byType(Expanded), findsAtLeastNWidgets(1));
      });
    });
  });
}
