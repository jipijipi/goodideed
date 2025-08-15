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

  testWidgets('Queued overlay shows after explicit hide', (tester) async {
    await ServiceLocator.instance.initialize();

    final completer = Completer<File?>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            RiveOverlayHost(
              service: ServiceLocator.instance.riveOverlayService,
              zone: 4,
              fileLoader: (_) => completer.future, // never completes
            ),
          ]),
        ),
      ),
    );

    final svc = ServiceLocator.instance.riveOverlayService;

    // Show first overlay with id 'badge'
    svc.show(
      asset: 'assets/animations/badge.riv',
      zone: 4,
      id: 'badge',
      policy: 'replace',
    );
    await tester.pump();

    // Queue second overlay with same id; should not appear until first hides
    svc.show(
      asset: 'assets/animations/badge2.riv',
      zone: 4,
      id: 'badge',
      policy: 'queue',
    );
    await tester.pump();

    // First instance is present, second not yet
    expect(find.byKey(const ValueKey('rive_overlay_zone_4_active')), findsOneWidget);
    expect(find.byKey(const ValueKey('rive_overlay_instance_badge')), findsOneWidget);

    // Hide first (drains queue and shows next)
    svc.hide(zone: 4, id: 'badge');
    await tester.pump();

    // The host remains active and shows the next instance for same id
    expect(find.byKey(const ValueKey('rive_overlay_zone_4_active')), findsOneWidget);
    expect(find.byKey(const ValueKey('rive_overlay_instance_badge')), findsOneWidget);
  });
}

