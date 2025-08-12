import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/services/service_locator.dart';
import 'package:noexc/widgets/chat_screen/rive_overlay_host.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    setupTestingWithMocks();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  testWidgets('Zone 4 mid-ground overlay shows, updates, and hides', (tester) async {
    await ServiceLocator.instance.initialize();

    final completer = Completer<File?>(); // Never completes to avoid native Rive
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              RiveOverlayHost(
                service: ServiceLocator.instance.riveOverlayService,
                zone: 4,
                fileLoader: (_) => completer.future,
              ),
            ],
          ),
        ),
      ),
    );

    // Initially not active
    expect(find.byKey(const ValueKey('rive_overlay_zone_4_active')), findsNothing);

    // Show overlay (no auto-hide)
    final svc = ServiceLocator.instance.riveOverlayService;
    svc.show(
      asset: 'assets/animations/intro_logo_animated.riv',
      zone: 4,
      align: Alignment.center,
    );

    await tester.pump();
    expect(find.byKey(const ValueKey('rive_overlay_zone_4_active')), findsOneWidget);

    // Update bindings (no crash)
    svc.update(zone: 4, bindings: const {'dummy': 1.0});
    await tester.pump();

    // Hide overlay
    svc.hide(zone: 4);
    await tester.pump();
    expect(find.byKey(const ValueKey('rive_overlay_zone_4_active')), findsNothing);
  });
}

