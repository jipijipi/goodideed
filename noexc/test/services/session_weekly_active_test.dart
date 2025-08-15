import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/constants/storage_keys.dart';

import '../test_helpers.dart';

void main() {
  setUp(() async {
    setupQuietTesting();
    SharedPreferences.setMockInitialValues({});
  });

  test('maps task.activeDays to session.<day>_active flags', () async {
    final userData = UserDataService();
    final session = SessionService(userData);

    // Active on Mon, Wed, Fri (1,3,5)
    await userData.storeValue(StorageKeys.taskActiveDays, [1, 3, 5]);

    await session.recalculateWeeklyActiveDays();

    expect(await userData.getValue<int>(StorageKeys.sessionMonActive), 1);
    expect(await userData.getValue<int>(StorageKeys.sessionTueActive), 0);
    expect(await userData.getValue<int>(StorageKeys.sessionWedActive), 1);
    expect(await userData.getValue<int>(StorageKeys.sessionThuActive), 0);
    expect(await userData.getValue<int>(StorageKeys.sessionFriActive), 1);
    expect(await userData.getValue<int>(StorageKeys.sessionSatActive), 0);
    expect(await userData.getValue<int>(StorageKeys.sessionSunActive), 0);
  });
}

