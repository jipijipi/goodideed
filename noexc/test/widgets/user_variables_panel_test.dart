import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/widgets/user_variables_panel.dart';
import 'package:noexc/services/user_data_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserVariablesPanel', () {
    testWidgets('displays header correctly', (WidgetTester tester) async {
      final userDataService = UserDataService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserVariablesPanel(userDataService: userDataService),
          ),
        ),
      );

      expect(find.text('Debug Panel'), findsOneWidget);
    });

    testWidgets('shows debug information initially', (WidgetTester tester) async {
      final userDataService = UserDataService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserVariablesPanel(userDataService: userDataService),
          ),
        ),
      );

      // Wait for initial loading to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should show debug information section
      expect(find.text('Debug Information'), findsOneWidget);
      expect(find.text('Flutter Framework'), findsOneWidget);
    });

    testWidgets('can be instantiated with required parameters', (WidgetTester tester) async {
      final userDataService = UserDataService();
      
      expect(() => UserVariablesPanel(userDataService: userDataService), returnsNormally);
    });
  });
}