import 'package:stardust/src/config/layout_config.dart';
import 'package:test/test.dart';

void main() {
  group('LogoConfig', () {
    test('fromYaml with string creates single logo', () {
      final config = LogoConfig.fromYaml('/logo.svg');

      expect(config.single, equals('/logo.svg'));
      expect(config.light, isNull);
      expect(config.dark, isNull);
    });

    test('fromYaml with map creates light/dark logos', () {
      final config = LogoConfig.fromYaml({
        'light': '/logo-light.svg',
        'dark': '/logo-dark.svg',
      });

      expect(config.light, equals('/logo-light.svg'));
      expect(config.dark, equals('/logo-dark.svg'));
      expect(config.single, isNull);
    });

    test('fromYaml with null returns empty config', () {
      final config = LogoConfig.fromYaml(null);

      expect(config.light, isNull);
      expect(config.dark, isNull);
      expect(config.single, isNull);
    });

    test('effectiveLight returns light when set', () {
      final config = LogoConfig.fromYaml({'light': '/light.svg'});

      expect(config.effectiveLight, equals('/light.svg'));
    });

    test('effectiveLight returns single as fallback', () {
      final config = LogoConfig.fromYaml('/single.svg');

      expect(config.effectiveLight, equals('/single.svg'));
    });

    test('effectiveDark returns dark when set', () {
      final config = LogoConfig.fromYaml({'dark': '/dark.svg'});

      expect(config.effectiveDark, equals('/dark.svg'));
    });

    test('effectiveDark returns single as fallback', () {
      final config = LogoConfig.fromYaml('/single.svg');

      expect(config.effectiveDark, equals('/single.svg'));
    });
  });

  group('ContentConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = ContentConfig.fromYaml(null);

      expect(config.dir, equals('docs/'));
      expect(config.index, equals('index.md'));
      expect(config.include, contains('**/*.md'));
      expect(config.exclude, isEmpty);
    });

    test('fromYaml parses all fields', () {
      final config = ContentConfig.fromYaml({
        'dir': 'content/',
        'index': 'home.md',
        'include': ['*.md'],
        'exclude': ['drafts/**'],
      });

      expect(config.dir, equals('content/'));
      expect(config.index, equals('home.md'));
      expect(config.include, equals(['*.md']));
      expect(config.exclude, equals(['drafts/**']));
    });
  });

  group('HeaderConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = HeaderConfig.fromYaml(null);

      expect(config.showName, isTrue);
      expect(config.showSearch, isTrue);
      expect(config.showThemeToggle, isTrue);
      expect(config.showSocial, isTrue);
      expect(config.announcement, isNull);
    });

    test('fromYaml parses boolean fields', () {
      final config = HeaderConfig.fromYaml({
        'showName': false,
        'showSearch': false,
        'showThemeToggle': false,
        'showSocial': false,
      });

      expect(config.showName, isFalse);
      expect(config.showSearch, isFalse);
      expect(config.showThemeToggle, isFalse);
      expect(config.showSocial, isFalse);
    });

    test('fromYaml parses announcement', () {
      final config = HeaderConfig.fromYaml({
        'announcement': {
          'text': 'New version available!',
          'link': '/changelog',
          'dismissible': false,
          'style': 'warning',
        },
      });

      expect(config.announcement, isNotNull);
      expect(config.announcement!.text, equals('New version available!'));
      expect(config.announcement!.link, equals('/changelog'));
      expect(config.announcement!.dismissible, isFalse);
      expect(config.announcement!.style, equals('warning'));
    });
  });

  group('AnnouncementConfig', () {
    test('fromYaml parses all fields', () {
      final config = AnnouncementConfig.fromYaml({
        'text': 'Announcement text',
        'link': 'https://example.com',
        'dismissible': true,
        'style': 'info',
      });

      expect(config.text, equals('Announcement text'));
      expect(config.link, equals('https://example.com'));
      expect(config.dismissible, isTrue);
      expect(config.style, equals('info'));
    });

    test('fromYaml uses defaults for optional fields', () {
      final config = AnnouncementConfig.fromYaml({
        'text': 'Required text',
      });

      expect(config.text, equals('Required text'));
      expect(config.link, isNull);
      expect(config.dismissible, isTrue);
      expect(config.style, equals('info'));
    });
  });

  group('FooterConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = FooterConfig.fromYaml(null);

      expect(config.copyright, isNull);
      expect(config.links, isEmpty);
    });

    test('fromYaml parses copyright', () {
      final config = FooterConfig.fromYaml({
        'copyright': '2024 My Company',
      });

      expect(config.copyright, equals('2024 My Company'));
    });

    test('fromYaml parses links', () {
      final config = FooterConfig.fromYaml({
        'links': [
          {
            'group': 'Resources',
            'items': [
              {'label': 'Docs', 'href': '/docs'},
              {'label': 'API', 'href': '/api'},
            ],
          },
        ],
      });

      expect(config.links.length, equals(1));
      expect(config.links[0].group, equals('Resources'));
      expect(config.links[0].items.length, equals(2));
    });
  });

  group('FooterLinkGroup', () {
    test('fromYaml parses group with items', () {
      final group = FooterLinkGroup.fromYaml({
        'group': 'Company',
        'items': [
          {'label': 'About', 'href': '/about'},
        ],
      });

      expect(group.group, equals('Company'));
      expect(group.items.length, equals(1));
      expect(group.items[0].label, equals('About'));
    });

    test('fromYaml handles empty items', () {
      final group = FooterLinkGroup.fromYaml({
        'group': 'Empty',
      });

      expect(group.group, equals('Empty'));
      expect(group.items, isEmpty);
    });
  });

  group('FooterLink', () {
    test('fromYaml parses label and href', () {
      final link = FooterLink.fromYaml({
        'label': 'Contact',
        'href': '/contact',
      });

      expect(link.label, equals('Contact'));
      expect(link.href, equals('/contact'));
    });
  });
}
