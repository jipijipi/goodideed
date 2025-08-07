import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/user_data_service.dart';

void main() {
  group('Sample Test', () {
    late UserDataService userDataService;

    setUp(() async {
      userDataService = UserDataService();
    });

    test('should work', () async {
      expect(true, isTrue);
    });
  });
}