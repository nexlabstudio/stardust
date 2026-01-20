import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/content/markdown_parser.dart';
import 'package:stardust/src/generator/page_builder.dart';
import 'package:stardust/src/models/page.dart';
import 'package:test/test.dart';

void main() {
  group('PageBuilder', () {
    late PageBuilder builder;
    const testConfig = StardustConfig(name: 'Test Site');

    setUp(() {
      builder = PageBuilder(config: testConfig);
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

      test('includes dark mode class', () {
        const page = Page(
          path: '/test',
          sourcePath: 'content/test.md',
          title: 'Test',
          content: '<p>Content</p>',
        );

        final html = builder.build(page, sidebar: []);

        expect(html, contains('dark-mode-'));
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

  group('PageLink', () {
    test('stores path and title', () {
      const link = PageLink(path: '/next-page', title: 'Next Page');

      expect(link.path, equals('/next-page'));
      expect(link.title, equals('Next Page'));
    });
  });
}
