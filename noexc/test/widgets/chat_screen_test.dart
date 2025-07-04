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
      await tester.pump();
      
      // Verify content area exists
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}