import 'package:stardust/src/config/config.dart';
import 'package:test/test.dart';

void main() {
  group('StardustConfig', () {
    group('withVersion', () {
      const base = StardustConfig(
        name: 'Docs',
        url: 'https://example.com',
        content: ContentConfig(dir: 'docs'),
        versions: VersionsConfig(enabled: true, current: '2.0'),
      );

      test('overrides content dir and base path, tags the active version', () {
        const entry = VersionEntry(version: '1.0', path: '/v1/');

        final v = base.withVersion(
          entry,
          source: 'versions/1.0',
          versionBasePath: '/v1',
          versionPages: {
            '1.0': {'/'},
          },
        );

        expect(v.content.dir, 'versions/1.0');
        expect(v.basePath, '/v1');
        expect(v.activeVersion, entry);
        expect(v.versionPages, {
          '1.0': {'/'},
        });
        expect(v.name, 'Docs', reason: 'unrelated fields carry through');
        expect(v.versions, base.versions);
      });

      test('a null base path builds at the site root', () {
        final v = base.withVersion(
          const VersionEntry(version: '2.0', path: '/'),
          source: 'docs',
          versionBasePath: null,
        );

        expect(v.basePath, '');
        expect(v.versionPages, isNull, reason: 'falls back to the existing index when none is passed');
      });
    });

    group('withLocale', () {
      const base = StardustConfig(
        name: 'Docs',
        content: ContentConfig(dir: 'docs', exclude: ['drafts/**']),
        i18n: I18nConfig(enabled: true, defaultLocale: 'en'),
      );
      const locale = LocaleConfig(code: 'es', label: 'Español', path: '/es/', dir: 'ltr');

      test('overrides content dir/base path and tags the active locale', () {
        final l = base.withLocale(
          locale,
          contentDir: '/tmp/merged',
          localeBasePath: '/es',
          untranslatedPaths: {'/guide'},
          excludeSubdirs: ['es/**'],
        );

        expect(l.content.dir, '/tmp/merged');
        expect(l.content.exclude, ['drafts/**', 'es/**'], reason: 'locale subdirs added to existing excludes');
        expect(l.basePath, '/es');
        expect(l.activeLocale, locale);
        expect(l.untranslatedPaths, {'/guide'});
        expect(l.lang, 'es', reason: 'lang follows the active locale');
      });

      test('the active locale drives lang and dir', () {
        const rtl = LocaleConfig(code: 'ar', label: 'العربية', path: '/ar/', dir: 'rtl');
        final l = base.withLocale(rtl, contentDir: 'docs', localeBasePath: '/ar');

        expect(l.lang, 'ar');
        expect(l.dir, 'rtl');
      });
    });

    group('i18nStrings', () {
      final i18n = I18nConfig.fromYaml({
        'defaultLocale': 'en',
        'strings': {
          'nav.next': 'Shared next',
          'toc.title': 'Shared contents',
          'code.copy': 'Shared copy',
        },
        'locales': [
          {
            'code': 'en',
            'label': 'English',
            'path': '/',
            'strings': {'nav.previous': 'Default previous'},
          },
          {
            'code': 'fr',
            'label': 'Français',
            'path': '/fr/',
            'strings': {
              'nav.next': 'Suivant',
              'search.placeholder': 'Rechercher',
            },
          },
        ],
      });

      test('uses the default locale strings when no locale is active', () {
        final config = StardustConfig(name: 'Docs', i18n: i18n);

        expect(config.i18nStrings.navPrevious, equals('Default previous'));
        expect(config.i18nStrings.navNext, equals('Shared next'));
        expect(config.i18nStrings.codeCopy, equals('Shared copy'));
      });

      test('uses active locale overrides with shared string fallbacks', () {
        final config = StardustConfig(name: 'Docs', i18n: i18n);
        final localized = config.withLocale(
          i18n.locales[1],
          contentDir: 'docs/fr',
          localeBasePath: '/fr',
        );

        expect(localized.i18nStrings.navNext, equals('Suivant'));
        expect(localized.i18nStrings.searchPlaceholder, equals('Rechercher'));
        expect(localized.i18nStrings.tocTitle, equals('Shared contents'));
        expect(localized.i18nStrings.codeCopy, equals('Shared copy'));
      });
    });

    group('pageInfo parsing', () {
      test('defaults everything off', () {
        const info = PageInfoConfig();
        expect([info.readingTime, info.lastUpdated, info.contributors, info.needsGit], everyElement(isFalse));
      });

      test('reads toggles and flags git need', () {
        final info = PageInfoConfig.fromYaml({'readingTime': true, 'lastUpdated': true});
        expect(info.readingTime, isTrue);
        expect(info.lastUpdated, isTrue);
        expect(info.contributors, isFalse);
        expect(info.needsGit, isTrue);
      });
    });

    group('theme v1 parsing', () {
      test('parses token overrides, keeping only safe names', () {
        final theme = ThemeConfig.fromYaml({
          'tokens': {'color-primary': '#f00', 'bad key!': 'x'},
          'tokensDark': {'color-border': '#111'},
        });

        expect(theme.tokens, {'color-primary': '#f00'});
        expect(theme.tokensDark, {'color-border': '#111'});
      });

      test('parses header/footer/sidebar slots', () {
        final theme = ThemeConfig.fromYaml({
          'slots': {'header': '<b>h</b>', 'footer': '<b>f</b>', 'sidebar': '<b>s</b>'},
        });

        expect(theme.slots.header, '<b>h</b>');
        expect(theme.slots.footer, '<b>f</b>');
        expect(theme.slots.sidebar, '<b>s</b>');
      });

      test('footer poweredBy defaults to true and reads false', () {
        expect(const FooterConfig().poweredBy, isTrue);
        expect(FooterConfig.fromYaml({'poweredBy': false}).poweredBy, isFalse);
      });
    });

    group('basePath', () {
      test('returns empty string when no URL or explicit basePath', () {
        const config = StardustConfig(name: 'Test');
        expect(config.basePath, equals(''));
      });

      test('extracts path from URL', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.github.io/my-docs',
        );
        expect(config.basePath, equals('/my-docs'));
      });

      test('extracts path from URL with trailing slash', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.github.io/my-docs/',
        );
        expect(config.basePath, equals('/my-docs'));
      });

      test('returns empty for root URL', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
        );
        expect(config.basePath, equals(''));
      });

      test('returns empty for URL with only slash path', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.com/',
        );
        expect(config.basePath, equals(''));
      });

      test('uses explicit basePath over URL', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.github.io/from-url',
          build: BuildConfig(basePath: '/explicit-path'),
        );
        expect(config.basePath, equals('/explicit-path'));
      });

      test('adds leading slash to explicit basePath if missing', () {
        const config = StardustConfig(
          name: 'Test',
          build: BuildConfig(basePath: 'no-slash'),
        );
        expect(config.basePath, equals('/no-slash'));
      });

      test('returns empty string in devMode', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.github.io/my-docs',
          devMode: true,
        );
        expect(config.basePath, equals(''));
      });
    });

    group('withDevMode', () {
      test('creates copy with devMode enabled', () {
        const config = StardustConfig(
          name: 'Test',
          description: 'Test description',
          url: 'https://example.github.io/my-docs',
        );

        final devConfig = config.withDevMode();

        expect(devConfig.devMode, isTrue);
        expect(devConfig.name, equals('Test'));
        expect(devConfig.description, equals('Test description'));
        expect(devConfig.url, equals('https://example.github.io/my-docs'));
        expect(devConfig.basePath, equals(''));
      });

      test('preserves all config fields', () {
        final config = StardustConfig(
          name: 'Test',
          tagline: 'A tagline',
          nav: const [NavItem(label: 'Home', href: '/')],
          sidebar: const [
            SidebarGroup(group: 'Guide', pages: [SidebarPage(slug: 'intro')])
          ],
          theme: ThemeConfig.fromYaml({'radius': '10px'}),
          search: const SearchConfig(placeholder: 'Search...'),
        );

        final devConfig = config.withDevMode();

        expect(devConfig.tagline, equals('A tagline'));
        expect(devConfig.nav.length, equals(1));
        expect(devConfig.sidebar.length, equals(1));
        expect(devConfig.theme.radius, equals('10px'));
        expect(devConfig.search.placeholder, equals('Search...'));
      });
    });
  });

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

    test('fromYaml parses basePath', () {
      final config = BuildConfig.fromYaml({
        'basePath': '/docs',
      });

      expect(config.basePath, equals('/docs'));
    });

    test('basePath defaults to null', () {
      final config = BuildConfig.fromYaml({});
      expect(config.basePath, isNull);
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
    });

    test('fromYaml parses all fields', () {
      final config = SearchConfig.fromYaml({
        'enabled': false,
        'placeholder': 'Type to search...',
      });

      expect(config.enabled, isFalse);
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
          {'code': 'en', 'label': 'English', 'path': '/en/'},
          {'code': 'es', 'label': 'Spanish', 'path': '/es/'},
        ],
      });

      expect(config.defaultLocale, equals('en'));
      expect(config.locales.length, equals(2));
      expect(config.locales[0].code, equals('en'));
      expect(config.locales[1].label, equals('Spanish'));
    });

    test('fromYaml parses locale strings with shared fallbacks', () {
      final config = I18nConfig.fromYaml({
        'defaultLocale': 'en',
        'strings': {
          'footer.poweredBy': 'Made with',
          'code.copy': 'Copy snippet',
        },
        'locales': [
          {'code': 'en', 'label': 'English', 'path': '/'},
          {
            'code': 'es',
            'label': 'Español',
            'path': '/es/',
            'strings': {'footer.poweredBy': 'Creado con'},
          },
        ],
      });

      expect(config.locales[0].strings, isNull);
      expect(config.locales[1].strings, isNotNull);
      expect(config.locales[1].strings!.footerPoweredBy, equals('Creado con'));
      expect(config.locales[1].strings!.codeCopy, equals('Copy snippet'));
    });
  });

  group('I18nStrings.fromYaml', () {
    test('empty yaml uses all defaults', () {
      const strings = I18nStrings();
      final parsed = I18nStrings.fromYaml(null);

      expect(parsed.searchOneResult, equals(strings.searchOneResult));
      expect(parsed.searchClear, equals(strings.searchClear));
    });

    test('overrides and defaults the untranslated notice', () {
      expect(I18nStrings.fromYaml({'locale.untranslated': 'Aún no traducido'}).localeUntranslated, 'Aún no traducido');
      expect(const I18nStrings().localeUntranslated, 'This page has not been translated yet.');
    });

    test('applies search string overrides', () {
      final strings = I18nStrings.fromYaml({
        'search.noResults': 'Rien pour "%s"',
        'search.oneResult': '1 résultat',
        'search.manyResults': '%s résultats',
        'search.searching': 'Recherche...',
        'search.clear': 'Effacer',
        'search.more': 'Charger plus',
        'search.unavailable': 'Indisponible',
      });

      expect(strings.searchNoResults, equals('Rien pour "%s"'));
      expect(strings.searchOneResult, equals('1 résultat'));
      expect(strings.searchManyResults, equals('%s résultats'));
      expect(strings.searchSearching, equals('Recherche...'));
      expect(strings.searchClear, equals('Effacer'));
      expect(strings.searchMore, equals('Charger plus'));
      expect(strings.searchUnavailable, equals('Indisponible'));
    });

    test('falls back to search defaults when a non-empty map omits them', () {
      final strings = I18nStrings.fromYaml({'nav.next': 'Suivant'});

      expect(strings.navNext, equals('Suivant'));
      expect(strings.searchOneResult, equals('1 result'));
      expect(strings.searchManyResults, equals('%s results'));
      expect(strings.searchClear, equals('Clear search'));
      expect(strings.searchMore, equals('Load more results'));
      expect(strings.searchUnavailable, equals('Search is unavailable'));
    });

    test('parses the search, toc, code, page, and dartdoc strings', () {
      final strings = I18nStrings.fromYaml({
        'search.placeholder': 'Find anything',
        'toc.title': 'In this article',
        'code.copy': 'Copy snippet',
        'code.copyLabel': 'Copy this code',
        'code.copied': 'Copied successfully',
        'code.copyFailed': 'Could not copy',
        'page.copyMarkdown': 'Copy Markdown',
        'dartdoc.api': 'Reference',
        'dartdoc.backToDocs': '← Documentation',
      });

      expect(strings.searchPlaceholder, equals('Find anything'));
      expect(strings.tocTitle, equals('In this article'));
      expect(strings.codeCopy, equals('Copy snippet'));
      expect(strings.codeCopyLabel, equals('Copy this code'));
      expect(strings.codeCopied, equals('Copied successfully'));
      expect(strings.codeCopyFailed, equals('Could not copy'));
      expect(strings.pageCopyMarkdown, equals('Copy Markdown'));
      expect(strings.dartdocApi, equals('Reference'));
      expect(strings.dartdocBackToDocs, equals('← Documentation'));
    });

    test('inherits omitted values from an explicit fallback', () {
      const fallback = I18nStrings(
        navNext: 'Shared next',
        searchPlaceholder: 'Shared search',
        codeCopy: 'Shared copy',
      );
      final strings = I18nStrings.fromYaml(
        {
          'nav.previous': 'Locale previous',
          'toc.title': 'Locale contents',
        },
        fallback: fallback,
      );

      expect(strings.navPrevious, equals('Locale previous'));
      expect(strings.navNext, equals('Shared next'));
      expect(strings.searchPlaceholder, equals('Shared search'));
      expect(strings.tocTitle, equals('Locale contents'));
      expect(strings.codeCopy, equals('Shared copy'));
    });

    test('new nullable legacy-setting overrides default to null', () {
      const strings = I18nStrings();

      expect(strings.searchPlaceholder, isNull);
      expect(strings.tocTitle, isNull);
    });

    test('new standalone UI strings have English defaults', () {
      const strings = I18nStrings();

      expect(strings.codeCopy, equals('Copy'));
      expect(strings.codeCopyLabel, equals('Copy code'));
      expect(strings.codeCopied, equals('Copied!'));
      expect(strings.codeCopyFailed, equals('Copy failed'));
      expect(strings.pageCopyMarkdown, equals('Copy page as Markdown'));
      expect(strings.dartdocApi, equals('API'));
      expect(strings.dartdocBackToDocs, equals('← Back to docs'));
    });
  });
}
