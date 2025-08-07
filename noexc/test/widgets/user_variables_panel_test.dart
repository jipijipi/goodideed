import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/widgets/user_variables_panel.dart';
import 'package:noexc/services/user_data_service.dart';
import 'test_utils.dart';

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
      await tester.pump(TestUtils.quickPump);
      
      // Should show debug panel header
      expect(find.text('Debug Panel'), findsOneWidget);
      // Check for any visible content in the panel
      expect(find.byType(UserVariablesPanel), findsOneWidget);
    });

    testWidgets('can be instantiated with required parameters', (WidgetTester tester) async {
      final userDataService = UserDataService();
      
      expect(() => UserVariablesPanel(userDataService: userDataService), returnsNormally);
    });
  });
}