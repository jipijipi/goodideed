import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noexc/services/session_service.dart';
import 'package:noexc/services/user_data_service.dart';
import 'package:noexc/constants/storage_keys.dart';
import '../test_helpers.dart';

void main() {
  group('SessionService End State Management', () {
    late SessionService sessionService;
    late UserDataService userDataService;

    setUp(() async {
      setupQuietTesting();
      SharedPreferences.setMockInitialValues({});
      userDataService = UserDataService();
      sessionService = SessionService(userDataService);
    });

    tearDown(() async {
      await userDataService.clearAllData();
    });

    group('isAtEndState', () {
      test('should return false when no end state flag is set', () async {
        final result = await sessionService.isAtEndState();
        expect(result, false);
      });

      test('should return true when end state flag is set to true', () async {
        await userDataService.storeValue(StorageKeys.sessionIsAtEndState, true);
        
        final result = await sessionService.isAtEndState();
        expect(result, true);
      });

      test('should return false when end state flag is set to false', () async {
        await userDataService.storeValue(StorageKeys.sessionIsAtEndState, false);
        
        final result = await sessionService.isAtEndState();
        expect(result, false);
      });

      test('should handle null values gracefully', () async {
        // Explicitly store null to test edge case
        await userDataService.storeValue(StorageKeys.sessionIsAtEndState, null);
        
        final result = await sessionService.isAtEndState();
        expect(result, false);
      });
    });

    group('setEndState', () {
      test('should set end state flag to true', () async {
        await sessionService.setEndState(true);
        
        final stored = await userDataService.getValue<bool>(StorageKeys.sessionIsAtEndState);
        expect(stored, true);
      });

      test('should set end state flag to false', () async {
        await sessionService.setEndState(false);
        
        final stored = await userDataService.getValue<bool>(StorageKeys.sessionIsAtEndState);
        expect(stored, false);
      });

      test('should overwrite existing end state flag', () async {
        await userDataService.storeValue(StorageKeys.sessionIsAtEndState, true);
        
        await sessionService.setEndState(false);
        
        final result = await sessionService.isAtEndState();
        expect(result, false);
      });
    });

    group('clearEndState', () {
      test('should set end state flag to false', () async {
        await userDataService.storeValue(StorageKeys.sessionIsAtEndState, true);
        
        await sessionService.clearEndState();
        
        final result = await sessionService.isAtEndState();
        expect(result, false);
      });

      test('should work when no flag was previously set', () async {
        await sessionService.clearEndState();
        
        final result = await sessionService.isAtEndState();
        expect(result, false);
      });
    });

    group('integration with existing session methods', () {
      test('should not interfere with initializeSession', () async {
        await userDataService.storeValue(StorageKeys.sessionIsAtEndState, true);
        
        // This should not clear the end state flag
        await sessionService.initializeSession();
        
        final result = await sessionService.isAtEndState();
        expect(result, true);
      });
    });
  });
}