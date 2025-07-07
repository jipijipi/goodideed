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

      expect(find.text('My Information'), findsOneWidget);
    });

    testWidgets('shows empty state initially', (WidgetTester tester) async {
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
      
      expect(find.text('No information stored yet'), findsOneWidget);
    });

    testWidgets('can be instantiated with required parameters', (WidgetTester tester) async {
      final userDataService = UserDataService();
      
      expect(() => UserVariablesPanel(userDataService: userDataService), returnsNormally);
    });
  });
}