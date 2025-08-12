import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
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

  testWidgets('Zone 3 background overlay shows, updates, and hides', (tester) async {
    await ServiceLocator.instance.initialize();

    final completer = Completer<File?>(); // never completes to avoid native Rive
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              // Background host (zone 3)
              RiveOverlayHost(
                service: ServiceLocator.instance.riveOverlayService,
                zone: 3,
                fileLoader: (_) => completer.future,
              ),
            ],
          ),
        ),
      ),
    );

    // Initially not active
    expect(find.byKey(const ValueKey('rive_overlay_zone_3_active')), findsNothing);

    // Show a persistent background overlay (no auto-hide)
    final svc = ServiceLocator.instance.riveOverlayService;
    svc.show(
      asset: 'assets/animations/test-spere.riv',
      zone: 3,
      align: Alignment.center,
      // Fit left default; test avoids native Rive by non-completing loader
      bindings: const {'posx': 100.0, 'posy': 200.0},
    );

    await tester.pump();
    expect(find.byKey(const ValueKey('rive_overlay_zone_3_active')), findsOneWidget);

    // Update bindings while active (should not crash even without a loaded file)
    svc.update(zone: 3, bindings: const {'posx': 150.0});
    await tester.pump();

    // Hide background overlay
    svc.hide(zone: 3);
    await tester.pump();
    expect(find.byKey(const ValueKey('rive_overlay_zone_3_active')), findsNothing);
  });
}
