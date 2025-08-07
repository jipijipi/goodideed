import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/widgets/common/app_button.dart';
import 'package:noexc/constants/design_tokens.dart';
import '../test_utils.dart';

void main() {
  TestGroups.responsiveTests('AppButton', () {
    group('AppButton Widget Tests', () {
      testWidgets('renders primary button correctly', (tester) async {
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: const AppButton.primary(text: 'Test Button'),
          ),
        );

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('renders secondary button correctly', (tester) async {
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: const AppButton.secondary(text: 'Test Button'),
          ),
        );

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
      });

      testWidgets('renders outline button correctly', (tester) async {
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: const AppButton.outline(text: 'Test Button'),
          ),
        );

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('handles tap events', (tester) async {
        bool wasTapped = false;
        
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: AppButton.primary(
              text: 'Test Button',
              onPressed: () => wasTapped = true,
            ),
          ),
        );

        await tester.tapAndSettle(find.text('Test Button'));
        expect(wasTapped, isTrue);
      });

      testWidgets('shows loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          TestUtils.createMaterialApp(
            child: const AppButton.primary(
              text: 'Test Button',
              isLoading: true,
            ),
          ),
        );
        // Use pump() instead of pumpAndSettle() because CircularProgressIndicator never settles
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Test Button'), findsNothing);
      });

      testWidgets('displays icon when provided', (tester) async {
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: const AppButton.primary(
              text: 'Test Button',
              icon: Icons.add,
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('Test Button'), findsOneWidget);
      });

      testWidgets('respects size variants', (tester) async {
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: const Column(
              children: [
                AppButton.primary(text: 'Small', size: ButtonSize.small),
                AppButton.primary(text: 'Medium', size: ButtonSize.medium),
                AppButton.primary(text: 'Large', size: ButtonSize.large),
              ],
            ),
          ),
        );

        final smallButton = tester.widget<SizedBox>(
          find.ancestor(
            of: find.text('Small'),
            matching: find.byType(SizedBox),
          ).first,
        );
        
        final mediumButton = tester.widget<SizedBox>(
          find.ancestor(
            of: find.text('Medium'),
            matching: find.byType(SizedBox),
          ).first,
        );

        final largeButton = tester.widget<SizedBox>(
          find.ancestor(
            of: find.text('Large'),
            matching: find.byType(SizedBox),
          ).first,
        );

        expect(smallButton.height, equals(DesignTokens.buttonHeightS));
        expect(mediumButton.height, equals(DesignTokens.buttonHeightM));
        expect(largeButton.height, equals(DesignTokens.buttonHeightL));
      });

      testWidgets('expands to full width when isExpanded is true', (tester) async {
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: const AppButton.primary(
              text: 'Expanded Button',
              isExpanded: true,
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.text('Expanded Button'),
            matching: find.byType(SizedBox),
          ).first,
        );

        expect(sizedBox.width, equals(double.infinity));
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await TestUtils.pumpWithAnimation(
          tester,
          TestUtils.createMaterialApp(
            child: const AppButton.primary(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        );

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );

        expect(button.onPressed, isNull);
      });

      testWidgets('is disabled when loading', (tester) async {
        await tester.pumpWidget(
          TestUtils.createMaterialApp(
            child: AppButton.primary(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        );
        // Use pump() instead of pumpAndSettle() because CircularProgressIndicator never settles
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );

        expect(button.onPressed, isNull);
      });
    });
  });

  TestGroups.animationTests('AppButton', () {
    testWidgets('loading animation works correctly', (tester) async {
      bool isLoading = false;
      
      await TestUtils.pumpWithAnimation(
        tester,
        TestUtils.createMaterialApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return AppButton.primary(
                text: 'Toggle Loading',
                isLoading: isLoading,
                onPressed: () {
                  setState(() {
                    isLoading = !isLoading;
                  });
                },
              );
            },
          ),
        ),
      );

      // Initially not loading
      expect(find.text('Toggle Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap to start loading
      await tester.tap(find.text('Toggle Loading'));
      await tester.pump(); // Use pump() because loading state has infinite animation

      // Should now show loading indicator
      expect(find.text('Toggle Loading'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  TestGroups.accessibilityTests('AppButton', () {
    testWidgets('has proper semantics', (tester) async {
      await TestUtils.pumpWithAnimation(
        tester,
        TestUtils.createMaterialApp(
          child: AppButton.primary(
            text: 'Accessible Button',
            onPressed: () {},
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Accessible Button'),
        findsOneWidget,
      );
    });
  });
}
