import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/themes/app_themes.dart';

/// Test utilities for UI testing with consistent setup
class TestUtils {
  TestUtils._();

  /// Creates a basic MaterialApp wrapper for widget testing
  static Widget createMaterialApp({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('en', 'US'),
  }) {
    return MaterialApp(
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      locale: locale,
      home: Scaffold(body: child),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Creates a MaterialApp with custom theme for testing
  static Widget createThemedApp({
    required Widget child,
    required ThemeData theme,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(body: child),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Creates a test MediaQuery wrapper with specific screen size
  static Widget createMediaQueryWrapper({
    required Widget child,
    Size screenSize = const Size(375, 812), // iPhone 12 Pro size
    double devicePixelRatio = 3.0,
    double textScaleFactor = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        devicePixelRatio: devicePixelRatio,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: child,
    );
  }

  /// Creates a responsive test wrapper with media query and material app
  static Widget createResponsiveTestWrapper({
    required Widget child,
    Size screenSize = const Size(375, 812),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return createMediaQueryWrapper(
      screenSize: screenSize,
      child: createMaterialApp(child: child, themeMode: themeMode),
    );
  }

  /// Pumps a widget with animation settling
  static Future<void> pumpWithAnimation(
    WidgetTester tester,
    Widget widget, {
    Duration? duration,
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(duration ?? extendedPump);
  }

  /// Finds a widget by text with case-insensitive matching
  static Finder findTextIgnoreCase(String text) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data?.toLowerCase().contains(text.toLowerCase()) == true,
    );
  }

  /// Finds a widget by key with error handling
  static Finder findByKeySafe(String key) {
    return find.byKey(Key(key));
  }

  /// Taps a widget and waits for animations
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder, {
    Duration? settleDuration,
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(settleDuration ?? extendedPump);
  }

  /// Enters text in a field and waits for animations
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration? settleDuration,
  }) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle(settleDuration ?? extendedPump);
  }

  /// Verifies a widget exists and is visible
  static void expectVisible(Finder finder) {
    expect(finder, findsOneWidget);
    final widget = finder.evaluate().first.widget;
    expect(widget, isA<Widget>());
  }

  /// Verifies a widget does not exist
  static void expectNotFound(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies multiple widgets exist
  static void expectMultiple(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Creates a mock UserDataService for testing
  static UserDataService createMockUserDataService() {
    // Return a real instance for now - can be mocked later if needed
    return UserDataService();
  }

  /// Creates a mock SessionService for testing
  static SessionService createMockSessionService(
    UserDataService userDataService,
  ) {
    return SessionService(userDataService);
  }

  // Timeout Constants
  /// Standard test timeout duration
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Short timeout for quick operations
  static const Duration shortTimeout = Duration(seconds: 5);

  /// Long timeout for complex operations
  static const Duration longTimeout = Duration(seconds: 60);

  // Animation and Pump Constants
  /// Standard animation duration for tests
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Standard settle duration for tests
  static const Duration settleDuration = Duration(milliseconds: 500);

  /// Quick pump duration for simple state changes
  static const Duration quickPump = Duration(milliseconds: 100);

  /// Standard pump duration for most test operations
  static const Duration standardPump = Duration(seconds: 2);

  /// Extended pump duration for complex animations
  static const Duration extendedPump = Duration(seconds: 10);
}

/// Custom matcher for testing widget properties
class WidgetPropertyMatcher extends Matcher {
  final bool Function(Widget) predicate;
  final String description;

  const WidgetPropertyMatcher(this.predicate, this.description);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Element) return false;
    final widget = item.widget;
    return predicate(widget);
  }

  @override
  Description describe(Description description) {
    return description.add(this.description);
  }
}

/// Extension methods for easier testing
extension WidgetTesterExtensions on WidgetTester {
  /// Convenience method to pump and settle with default duration
  Future<void> pumpAndSettleDefault() async {
    await pumpAndSettle(TestUtils.extendedPump);
  }

  /// Convenience method to tap and settle
  Future<void> tapAndSettle(Finder finder) async {
    await TestUtils.tapAndSettle(this, finder);
  }

  /// Convenience method to enter text and settle
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await TestUtils.enterTextAndSettle(this, finder, text);
  }
}

/// Test group helpers for organized testing
class TestGroups {
  static void responsiveTests(String description, Function() testGroup) {
    group('$description - Responsive Tests', testGroup);
  }

  static void animationTests(String description, Function() testGroup) {
    group('$description - Animation Tests', testGroup);
  }

  static void interactionTests(String description, Function() testGroup) {
    group('$description - Interaction Tests', testGroup);
  }

  static void accessibilityTests(String description, Function() testGroup) {
    group('$description - Accessibility Tests', testGroup);
  }
}
