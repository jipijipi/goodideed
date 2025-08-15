import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/services/service_locator.dart';
import 'package:noexc/services/data_action_processor.dart';
import 'package:noexc/models/data_action.dart';
import 'package:noexc/constants/storage_keys.dart';

import '../test_helpers.dart';

void main() {
  setUp(() async {
    setupQuietTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  test('append/remove resolve templated values from session variables', () async {
    await ServiceLocator.instance.initialize();

    final userData = ServiceLocator.instance.userDataService;
    final session = ServiceLocator.instance.sessionService;
    final processor = DataActionProcessor(userData, sessionService: session);

    // Seed a session value
    await userData.storeValue(StorageKeys.sessionTimeOfDay, 9);

    // Append using a template
    await processor.processActions([
      DataAction(type: DataActionType.append, key: 'debug.hours', value: '{session.timeOfDay}')
    ]);

    final list1 = await userData.getValue<dynamic>('debug.hours');
    expect(list1, isA<List>());
    expect((list1 as List).first, 9);

    // Remove using shorthand path
    await processor.processActions([
      DataAction(type: DataActionType.remove, key: 'debug.hours', value: 'session.timeOfDay')
    ]);

    final list2 = await userData.getValue<dynamic>('debug.hours');
    expect((list2 as List).contains(9), isFalse);
  });
}

