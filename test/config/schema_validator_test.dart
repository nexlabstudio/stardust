import 'dart:io';

import 'package:stardust/src/config/config_loader.dart';
import 'package:stardust/src/config/schema_validator.dart';
import 'package:stardust/src/config/stardust_schema.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaValidator', () {
    final validator = SchemaValidator();

    test('accepts a minimal valid config', () {
      expect(validator.validate({'name': 'Test'}), isEmpty);
    });

    test('reports wrong-typed section with its key path', () {
      final issues = validator.validate({'name': 'Test', 'theme': 'blue'});

      expect(issues, hasLength(1));
      expect(issues.single.isWarning, isFalse);
      expect(issues.single.path, equals('theme'));
      expect(issues.single.message, contains('expected a mapping'));
    });

    test('reports enum violation with full key path', () {
      final issues = validator.validate({
        'name': 'Test',
        'theme': {
          'darkMode': {'default': 'purple'},
        },
      });

      expect(issues.single.path, equals('theme.darkMode.default'));
      expect(issues.single.message, contains('light, dark, system'));
      expect(issues.single.message, contains('purple'));
    });

    test('reports wrong-typed leaf value', () {
      final issues = validator.validate({
        'name': 'Test',
        'search': {'enabled': 'yes'},
      });

      expect(issues.single.path, equals('search.enabled'));
      expect(issues.single.message, contains('true or false'));
    });

    test('flags unknown keys as warnings with a suggestion', () {
      final issues = validator.validate({'name': 'Test', 'serach': {}});

      expect(issues.single.isWarning, isTrue);
      expect(issues.single.path, equals('serach'));
      expect(issues.single.message, contains('did you mean "search"?'));
    });

    test('validates list items with indexed paths', () {
      final issues = validator.validate({
        'name': 'Test',
        'i18n': {
          'locales': [
            {'code': 'en', 'label': 'English', 'path': '/en/', 'dir': 'sideways'},
          ],
        },
      });

      expect(issues.single.path, equals('i18n.locales[0].dir'));
      expect(issues.single.message, contains('ltr, rtl'));
    });

    test('accepts both shapes of a oneOf value', () {
      expect(
          validator.validate({
            'name': 'T',
            'code': {'theme': 'github-dark'}
          }),
          isEmpty);
      expect(
        validator.validate({
          'name': 'T',
          'code': {
            'theme': {'light': 'a', 'dark': 'b'},
          },
        }),
        isEmpty,
      );
    });

    test('null values are treated as absent', () {
      expect(validator.validate({'name': 'Test', 'url': null}), isEmpty);
    });
  });

  group('ConfigLoader validation', () {
    test('throws ConfigException with key paths for invalid values', () {
      expect(
        () => ConfigLoader.parse({
          'name': 'Test',
          'theme': {
            'darkMode': {'default': 'purple'},
          },
        }),
        throwsA(isA<ConfigException>().having((e) => e.message, 'message', contains('theme.darkMode.default'))),
      );
    });

    test('warns on unknown keys without failing the build', () {
      final warnings = <String>[];
      final config = ConfigLoader.parse(
        {'name': 'Test', 'serach': {}},
        logger: Logger(onError: warnings.add),
      );

      expect(config.name, equals('Test'));
      expect(warnings.single, contains('did you mean "search"?'));
    });

    test('rejects defaultLocale missing from locales', () {
      expect(
        () => ConfigLoader.parse({
          'name': 'Test',
          'i18n': {
            'defaultLocale': 'fr',
            'locales': [
              {'code': 'en', 'label': 'English', 'path': '/en/'},
            ],
          },
        }),
        throwsA(isA<ConfigException>().having((e) => e.message, 'message', contains('defaultLocale'))),
      );
    });

    test('warns when versions.current matches no list entry', () {
      final warnings = <String>[];
      ConfigLoader.parse(
        {
          'name': 'Test',
          'versions': {
            'enabled': true,
            'current': '3.0',
            'list': [
              {'version': '2.0', 'path': '/'},
            ],
          },
        },
        logger: Logger(onError: warnings.add),
      );

      expect(warnings.single, contains('versions.current'));
    });

    test('wraps YAML syntax errors in ConfigException', () async {
      final tempDir = await Directory.systemTemp.createTemp('stardust_config_test');
      final file = File('${tempDir.path}/bad.yaml');
      await file.writeAsString('name: [unclosed');

      try {
        await expectLater(
          ConfigLoader.load(file.path),
          throwsA(isA<ConfigException>().having((e) => e.message, 'message', contains('Invalid YAML'))),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('wraps missing-file errors in ConfigException', () async {
      await expectLater(
        ConfigLoader.load('/nonexistent/stardust.yaml'),
        throwsA(isA<ConfigException>().having((e) => e.message, 'message', contains('Cannot read'))),
      );
    });
  });

  group('schema sync', () {
    test('embedded schema matches schema/stardust.json', () {
      final onDisk = File('schema/stardust.json').readAsStringSync().replaceAll('\r\n', '\n');

      expect(
        stardustSchemaJson.replaceAll('\r\n', '\n'),
        equals(onDisk),
        reason: 'schema/stardust.json changed — run `dart run tool/embed_schema.dart` to regenerate',
      );
    });
  });
}
