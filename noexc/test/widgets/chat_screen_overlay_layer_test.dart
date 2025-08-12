import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/widgets/chat_screen.dart';
import 'package:noexc/services/service_locator.dart';

import '../test_helpers.dart';

void main() {
  setUp(() async {
    setupTestingWithMocks();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  testWidgets('ChatScreen mounts overlay layers for zones 3, 4, and 2', (tester) async {
    await ServiceLocator.instance.initialize();

    await tester.pumpWidget(
      const MaterialApp(
        home: ChatScreen(),
      ),
    );

    // Let initial state settle
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('rive_overlay_zone_3')), findsOneWidget);
    expect(find.byKey(const ValueKey('rive_overlay_zone_4')), findsOneWidget);
    expect(find.byKey(const ValueKey('rive_overlay_zone_2')), findsOneWidget);
  });
}

