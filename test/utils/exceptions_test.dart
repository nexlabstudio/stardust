import 'package:stardust/src/utils/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('StardustException', () {
    test('ConfigException formats message correctly', () {
      const exception = ConfigException('Invalid config');
      expect(exception.toString(), equals('ConfigException: Invalid config'));
      expect(exception.message, equals('Invalid config'));
      expect(exception.cause, isNull);
    });

    test('ConfigException includes cause when provided', () {
      final cause = Exception('underlying error');
      final exception = ConfigException('Invalid config', cause);
      expect(exception.toString(), contains('Invalid config'));
      expect(exception.toString(), contains('caused by:'));
      expect(exception.cause, equals(cause));
    });

    test('GeneratorException formats correctly', () {
      const exception = GeneratorException('Generation failed');
      expect(exception.toString(), equals('GeneratorException: Generation failed'));
    });

    test('ContentException includes sourcePath when provided', () {
      const exception = ContentException(
        'Parse error',
        sourcePath: '/path/to/file.md',
      );
      expect(exception.toString(), contains('Parse error'));
      expect(exception.toString(), contains('/path/to/file.md'));
      expect(exception.sourcePath, equals('/path/to/file.md'));
    });

    test('ContentException includes both sourcePath and cause', () {
      final cause = Exception('yaml error');
      final exception = ContentException(
        'Parse error',
        sourcePath: '/path/to/file.md',
        cause: cause,
      );
      expect(exception.toString(), contains('Parse error'));
      expect(exception.toString(), contains('/path/to/file.md'));
      expect(exception.toString(), contains('caused by:'));
    });

    test('ContentException without sourcePath still formats correctly', () {
      const exception = ContentException('Parse error');
      expect(exception.toString(), equals('ContentException: Parse error'));
      expect(exception.sourcePath, isNull);
    });

    test('OpenApiException formats correctly', () {
      const exception = OpenApiException('Invalid OpenAPI spec');
      expect(exception.toString(), equals('OpenApiException: Invalid OpenAPI spec'));
    });

    test('PagefindException formats correctly', () {
      const exception = PagefindException('Pagefind not found');
      expect(exception.toString(), equals('PagefindException: Pagefind not found'));
    });
  });
}
