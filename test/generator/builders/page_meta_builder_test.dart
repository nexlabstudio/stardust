import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/builders/page_meta_builder.dart';
import 'package:stardust/src/models/page.dart';
import 'package:test/test.dart';

void main() {
  group('PageMetaBuilder', () {
    late PageMetaBuilder builder;
    late Page testPage;

    group('buildFavicon', () {
      test('returns empty string when favicon is not configured', () {
        const config = StardustConfig(name: 'Test Site');
        builder = PageMetaBuilder(config: config);

        expect(builder.buildFavicon(), isEmpty);
      });

      test('builds SVG favicon with correct MIME type', () {
        const config = StardustConfig(
          name: 'Test Site',
          favicon: '/images/favicon.svg',
        );
        builder = PageMetaBuilder(config: config);

        final result = builder.buildFavicon();

        expect(result, contains('rel="icon"'));
        expect(result, contains('type="image/svg+xml"'));
        expect(result, contains('href="/images/favicon.svg"'));
      });

      test('builds PNG favicon with correct MIME type', () {
        const config = StardustConfig(
          name: 'Test Site',
          favicon: '/favicon.png',
        );
        builder = PageMetaBuilder(config: config);

        final result = builder.buildFavicon();

        expect(result, contains('type="image/png"'));
        expect(result, contains('href="/favicon.png"'));
      });

      test('builds ICO favicon with correct MIME type', () {
        const config = StardustConfig(
          name: 'Test Site',
          favicon: '/favicon.ico',
        );
        builder = PageMetaBuilder(config: config);

        final result = builder.buildFavicon();

        expect(result, contains('type="image/x-icon"'));
        expect(result, contains('href="/favicon.ico"'));
      });

      test('defaults to x-icon for unknown extensions', () {
        const config = StardustConfig(
          name: 'Test Site',
          favicon: '/favicon.unknown',
        );
        builder = PageMetaBuilder(config: config);

        final result = builder.buildFavicon();

        expect(result, contains('type="image/x-icon"'));
      });

      test('prepends basePath to favicon href', () {
        const config = StardustConfig(
          name: 'Test Site',
          build: BuildConfig(basePath: '/docs'),
          favicon: '/favicon.svg',
        );
        builder = PageMetaBuilder(config: config);

        final result = builder.buildFavicon();

        expect(result, contains('href="/docs/favicon.svg"'));
      });
    });

    group('with minimal config', () {
      setUp(() {
        const config = StardustConfig(name: 'Test Site');
        builder = PageMetaBuilder(config: config);
        testPage = const Page(
          path: '/docs/intro',
          sourcePath: '/content/docs/intro.md',
          title: 'Introduction',
          content: '<p>Content</p>',
          toc: [],
          frontmatter: {},
        );
      });

      test('builds OG title', () {
        final result = builder.build(testPage);

        expect(result, contains('<meta property="og:title" content="Introduction">'));
      });

      test('builds OG type', () {
        final result = builder.build(testPage);

        expect(result, contains('<meta property="og:type" content="article">'));
      });

      test('builds twitter card', () {
        final result = builder.build(testPage);

        expect(result, contains('<meta name="twitter:card" content="summary_large_image">'));
      });

      test('does not include canonical link without url', () {
        final result = builder.build(testPage);

        expect(result, isNot(contains('<link rel="canonical"')));
      });
    });

    group('with url configured', () {
      setUp(() {
        const config = StardustConfig(
          name: 'Test Site',
          url: 'https://example.com',
        );
        builder = PageMetaBuilder(config: config);
        testPage = const Page(
          path: '/docs/intro',
          sourcePath: '/content/docs/intro.md',
          title: 'Introduction',
          content: '<p>Content</p>',
          toc: [],
          frontmatter: {},
        );
      });

      test('builds canonical link', () {
        final result = builder.build(testPage);

        expect(result, contains('<link rel="canonical" href="https://example.com/docs/intro">'));
      });

      test('builds OG url', () {
        final result = builder.build(testPage);

        expect(result, contains('<meta property="og:url" content="https://example.com/docs/intro">'));
      });

      test('handles root path without double slash', () {
        const rootPage = Page(
          path: '/',
          sourcePath: '/content/index.md',
          title: 'Home',
          content: '<p>Home</p>',
          toc: [],
          frontmatter: {},
        );

        final result = builder.build(rootPage);

        expect(result, contains('href="https://example.com"'));
        expect(result, contains('og:url" content="https://example.com"'));
      });

      test('normalizes URL with trailing slash', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.com/',
        );
        final builderWithTrailingSlash = PageMetaBuilder(config: config);

        final result = builderWithTrailingSlash.build(testPage);

        expect(result, contains('href="https://example.com/docs/intro"'));
      });
    });

    group('with description', () {
      setUp(() {
        const config = StardustConfig(name: 'Test Site');
        builder = PageMetaBuilder(config: config);
        testPage = const Page(
          path: '/about',
          sourcePath: '/content/about.md',
          title: 'About',
          description: 'Learn about our site',
          content: '<p>Content</p>',
          toc: [],
          frontmatter: {},
        );
      });

      test('builds meta description', () {
        final result = builder.build(testPage);

        expect(result, contains('<meta name="description" content="Learn about our site">'));
      });

      test('builds OG description', () {
        final result = builder.build(testPage);

        expect(result, contains('<meta property="og:description" content="Learn about our site">'));
      });

      test('escapes HTML in description', () {
        const pageWithHtml = Page(
          path: '/test',
          sourcePath: '/content/test.md',
          title: 'Test',
          description: 'Description with <script>alert("xss")</script>',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builder.build(pageWithHtml);

        expect(result, contains('&lt;script&gt;'));
        expect(result, isNot(contains('<script>')));
      });
    });

    group('with SEO config', () {
      test('includes OG image when configured', () {
        const config = StardustConfig(
          name: 'Test',
          seo: SeoConfig(ogImage: '/og-image.png'),
        );
        final builderWithSeo = PageMetaBuilder(config: config);

        final result = builderWithSeo.build(testPage);

        expect(result, contains('<meta property="og:image" content="/og-image.png">'));
      });

      test('includes twitter handle when configured', () {
        const config = StardustConfig(
          name: 'Test',
          seo: SeoConfig(twitterHandle: '@myhandle'),
        );
        final builderWithSeo = PageMetaBuilder(config: config);
        const page = Page(
          path: '/test',
          sourcePath: '/test.md',
          title: 'Test',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builderWithSeo.build(page);

        expect(result, contains('<meta name="twitter:site" content="@myhandle">'));
      });

      test('uses custom twitter card type', () {
        const config = StardustConfig(
          name: 'Test',
          seo: SeoConfig(twitterCard: 'summary_large_image'),
        );
        final builderWithSeo = PageMetaBuilder(config: config);
        const page = Page(
          path: '/test',
          sourcePath: '/test.md',
          title: 'Test',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builderWithSeo.build(page);

        expect(result, contains('<meta name="twitter:card" content="summary_large_image">'));
      });
    });

    group('structured data', () {
      late PageMetaBuilder builderWithStructuredData;

      setUp(() {
        const config = StardustConfig(
          name: 'Test Site',
          description: 'A test site',
          url: 'https://example.com',
          seo: SeoConfig(
            structuredData: true,
            ogImage: '/og.png',
          ),
        );
        builderWithStructuredData = PageMetaBuilder(config: config);
      });

      test('includes article schema', () {
        const page = Page(
          path: '/article',
          sourcePath: '/content/article.md',
          title: 'My Article',
          description: 'Article description',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builderWithStructuredData.build(page);

        expect(result, contains('application/ld+json'));
        expect(result, contains('"@type":"Article"'));
        expect(result, contains('"headline":"My Article"'));
        expect(result, contains('"description":"Article description"'));
        expect(result, contains('"image":"/og.png"'));
      });

      test('includes breadcrumb schema when breadcrumbs exist', () {
        const page = Page(
          path: '/docs/guide/intro',
          sourcePath: '/content/docs/guide/intro.md',
          title: 'Intro',
          content: '',
          toc: [],
          frontmatter: {},
          breadcrumbs: [
            PageLink(path: '/', title: 'Home'),
            PageLink(path: '/docs', title: 'Docs'),
          ],
        );

        final result = builderWithStructuredData.build(page);

        expect(result, contains('"@type":"BreadcrumbList"'));
        expect(result, contains('"@type":"ListItem"'));
        expect(result, contains('"position":1'));
        expect(result, contains('"name":"Home"'));
      });

      test('includes website schema for root path', () {
        const rootPage = Page(
          path: '/',
          sourcePath: '/content/index.md',
          title: 'Home',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builderWithStructuredData.build(rootPage);

        expect(result, contains('"@type":"WebSite"'));
        expect(result, contains('"name":"Test Site"'));
        expect(result, contains('"description":"A test site"'));
      });

      test('escapes JSON in titles', () {
        const page = Page(
          path: '/test',
          sourcePath: '/test.md',
          title: 'Title with "quotes" and \\backslash',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builderWithStructuredData.build(page);

        expect(result, contains('\\"quotes\\"'));
        expect(result, contains('\\\\backslash'));
      });

      test('does not include structured data when disabled', () {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
          seo: SeoConfig(structuredData: false),
        );
        final builderWithoutStructuredData = PageMetaBuilder(config: config);
        const page = Page(
          path: '/test',
          sourcePath: '/test.md',
          title: 'Test',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builderWithoutStructuredData.build(page);

        expect(result, isNot(contains('application/ld+json')));
      });
    });
  });
}
