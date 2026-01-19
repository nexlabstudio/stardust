import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Logger', () {
    test('calls onLog callback when log is called', () {
      final messages = <String>[];
      final logger = Logger(onLog: messages.add);

      logger.log('test message');

      expect(messages, ['test message']);
    });

    test('calls onError callback when error is called', () {
      final logs = <String>[];
      final errors = <String>[];
      final logger = Logger(onLog: logs.add, onError: errors.add);

      logger.error('error message');

      expect(logs, isEmpty);
      expect(errors, ['error message']);
    });

    test('falls back to onLog when onError is null', () {
      final messages = <String>[];
      final logger = Logger(onLog: messages.add);

      logger.error('error as log');

      expect(messages, ['error as log']);
    });

    test('does nothing when no callbacks are set', () {
      const logger = Logger();

      // Should not throw
      logger.log('test');
      logger.error('error');
    });

    test('handles multiple log calls', () {
      final messages = <String>[];
      final logger = Logger(onLog: messages.add);

      logger.log('first');
      logger.log('second');
      logger.log('third');

      expect(messages, ['first', 'second', 'third']);
    });

    test('separates log and error messages', () {
      final logs = <String>[];
      final errors = <String>[];
      final logger = Logger(onLog: logs.add, onError: errors.add);

      logger.log('info 1');
      logger.error('error 1');
      logger.log('info 2');
      logger.error('error 2');

      expect(logs, ['info 1', 'info 2']);
      expect(errors, ['error 1', 'error 2']);
    });

    test('const constructor works', () {
      const logger = Logger();

      // Should not throw
      logger.log('test');
      logger.error('test');
    });
  });
}
