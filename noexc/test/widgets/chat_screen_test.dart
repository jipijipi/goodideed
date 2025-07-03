import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/widgets/chat_screen.dart';

void main() {
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
      
      // Clean up any pending timers
      await tester.pumpAndSettle();
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Clean up any pending timers
      await tester.pumpAndSettle();
    });

    testWidgets('should eventually display chat content', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pump();
      
      // Verify loading is done and content area exists
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      
      // Clean up any pending timers
      await tester.pumpAndSettle();
    });
  });
}