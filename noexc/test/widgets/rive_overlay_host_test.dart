import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rive/rive.dart';

import 'package:noexc/widgets/chat_screen.dart';
import 'package:noexc/services/service_locator.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    // Ensure bindings and platform mocks
    setupTestingWithMocks();
    SharedPreferences.setMockInitialValues({});
    await RiveNative.init();
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  testWidgets('Overlay host shows and auto-hides Rive overlay', (tester) async {
    // Initialize services
    await ServiceLocator.instance.initialize();

    // Pump ChatScreen (which includes overlay host)
    await tester.pumpWidget(const MaterialApp(home: ChatScreen()));

    // Wait for initial loading to settle
    await tester.pumpAndSettle();

    // Initially, overlay should not be active
    expect(find.byKey(const ValueKey('rive_overlay_zone_2_active')), findsNothing);

    // Trigger an overlay via service
    final overlayService = ServiceLocator.instance.riveOverlayService;
    overlayService.show(
      asset: 'assets/animations/intro_logo_animated.riv',
      autoHideAfter: const Duration(milliseconds: 300),
      zone: 2,
      align: Alignment.center,
    );

    // Allow frame to build overlay
    await tester.pump();

    // Overlay should appear (even if loading Rive, the host becomes active)
    expect(find.byKey(const ValueKey('rive_overlay_zone_2_active')), findsOneWidget);

    // After autoHide duration + a small buffer, it should disappear
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('rive_overlay_zone_2_active')), findsNothing);
  });
}

