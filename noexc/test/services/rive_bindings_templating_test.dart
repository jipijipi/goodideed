import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/services/service_locator.dart';

import '../test_helpers.dart';

void main() {
  setUp(() async {
    setupTestingWithMocks();
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.reset();
    await ServiceLocator.instance.initialize();
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  test('TextTemplatingService resolves {user.streak} to numeric string', () async {
    final userData = ServiceLocator.instance.userDataService;
    await userData.storeValue('user.streak', 123);

    final templating = ServiceLocator.instance.templatingService;
    final result = await templating.processTemplate('{user.streak}');

    expect(result, '123');
    expect(double.tryParse(result), 123.0);
  });

  test('Templating supports multiple roots (session.*, task.*)', () async {
    final userData = ServiceLocator.instance.userDataService;
    await userData.storeValue('session.visitCount', 5);
    await userData.storeValue('task.statusScore', 42);

    final templating = ServiceLocator.instance.templatingService;
    final res1 = await templating.processTemplate('{session.visitCount}');
    final res2 = await templating.processTemplate('{task.statusScore}');

    expect(res1, '5');
    expect(res2, '42');
    expect(double.tryParse(res1), 5.0);
    expect(double.tryParse(res2), 42.0);
  });
}
