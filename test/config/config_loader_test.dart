import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/config/config_loader.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigLoader', () {
    group('parse', () {
      test('parses minimal config with only name', () {
        final config = ConfigLoader.parse({'name': 'Test'});

        expect(config.name, equals('Test'));
      });

      test('throws ConfigException when name is missing', () {
        expect(
          () => ConfigLoader.parse({}),
          throwsA(isA<ConfigException>()),
        );
      });

      test('throws ConfigException when name is empty', () {
        expect(
          () => ConfigLoader.parse({'name': ''}),
          throwsA(isA<ConfigException>()),
        );
      });

      test('parses description', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'description': 'A test site',
        });

        expect(config.description, equals('A test site'));
      });

      test('parses tagline', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'tagline': 'Build better docs',
        });

        expect(config.tagline, equals('Build better docs'));
      });

      test('parses url', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'url': 'https://example.com',
        });

        expect(config.url, equals('https://example.com'));
      });

      test('parses favicon', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'favicon': '/favicon.ico',
        });

        expect(config.favicon, equals('/favicon.ico'));
      });

      test('parses logo config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'logo': {
            'light': '/logo-light.svg',
            'dark': '/logo-dark.svg',
          },
        });

        expect(config.logo, isNotNull);
        expect(config.logo!.light, equals('/logo-light.svg'));
        expect(config.logo!.dark, equals('/logo-dark.svg'));
      });

      test('parses content config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'content': {
            'dir': 'docs',
            'include': ['**/*.md'],
            'exclude': ['**/draft/*'],
          },
        });

        expect(config.content.dir, equals('docs'));
        expect(config.content.include, contains('**/*.md'));
        expect(config.content.exclude, contains('**/draft/*'));
      });

      test('parses navigation items', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'nav': [
            {'label': 'Home', 'href': '/'},
            {'label': 'Docs', 'href': '/docs'},
          ],
        });

        expect(config.nav.length, equals(2));
        expect(config.nav[0].label, equals('Home'));
        expect(config.nav[0].href, equals('/'));
        expect(config.nav[1].label, equals('Docs'));
      });

      test('parses sidebar groups', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'sidebar': [
            {
              'group': 'Getting Started',
              'pages': [
                {'slug': 'intro'},
                {'slug': 'setup', 'label': 'Setup Guide'},
              ],
            },
          ],
        });

        expect(config.sidebar.length, equals(1));
        expect(config.sidebar[0].group, equals('Getting Started'));
        expect(config.sidebar[0].pages.length, equals(2));
        expect(config.sidebar[0].pages[0].slug, equals('intro'));
        expect(config.sidebar[0].pages[1].label, equals('Setup Guide'));
      });

      test('parses toc config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'toc': {
            'minDepth': 2,
            'maxDepth': 4,
          },
        });

        expect(config.toc.minDepth, equals(2));
        expect(config.toc.maxDepth, equals(4));
      });

      test('parses theme config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'theme': {
            'colors': {'primary': '#3b82f6'},
            'darkMode': {
              'enabled': true,
              'default': 'system',
            },
          },
        });

        expect(config.theme.colors.primary, equals('#3b82f6'));
        expect(config.theme.darkMode.enabled, isTrue);
        expect(config.theme.darkMode.defaultMode, equals('system'));
      });

      test('parses code config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'code': {
            'lineNumbers': true,
            'copyButton': true,
            'theme': {'light': 'github-light', 'dark': 'github-dark'},
          },
        });

        expect(config.code.lineNumbers, isTrue);
        expect(config.code.copyButton, isTrue);
        expect(config.code.theme.dark, equals('github-dark'));
      });

      test('parses search config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'search': {
            'enabled': true,
            'provider': 'pagefind',
          },
        });

        expect(config.search.enabled, isTrue);
        expect(config.search.provider, equals('pagefind'));
      });

      test('parses SEO config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'seo': {
            'titleTemplate': '%s | Test Site',
            'twitterCard': 'summary_large_image',
          },
        });

        expect(config.seo.titleTemplate, equals('%s | Test Site'));
        expect(config.seo.twitterCard, equals('summary_large_image'));
      });

      test('parses social config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'social': {
            'github': 'https://github.com/test',
            'twitter': 'https://twitter.com/test',
          },
        });

        expect(config.social.github, equals('https://github.com/test'));
        expect(config.social.twitter, equals('https://twitter.com/test'));
      });

      test('parses header config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'header': {
            'showName': true,
            'showSearch': true,
            'showThemeToggle': true,
          },
        });

        expect(config.header.showName, isTrue);
        expect(config.header.showSearch, isTrue);
        expect(config.header.showThemeToggle, isTrue);
      });

      test('parses footer config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'footer': {
            'copyright': '2024 Test',
          },
        });

        expect(config.footer.copyright, equals('2024 Test'));
      });

      test('parses build config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'build': {
            'sitemap': {'enabled': true},
            'robots': {'enabled': true},
          },
        });

        expect(config.build.sitemap.enabled, isTrue);
        expect(config.build.robots.enabled, isTrue);
      });

      test('parses integrations config', () {
        final config = ConfigLoader.parse({
          'name': 'Test',
          'integrations': {
            'analytics': {'google': 'GA-123'},
          },
        });

        expect(config.integrations.analytics, isNotNull);
        expect(config.integrations.analytics!.google, equals('GA-123'));
      });

      test('uses defaults for missing optional fields', () {
        final config = ConfigLoader.parse({'name': 'Test'});

        expect(config.description, isNull);
        expect(config.tagline, isNull);
        expect(config.url, isNull);
        expect(config.nav, isEmpty);
        expect(config.sidebar, isEmpty);
        expect(config.toc.minDepth, equals(2));
        expect(config.toc.maxDepth, equals(4));
        expect(config.code.copyButton, isTrue);
        expect(config.search.enabled, isTrue);
      });
    });
  });

  group('Config classes', () {
    group('ContentConfig', () {
      test('fromYaml with full config', () {
        final config = ContentConfig.fromYaml({
          'dir': 'docs',
          'include': ['**/*.md'],
          'exclude': ['drafts/**'],
        });

        expect(config.dir, equals('docs'));
        expect(config.include, contains('**/*.md'));
        expect(config.exclude, contains('drafts/**'));
      });

      test('fromYaml with null uses defaults', () {
        final config = ContentConfig.fromYaml(null);

        expect(config.dir, equals('docs/'));
        expect(config.include, contains('**/*.md'));
      });
    });

    group('TocConfig', () {
      test('fromYaml parses depths', () {
        final config = TocConfig.fromYaml({
          'minDepth': 1,
          'maxDepth': 6,
        });

        expect(config.minDepth, equals(1));
        expect(config.maxDepth, equals(6));
      });

      test('fromYaml with null uses defaults', () {
        final config = TocConfig.fromYaml(null);

        expect(config.minDepth, equals(2));
        expect(config.maxDepth, equals(4));
      });
    });

    group('CodeConfig', () {
      test('fromYaml parses all fields', () {
        final config = CodeConfig.fromYaml({
          'lineNumbers': true,
          'copyButton': false,
          'theme': {'light': 'one-light', 'dark': 'one-dark'},
        });

        expect(config.lineNumbers, isTrue);
        expect(config.copyButton, isFalse);
        expect(config.theme.dark, equals('one-dark'));
        expect(config.theme.light, equals('one-light'));
      });

      test('fromYaml parses theme as string', () {
        final config = CodeConfig.fromYaml({
          'theme': 'monokai',
        });

        // When theme is a string, both light and dark use same theme
        expect(config.theme.light, equals('monokai'));
        expect(config.theme.dark, equals('monokai'));
      });
    });

    group('SearchConfig', () {
      test('fromYaml parses fields', () {
        final config = SearchConfig.fromYaml({
          'enabled': false,
          'provider': 'algolia',
        });

        expect(config.enabled, isFalse);
        expect(config.provider, equals('algolia'));
      });
    });

    group('SeoConfig', () {
      test('fromYaml parses template', () {
        final config = SeoConfig.fromYaml({
          'titleTemplate': '%s - Docs',
        });

        expect(config.titleTemplate, equals('%s - Docs'));
      });
    });

    group('NavItem', () {
      test('fromYaml parses item', () {
        final item = NavItem.fromYaml({
          'label': 'Documentation',
          'href': '/docs',
        });

        expect(item.label, equals('Documentation'));
        expect(item.href, equals('/docs'));
      });
    });

    group('SidebarGroup', () {
      test('fromYaml parses group with pages', () {
        final group = SidebarGroup.fromYaml({
          'group': 'API',
          'pages': [
            {'slug': 'overview'},
            {'slug': 'auth', 'label': 'Authentication'},
          ],
        });

        expect(group.group, equals('API'));
        expect(group.pages.length, equals(2));
        expect(group.pages[0].slug, equals('overview'));
        expect(group.pages[1].label, equals('Authentication'));
      });
    });

    group('SidebarPage', () {
      test('fromYaml parses page with slug only', () {
        final page = SidebarPage.fromYaml({'slug': 'intro'});

        expect(page.slug, equals('intro'));
        expect(page.label, isNull);
      });

      test('fromYaml parses page with label', () {
        final page = SidebarPage.fromYaml({
          'slug': 'intro',
          'label': 'Introduction',
        });

        expect(page.slug, equals('intro'));
        expect(page.label, equals('Introduction'));
      });
    });
  });
}
