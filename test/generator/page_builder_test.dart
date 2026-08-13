import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/content/markdown_parser.dart';
import 'package:stardust/src/generator/page_builder.dart';
import 'package:stardust/src/generator/page_info.dart';
import 'package:stardust/src/models/page.dart';
import 'package:test/test.dart';

void main() {
  group('PageBuilder', () {
    late PageBuilder builder;
    const testConfig = StardustConfig(name: 'Test Site');

    setUp(() {
      builder = PageBuilder(config: testConfig);
    });

    group('page metadata', () {
      const page = Page(
        path: '/guide',
        sourcePath: 'docs/guide.md',
        title: 'Guide',
        content: '<p>one two three</p>',
      );

      test('renders reading time, last updated, and contributors when enabled', () {
        const config = StardustConfig(
          name: 'T',
          pageInfo: PageInfoConfig(readingTime: true, lastUpdated: true, contributors: true),
        );
        final builder = PageBuilder(config: config)
          ..gitMetadata = {
            'docs/guide.md': GitFileMeta(lastModified: DateTime.utc(2026, 7, 24), authors: const ['Alice', 'Bob']),
          };

        final html = builder.build(page, sidebar: []);

        expect(html, contains('class="page-meta"'));
        expect(html, contains('1 min read'));
        expect(html, contains('Last updated 2026-07-24'));
        expect(html, contains('Alice, Bob'));
      });

      test('renders no meta block when nothing is enabled', () {
        expect(PageBuilder(config: const StardustConfig(name: 'T')).build(page, sidebar: []),
            isNot(contains('page-meta')));
      });

      test('escapes contributor names', () {
        const config = StardustConfig(name: 'T', pageInfo: PageInfoConfig(contributors: true));
        final builder = PageBuilder(config: config)
          ..gitMetadata = {
            'docs/guide.md': GitFileMeta(lastModified: DateTime.utc(2026), authors: const ['<script>evil']),
          };

        final html = builder.build(page, sidebar: []);

        expect(html, contains('&lt;script&gt;evil'));
        expect(html, isNot(contains('<script>evil')));
      });
    });

    group('splash layout', () {
      const splashPage = Page(
        path: '/',
        sourcePath: 'content/index.md',
        title: 'Stardust',
        content: '<p>Cards go here</p>',
        frontmatter: {
          'layout': 'splash',
          'hero': {
            'tagline': 'Docs you <own>',
            'image': '/images/logo.svg',
            'actions': [
              {'label': 'Get Started', 'href': '/quickstart', 'variant': 'primary'},
              {'label': 'GitHub', 'href': 'https://x.com', 'external': true},
              {'label': 'Bad', 'href': 'javascript:alert(1)'},
            ],
          },
        },
      );

      test('renders the hero and full-width splash, dropping docs chrome', () {
        final html = builder.build(splashPage, sidebar: [
          const SidebarGroup(group: 'Guides', pages: [SidebarPage(slug: 'guide')]),
        ]);

        expect(html, contains('class="hero"'));
        expect(html, contains('<main class="splash">'));
        expect(html, contains('Cards go here'));
        expect(html, isNot(contains('class="sidebar"')));
        expect(html, isNot(contains('class="toc"')));
        expect(html, isNot(contains('page-nav')));
      });

      test('renders hero title, tagline, and typed action buttons', () {
        final html = builder.build(splashPage, sidebar: []);

        expect(html, contains('<h1 class="hero-title">Stardust</h1>'));
        expect(html, contains('hero-action--primary'));
        expect(html, contains('href="/quickstart"'));
        expect(html, contains('target="_blank" rel="noopener"'));
      });

      test('escapes hero content and strips unsafe action hrefs', () {
        final html = builder.build(splashPage, sidebar: []);

        expect(html, contains('Docs you &lt;own&gt;'));
        expect(html, isNot(contains('javascript:alert(1)')));
      });

      test('a splash page without hero data renders no hero', () {
        const noHero = Page(
          path: '/',
          sourcePath: 'content/index.md',
          title: 'Home',
          content: '<p>Just cards</p>',
          frontmatter: {'layout': 'splash'},
        );

        final html = builder.build(noHero, sidebar: []);

        expect(html, contains('class="splash"'));
        expect(html, isNot(contains('class="hero"')));
      });
    });

    group('build', () {
      test('generates valid HTML structure', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test Page',
          content: '<p>Hello World</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains('<html'));
        expect(html, contains('</html>'));
        expect(html, contains('<head>'));
        expect(html, contains('</head>'));
        expect(html, contains('<body>'));
        expect(html, contains('</body>'));
      });

      test('includes page title in document', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'My Test Page',
          content: '<p>Content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('<title>'));
        expect(html, contains('My Test Page'));
      });

      test('includes page content', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>This is the page content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('This is the page content'));
        expect(html, contains('class="prose"'));
      });

      test('uses the localized copy-page Markdown label', () {
        const config = StardustConfig(
          name: 'Test',
          build: BuildConfig(llms: LlmsConfig(enabled: true)),
          i18n: I18nConfig(
            strings: I18nStrings(pageCopyMarkdown: 'Copier la page en Markdown'),
          ),
        );
        const page = Page(
          path: '/guide',
          sourcePath: 'content/guide.md',
          title: 'Guide',
          content: '<p>Content</p>',
        );

        final html = PageBuilder(config: config).build(page, sidebar: []);

        expect(
          html,
          contains(
            '<button class="copy-page-button" data-md-path="../guide.md">Copier la page en Markdown</button>',
          ),
        );
        expect(html, isNot(contains('>Copy page as Markdown</button>')));
      });

      test('includes meta viewport', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('name="viewport"'));
        expect(html, contains('width=device-width'));
      });

      test('includes charset meta', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('charset="UTF-8"'));
      });

      test('includes layout structure', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('class="layout"'));
        expect(html, contains('class="mobile-overlay"'));
        expect(html, contains('id="mobile-overlay"'));
        expect(html, contains('class="main-container"'));
        expect(html, contains('<main'));
      });

      test('handles root path', () {
        const page = Page(
          path: '/',
          sourcePath: 'content/index.md',
          title: 'Home',
          content: '<p>Welcome</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('Home'));
        expect(html, contains('Welcome'));
      });

      test('handles nested paths', () {
        const page = Page(
          path: '/docs/getting-started/installation',
          sourcePath: 'content/docs/getting-started/installation.md',
          title: 'Installation',
          content: '<p>Install steps</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('Installation'));
        expect(html, contains('Install steps'));
      });

      test('builds with sidebar groups', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        const sidebar = [
          SidebarGroup(
            group: 'Getting Started',
            pages: [
              SidebarPage(slug: 'intro', label: 'Introduction'),
              SidebarPage(slug: 'setup', label: 'Setup'),
            ],
          ),
        ];

        final html = builder.build(page, sidebar: sidebar);

        expect(html, contains('Getting Started'));
        expect(html, contains('Introduction'));
        expect(html, contains('Setup'));
      });

      test('marks the article as pagefind body by default', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('<article class="prose" data-pagefind-body>'));
      });

      test('search: false frontmatter removes the pagefind body attribute', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
          frontmatter: {'search': false},
        );

        final html = builder.build(page, sidebar: []);

        expect(html, isNot(contains('data-pagefind-body')));
      });

      test('applies theme with a blocking script in head, before styles', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, isNot(contains('dark-mode-')));
        final head = html.substring(0, html.indexOf('</head>'));
        expect(head, contains("classList.toggle('dark', dark)"));
        expect(head.indexOf('classList.toggle'), lessThan(head.indexOf('rel="stylesheet"')));
      });
    });

    group('with custom config', () {
      test('applies SEO title template', () {
        const customConfig = StardustConfig(
          name: 'My Docs',
          seo: SeoConfig(titleTemplate: '%s | My Docs'),
        );
        final customBuilder = PageBuilder(config: customConfig);

        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'API Reference',
          content: '<p>Content</p>',
        );

        final html = customBuilder.build(page, sidebar: []);

        expect(html, contains('API Reference | My Docs'));
      });

      test('includes favicon link when configured', () {
        const customConfig = StardustConfig(
          name: 'My Docs',
          favicon: '/images/favicon.svg',
        );
        final customBuilder = PageBuilder(config: customConfig);

        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        final html = customBuilder.build(page, sidebar: []);

        expect(html, contains('<link rel="icon"'));
        expect(html, contains('href="/images/favicon.svg"'));
      });
    });
  });

  group('Page', () {
    test('stores all required properties', () {
      const page = Page(
        path: '/getting-started',
        sourcePath: 'content/getting-started.md',
        title: 'Getting Started',
        content: '<p>Content here</p>',
      );

      expect(page.path, equals('/getting-started'));
      expect(page.sourcePath, equals('content/getting-started.md'));
      expect(page.title, equals('Getting Started'));
      expect(page.content, equals('<p>Content here</p>'));
    });

    test('stores optional properties', () {
      const toc = [TocEntry(level: 2, text: 'Section', id: 'section')];
      const prev = PageLink(path: '/prev', title: 'Previous');
      const next = PageLink(path: '/next', title: 'Next');
      const breadcrumbs = [PageLink(path: '/', title: 'Home')];

      const page = Page(
        path: '/test',
        sourcePath: 'content/test.md',
        title: 'Test',
        description: 'A test page',
        content: '<p>Content</p>',
        toc: toc,
        frontmatter: {'key': 'value'},
        prev: prev,
        next: next,
        breadcrumbs: breadcrumbs,
      );

      expect(page.description, equals('A test page'));
      expect(page.toc, equals(toc));
      expect(page.frontmatter['key'], equals('value'));
      expect(page.prev, equals(prev));
      expect(page.next, equals(next));
      expect(page.breadcrumbs, equals(breadcrumbs));
    });

    test('defaults optional properties', () {
      const page = Page(
        path: '/test',
        sourcePath: 'content/test.md',
        title: 'Test',
        content: '<p>Content</p>',
      );

      expect(page.description, isNull);
      expect(page.toc, isEmpty);
      expect(page.frontmatter, isEmpty);
      expect(page.prev, isNull);
      expect(page.next, isNull);
      expect(page.breadcrumbs, isEmpty);
    });

    group('outputPath', () {
      test('returns index.html for root path', () {
        const page = Page(
          path: '/',
          sourcePath: 'content/index.md',
          title: 'Home',
          content: '<p>Content</p>',
        );

        expect(page.outputPath, equals('index.html'));
      });

      test('returns nested path with index.html', () {
        const page = Page(
          path: '/getting-started',
          sourcePath: 'content/getting-started.md',
          title: 'Getting Started',
          content: '<p>Content</p>',
        );

        expect(page.outputPath, equals('getting-started/index.html'));
      });

      test('handles deeply nested paths', () {
        const page = Page(
          path: '/docs/api/auth',
          sourcePath: 'content/docs/api/auth.md',
          title: 'Auth',
          content: '<p>Content</p>',
        );

        expect(page.outputPath, equals('docs/api/auth/index.html'));
      });
    });
  });

  group('html lang and dir', () {
    test('defaults to lang="en" and dir="ltr"', () {
      const config = StardustConfig(name: 'Test');
      final builder = PageBuilder(config: config);

      final result = builder.build(
        const Page(path: '/', sourcePath: '/docs/index.md', title: 'Home', content: ''),
        sidebar: const [],
      );

      expect(result, contains('lang="en"'));
      expect(result, contains('dir="ltr"'));
    });

    test('sets lang from i18n defaultLocale', () {
      const config = StardustConfig(
        name: 'Test',
        i18n: I18nConfig(defaultLocale: 'fr'),
      );
      final builder = PageBuilder(config: config);

      final result = builder.build(
        const Page(path: '/', sourcePath: '/docs/index.md', title: 'Home', content: ''),
        sidebar: const [],
      );

      expect(result, contains('lang="fr"'));
    });

    test('sets dir="rtl" when current locale is RTL', () {
      const config = StardustConfig(
        name: 'Test',
        i18n: I18nConfig(
          enabled: true,
          defaultLocale: 'ar',
          locales: [
            LocaleConfig(code: 'ar', label: 'العربية', dir: 'rtl', path: '/ar/'),
          ],
        ),
      );
      final builder = PageBuilder(config: config);

      final result = builder.build(
        const Page(path: '/', sourcePath: '/docs/index.md', title: 'Home', content: ''),
        sidebar: const [],
      );

      expect(result, contains('dir="rtl"'));
    });
  });

  group('PageLink', () {
    test('stores path and title', () {
      const link = PageLink(path: '/next-page', title: 'Next Page');

      expect(link.path, equals('/next-page'));
      expect(link.title, equals('Next Page'));
    });
  });
}
