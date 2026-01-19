import 'package:stardust/src/config/config.dart';
import 'package:test/test.dart';

void main() {
  group('ThemeConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = ThemeConfig.fromYaml(null);

      expect(config.colors.primary, equals('#6366f1'));
      expect(config.darkMode.enabled, isTrue);
      expect(config.darkMode.defaultMode, equals('system'));
      expect(config.fonts.sans, equals('Inter'));
      expect(config.fonts.mono, equals('JetBrains Mono'));
      expect(config.radius, equals('8px'));
    });

    test('fromYaml parses all fields', () {
      final config = ThemeConfig.fromYaml({
        'colors': {
          'primary': '#ff0000',
          'secondary': '#00ff00',
          'accent': '#0000ff',
        },
        'darkMode': {
          'enabled': false,
          'default': 'light',
        },
        'fonts': {
          'sans': 'Roboto',
          'mono': 'Fira Code',
        },
        'radius': '12px',
      });

      expect(config.colors.primary, equals('#ff0000'));
      expect(config.colors.secondary, equals('#00ff00'));
      expect(config.colors.accent, equals('#0000ff'));
      expect(config.darkMode.enabled, isFalse);
      expect(config.darkMode.defaultMode, equals('light'));
      expect(config.fonts.sans, equals('Roboto'));
      expect(config.fonts.mono, equals('Fira Code'));
      expect(config.radius, equals('12px'));
    });

    test('fromYaml parses background colors', () {
      final config = ThemeConfig.fromYaml({
        'colors': {
          'background': {
            'light': '#f0f0f0',
            'dark': '#1a1a1a',
          },
        },
      });

      expect(config.colors.background, isNotNull);
      expect(config.colors.background!.light, equals('#f0f0f0'));
      expect(config.colors.background!.dark, equals('#1a1a1a'));
    });

    test('fromYaml parses text colors', () {
      final config = ThemeConfig.fromYaml({
        'colors': {
          'text': {
            'light': '#333333',
            'dark': '#cccccc',
          },
        },
      });

      expect(config.colors.text, isNotNull);
      expect(config.colors.text!.light, equals('#333333'));
      expect(config.colors.text!.dark, equals('#cccccc'));
    });

    test('fromYaml parses custom CSS', () {
      final config = ThemeConfig.fromYaml({
        'custom': {
          'css': ':root { --custom: value; }',
        },
      });

      expect(config.custom, isNotNull);
      expect(config.custom!.css, equals(':root { --custom: value; }'));
    });
  });

  group('SocialConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = SocialConfig.fromYaml(null);

      expect(config.github, isNull);
      expect(config.twitter, isNull);
      expect(config.discord, isNull);
    });

    test('fromYaml parses all social links', () {
      final config = SocialConfig.fromYaml({
        'github': 'https://github.com/test',
        'twitter': 'https://twitter.com/test',
        'discord': 'https://discord.gg/test',
        'linkedin': 'https://linkedin.com/in/test',
        'youtube': 'https://youtube.com/c/test',
        'slack': 'https://slack.com/test',
      });

      expect(config.github, equals('https://github.com/test'));
      expect(config.twitter, equals('https://twitter.com/test'));
      expect(config.discord, equals('https://discord.gg/test'));
      expect(config.linkedin, equals('https://linkedin.com/in/test'));
      expect(config.youtube, equals('https://youtube.com/c/test'));
      expect(config.slack, equals('https://slack.com/test'));
    });
  });

  group('DevConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = DevConfig.fromYaml(null);

      expect(config.port, equals(4000));
      expect(config.host, equals('localhost'));
    });

    test('fromYaml parses port and host', () {
      final config = DevConfig.fromYaml({
        'port': 8080,
        'host': '0.0.0.0',
      });

      expect(config.port, equals(8080));
      expect(config.host, equals('0.0.0.0'));
    });
  });

  group('BuildConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = BuildConfig.fromYaml(null);

      expect(config.sitemap.enabled, isTrue);
      expect(config.robots.enabled, isTrue);
    });

    test('fromYaml parses sitemap config', () {
      final config = BuildConfig.fromYaml({
        'sitemap': {
          'enabled': true,
          'changefreq': 'daily',
          'priority': 0.8,
        },
      });

      expect(config.sitemap.enabled, isTrue);
      expect(config.sitemap.changefreq, equals('daily'));
      expect(config.sitemap.priority, equals(0.8));
    });

    test('fromYaml parses robots config', () {
      final config = BuildConfig.fromYaml({
        'robots': {
          'enabled': true,
          'allow': ['/'],
          'disallow': ['/private'],
        },
      });

      expect(config.robots.enabled, isTrue);
      expect(config.robots.allow, contains('/'));
      expect(config.robots.disallow, contains('/private'));
    });

    test('fromYaml parses assets config', () {
      final config = BuildConfig.fromYaml({
        'assets': {
          'dir': 'static',
        },
      });

      expect(config.assets.dir, equals('static'));
    });

    test('fromYaml parses llms config', () {
      final config = BuildConfig.fromYaml({
        'llms': {
          'enabled': true,
        },
      });

      expect(config.llms.enabled, isTrue);
    });
  });

  group('IntegrationsConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = IntegrationsConfig.fromYaml(null);

      expect(config.editLink, isNull);
      expect(config.analytics, isNull);
    });

    test('fromYaml parses editLink', () {
      final config = IntegrationsConfig.fromYaml({
        'editLink': {
          'enabled': true,
          'repo': 'https://github.com/user/repo',
          'branch': 'develop',
          'path': 'content/',
          'text': 'Edit on GitHub',
        },
      });

      expect(config.editLink, isNotNull);
      expect(config.editLink!.enabled, isTrue);
      expect(config.editLink!.repo, equals('https://github.com/user/repo'));
      expect(config.editLink!.branch, equals('develop'));
      expect(config.editLink!.path, equals('content/'));
      expect(config.editLink!.text, equals('Edit on GitHub'));
    });

    test('fromYaml parses lastUpdated', () {
      final config = IntegrationsConfig.fromYaml({
        'lastUpdated': {
          'enabled': true,
          'format': 'yyyy-MM-dd',
          'text': 'Updated on',
        },
      });

      expect(config.lastUpdated, isNotNull);
      expect(config.lastUpdated!.enabled, isTrue);
      expect(config.lastUpdated!.format, equals('yyyy-MM-dd'));
      expect(config.lastUpdated!.text, equals('Updated on'));
    });

    test('fromYaml parses analytics with posthog', () {
      final config = IntegrationsConfig.fromYaml({
        'analytics': {
          'google': 'GA-123456',
          'plausible': 'example.com',
          'posthog': {
            'key': 'ph-key',
            'host': 'https://app.posthog.com',
          },
        },
      });

      expect(config.analytics, isNotNull);
      expect(config.analytics!.google, equals('GA-123456'));
      expect(config.analytics!.plausible, equals('example.com'));
      expect(config.analytics!.posthog, isNotNull);
      expect(config.analytics!.posthog!.key, equals('ph-key'));
      expect(config.analytics!.posthog!.host, equals('https://app.posthog.com'));
    });

    test('fromYaml parses comments with giscus', () {
      final config = IntegrationsConfig.fromYaml({
        'comments': {
          'provider': 'giscus',
          'giscus': {
            'repo': 'user/repo',
            'repoId': 'R_123',
            'category': 'General',
            'categoryId': 'C_123',
          },
        },
      });

      expect(config.comments, isNotNull);
      expect(config.comments!.provider, equals('giscus'));
      expect(config.comments!.giscus, isNotNull);
      expect(config.comments!.giscus!.repo, equals('user/repo'));
      expect(config.comments!.giscus!.repoId, equals('R_123'));
    });

    test('fromYaml parses comments with disqus', () {
      final config = IntegrationsConfig.fromYaml({
        'comments': {
          'provider': 'disqus',
          'disqus': {
            'shortname': 'my-site',
          },
        },
      });

      expect(config.comments, isNotNull);
      expect(config.comments!.provider, equals('disqus'));
      expect(config.comments!.disqus, isNotNull);
      expect(config.comments!.disqus!.shortname, equals('my-site'));
    });
  });

  group('SearchConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = SearchConfig.fromYaml(null);

      expect(config.enabled, isTrue);
      expect(config.provider, equals('pagefind'));
    });

    test('fromYaml parses all fields', () {
      final config = SearchConfig.fromYaml({
        'enabled': false,
        'provider': 'algolia',
        'placeholder': 'Type to search...',
      });

      expect(config.enabled, isFalse);
      expect(config.provider, equals('algolia'));
      expect(config.placeholder, equals('Type to search...'));
    });
  });

  group('SeoConfig', () {
    test('fromYaml with null uses defaults', () {
      final config = SeoConfig.fromYaml(null);

      expect(config.titleTemplate, equals('%s'));
    });

    test('fromYaml parses all fields', () {
      final config = SeoConfig.fromYaml({
        'titleTemplate': '%s | My Site',
        'ogImage': '/og-image.png',
        'twitterCard': 'summary_large_image',
        'twitterHandle': '@myhandle',
        'structuredData': false,
      });

      expect(config.titleTemplate, equals('%s | My Site'));
      expect(config.ogImage, equals('/og-image.png'));
      expect(config.twitterCard, equals('summary_large_image'));
      expect(config.twitterHandle, equals('@myhandle'));
      expect(config.structuredData, isFalse);
    });
  });

  group('LogoConfig', () {
    test('fromYaml with string creates single logo', () {
      final config = LogoConfig.fromYaml('/logo.svg');

      expect(config.single, equals('/logo.svg'));
      expect(config.effectiveLight, equals('/logo.svg'));
      expect(config.effectiveDark, equals('/logo.svg'));
    });

    test('fromYaml with map creates light/dark logos', () {
      final config = LogoConfig.fromYaml({
        'light': '/logo-light.svg',
        'dark': '/logo-dark.svg',
      });

      expect(config.light, equals('/logo-light.svg'));
      expect(config.dark, equals('/logo-dark.svg'));
      expect(config.effectiveLight, equals('/logo-light.svg'));
      expect(config.effectiveDark, equals('/logo-dark.svg'));
    });
  });

  group('VersionsConfig', () {
    test('fromYaml parses versions', () {
      final config = VersionsConfig.fromYaml({
        'enabled': true,
        'current': 'v2.0',
        'dropdown': true,
        'list': [
          {'version': 'v2.0', 'path': '/v2'},
          {'version': 'v1.0', 'path': '/v1', 'label': 'Version 1'},
        ],
      });

      expect(config.enabled, isTrue);
      expect(config.current, equals('v2.0'));
      expect(config.list.length, equals(2));
      expect(config.list[0].version, equals('v2.0'));
      expect(config.list[0].path, equals('/v2'));
      expect(config.list[1].label, equals('Version 1'));
    });
  });

  group('I18nConfig', () {
    test('fromYaml parses i18n settings', () {
      final config = I18nConfig.fromYaml({
        'defaultLocale': 'en',
        'locales': [
          {'code': 'en', 'label': 'English'},
          {'code': 'es', 'label': 'Spanish'},
        ],
      });

      expect(config.defaultLocale, equals('en'));
      expect(config.locales.length, equals(2));
      expect(config.locales[0].code, equals('en'));
      expect(config.locales[1].label, equals('Spanish'));
    });
  });
}
