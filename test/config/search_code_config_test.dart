import 'package:stardust/src/config/code_config.dart';
import 'package:stardust/src/config/search_config.dart';
import 'package:test/test.dart';

void main() {
  group('SearchConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = SearchConfig.fromYaml(null);

      expect(config.enabled, isTrue);
      expect(config.provider, equals('pagefind'));
      expect(config.placeholder, equals('Search docs...'));
      expect(config.hotkey, equals('/'));
      expect(config.algolia, isNull);
    });

    test('fromYaml parses all fields', () {
      final config = SearchConfig.fromYaml({
        'enabled': false,
        'provider': 'algolia',
        'placeholder': 'Search...',
        'hotkey': 'k',
      });

      expect(config.enabled, isFalse);
      expect(config.provider, equals('algolia'));
      expect(config.placeholder, equals('Search...'));
      expect(config.hotkey, equals('k'));
    });

    test('fromYaml parses algolia config', () {
      final config = SearchConfig.fromYaml({
        'algolia': {
          'appId': 'APP123',
          'apiKey': 'KEY456',
          'indexName': 'docs',
        },
      });

      expect(config.algolia, isNotNull);
      expect(config.algolia!.appId, equals('APP123'));
      expect(config.algolia!.apiKey, equals('KEY456'));
      expect(config.algolia!.indexName, equals('docs'));
    });
  });

  group('AlgoliaConfig', () {
    test('fromYaml parses all fields', () {
      final config = AlgoliaConfig.fromYaml({
        'appId': 'myapp',
        'apiKey': 'mykey',
        'indexName': 'myindex',
      });

      expect(config.appId, equals('myapp'));
      expect(config.apiKey, equals('mykey'));
      expect(config.indexName, equals('myindex'));
    });
  });

  group('CodeConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = CodeConfig.fromYaml(null);

      expect(config.lineNumbers, isFalse);
      expect(config.copyButton, isTrue);
      expect(config.wrapLongLines, isFalse);
      expect(config.defaultLanguage, equals('plaintext'));
      expect(config.aliases, isEmpty);
    });

    test('fromYaml parses all fields', () {
      final config = CodeConfig.fromYaml({
        'lineNumbers': true,
        'copyButton': false,
        'wrapLongLines': true,
        'defaultLanguage': 'javascript',
        'aliases': {'js': 'javascript'},
      });

      expect(config.lineNumbers, isTrue);
      expect(config.copyButton, isFalse);
      expect(config.wrapLongLines, isTrue);
      expect(config.defaultLanguage, equals('javascript'));
      expect(config.aliases['js'], equals('javascript'));
    });

    test('fromYaml parses theme as map', () {
      final config = CodeConfig.fromYaml({
        'theme': {
          'light': 'one-light',
          'dark': 'one-dark',
        },
      });

      expect(config.theme.light, equals('one-light'));
      expect(config.theme.dark, equals('one-dark'));
    });

    test('fromYaml parses theme as string', () {
      final config = CodeConfig.fromYaml({
        'theme': 'monokai',
      });

      expect(config.theme.light, equals('monokai'));
      expect(config.theme.dark, equals('monokai'));
    });
  });

  group('CodeThemeConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = CodeThemeConfig.fromYaml(null);

      expect(config.light, equals('github-light'));
      expect(config.dark, equals('github-dark'));
    });

    test('fromYaml with string sets both themes', () {
      final config = CodeThemeConfig.fromYaml('dracula');

      expect(config.light, equals('dracula'));
      expect(config.dark, equals('dracula'));
    });

    test('fromYaml with map sets individual themes', () {
      final config = CodeThemeConfig.fromYaml({
        'light': 'solarized-light',
        'dark': 'solarized-dark',
      });

      expect(config.light, equals('solarized-light'));
      expect(config.dark, equals('solarized-dark'));
    });
  });

  group('ComponentsConfig', () {
    test('default has standard callouts', () {
      const config = ComponentsConfig();

      expect(config.callouts.containsKey('info'), isTrue);
      expect(config.callouts.containsKey('warning'), isTrue);
      expect(config.callouts.containsKey('danger'), isTrue);
      expect(config.callouts.containsKey('tip'), isTrue);
      expect(config.callouts.containsKey('note'), isTrue);
    });

    test('fromYaml with null uses defaults', () {
      final config = ComponentsConfig.fromYaml(null);

      expect(config.callouts.containsKey('info'), isTrue);
    });

    test('fromYaml parses custom callouts', () {
      final config = ComponentsConfig.fromYaml({
        'callouts': {
          'custom': {
            'icon': '🔥',
            'color': '#ff0000',
          },
        },
      });

      expect(config.callouts.containsKey('custom'), isTrue);
      expect(config.callouts['custom']!.icon, equals('🔥'));
      expect(config.callouts['custom']!.color, equals('#ff0000'));
    });
  });

  group('CalloutConfig', () {
    test('fromYaml parses icon and color', () {
      final config = CalloutConfig.fromYaml({
        'icon': '⚡',
        'color': '#ffff00',
      });

      expect(config.icon, equals('⚡'));
      expect(config.color, equals('#ffff00'));
    });
  });
}
