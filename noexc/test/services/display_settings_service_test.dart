import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/display_settings_service.dart';

import '../test_helpers.dart';

void main() {
  setUp(() {
    setupQuietTesting();
  });

  test('instantDisplay toggles and notifies listeners', () async {
    final svc = DisplaySettingsService();
    var notified = 0;
    svc.addListener(() => notified++);

    expect(svc.instantDisplay, isFalse);
    svc.instantDisplay = true;
    expect(svc.instantDisplay, isTrue);
    expect(notified, 1);

    svc.instantDisplay = true; // no change
    expect(notified, 1); // should not notify again

    svc.instantDisplay = false;
    expect(svc.instantDisplay, isFalse);
    expect(notified, 2);
  });
}

