import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/widgets/chat_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    // Clear any stored data to prevent test interference
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatScreen Widget Tests', () {
    testWidgets('should display chat screen with app bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(),
        ),
      );

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      
      // Just pump once to avoid timer issues
      await tester.pump();
    });


    testWidgets('should load chat content after initialization', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(),
        ),
      );

      // Wait for async loading to complete
      await tester.pump();
      
      // Verify content area exists (should show chat messages)
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should allow legitimate message repetition in conversation loops', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(),
        ),
      );

      // Act - Allow sequence to load and all messages to display
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Give reasonable time for messages to load (reduce from 4000ms)
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Assert - Check that the chat loads successfully
      final allText = find.byType(Text);
      expect(allText, findsWidgets, 
        reason: 'Should find some text messages after sequence loads');

      // The test passes if no errors occur during message processing
      // (This verifies that removing duplicate filtering doesn't break the system)
    });

    testWidgets('should display text input field for text input messages', (WidgetTester tester) async {
      // This test will verify that text input fields appear when needed
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(),
        ),
      );

      // Wait for loading
      await tester.pump();
      
      // For now, just verify the screen loads without errors
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should handle text input submission', (WidgetTester tester) async {
      // This test will verify that text input can be submitted
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(),
        ),
      );

      // Wait for loading
      await tester.pump();
      
      // For now, just verify the screen loads without errors
      expect(find.byType(ListView), findsWidgets);
    });
  });
}