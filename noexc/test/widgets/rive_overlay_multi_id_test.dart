import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/widgets/chat_screen/rive_overlay_host.dart';
import 'package:noexc/services/service_locator.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    setupTestingWithMocks();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  testWidgets('Multiple overlays can run concurrently in one zone using ids', (tester) async {
    await ServiceLocator.instance.initialize();

    final completer = Completer<File?>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            RiveOverlayHost(
              service: ServiceLocator.instance.riveOverlayService,
              zone: 2,
              fileLoader: (_) => completer.future, // avoid native
            ),
          ]),
        ),
      ),
    );

    final svc = ServiceLocator.instance.riveOverlayService;

    // Show two overlays with different ids
    svc.show(asset: 'assets/animations/confetti.riv', zone: 2, id: 'confetti', zIndex: 1);
    svc.show(asset: 'assets/animations/badge.riv', zone: 2, id: 'badge', zIndex: 2);

    await tester.pump();

    // Both instances are mounted
    expect(find.byKey(const ValueKey('rive_overlay_zone_2_active')), findsOneWidget);
    expect(find.byKey(const ValueKey('rive_overlay_instance_confetti')), findsOneWidget);
    expect(find.byKey(const ValueKey('rive_overlay_instance_badge')), findsOneWidget);
  });
}

