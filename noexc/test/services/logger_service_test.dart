import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/logger_service.dart';

void main() {
  group('LoggerService', () {
    late LoggerService logger;

    setUp(() {
      logger = LoggerService.instance;
      // Reset to defaults for each test
      logger.configure(
        minLevel: LogLevel.debug,
        enabledComponents: null,
        showTimestamps: false,
      );
    });

    test('should be a singleton', () {
      final instance1 = LoggerService.instance;
      final instance2 = LoggerService.instance;
      expect(instance1, same(instance2));
    });

    test('should configure log levels correctly', () {
      logger.configure(minLevel: LogLevel.error);
      final config = logger.getConfiguration();
      expect(config['minLevel'], 'error');
    });

    test('should configure component filtering', () {
      logger.configure(enabledComponents: {LogComponent.chatService});
      final config = logger.getConfiguration();
      expect(config['enabledComponents'], ['chatService']);
      expect(config['allComponentsEnabled'], false);
    });

    test('should enable all components when set is empty', () {
      logger.enableAllComponents();
      final config = logger.getConfiguration();
      expect(config['allComponentsEnabled'], true);
    });

    test('should provide convenience methods for common components', () {
      // These should not throw exceptions
      expect(() => logger.route('test message'), returnsNormally);
      expect(() => logger.condition('test condition'), returnsNormally);
      expect(() => logger.scenario('test scenario'), returnsNormally);
      expect(() => logger.semantic('test semantic'), returnsNormally);
    });

    test('should handle different log levels', () {
      // These should not throw exceptions
      expect(() => logger.debug('debug message'), returnsNormally);
      expect(() => logger.info('info message'), returnsNormally);
      expect(() => logger.warning('warning message'), returnsNormally);
      expect(() => logger.error('error message'), returnsNormally);
      expect(() => logger.critical('critical message'), returnsNormally);
    });

    test('should configure timestamps', () {
      logger.configure(showTimestamps: true);
      final config = logger.getConfiguration();
      expect(config['showTimestamps'], true);
    });
  });
}