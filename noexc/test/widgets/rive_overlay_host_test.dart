import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rive/rive.dart';

import 'dart:async';
import 'package:noexc/widgets/chat_screen/rive_overlay_host.dart';
import 'package:noexc/services/service_locator.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    // Ensure bindings and platform mocks
    setupTestingWithMocks();
    SharedPreferences.setMockInitialValues({});
    // Do NOT call RiveNative.init() in tests; avoid native loading
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  testWidgets('Overlay host shows and auto-hides Rive overlay', (tester) async {
    // Initialize services
    await ServiceLocator.instance.initialize();

    // Use a RiveOverlayHost directly with a loader that never completes
    // to keep the overlay in loading state (no native calls).
    final completer = Completer<File?>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              RiveOverlayHost(
                service: ServiceLocator.instance.riveOverlayService,
                zone: 2,
                fileLoader: (_) => completer.future,
              ),
            ],
          ),
        ),
      ),
    );

    // No initial loading to settle; host is idle until show()

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
    // Allow AnimatedSwitcher to complete its transition
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('rive_overlay_zone_2_active')), findsNothing);
  });
}
