import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/builders/page_layout_builder.dart';
import 'package:stardust/src/generator/builders/page_meta_builder.dart';
import 'package:stardust/src/generator/url_resolver.dart';
import 'package:stardust/src/models/page.dart';
import 'package:test/test.dart';

void main() {
  group('UrlResolver', () {
    const subpathConfig = StardustConfig(name: 'T', url: 'https://example.com/docs');

    test('href applies the base path', () {
      expect(const UrlResolver(subpathConfig).href('/guide'), equals('/docs/guide'));
      expect(const UrlResolver(StardustConfig(name: 'T')).href('/guide'), equals('/guide'));
    });

    test('absolute never re-applies the base path from the url', () {
      expect(const UrlResolver(subpathConfig).absolute('/guide'), equals('https://example.com/docs/guide'));
    });

    test('absolute trims a trailing slash from the configured url', () {
      const config = StardustConfig(name: 'T', url: 'https://example.com/');
      expect(const UrlResolver(config).absolute('/guide'), equals('https://example.com/guide'));
    });

    test('absolute is null without a configured url', () {
      expect(const UrlResolver(StardustConfig(name: 'T')).absolute('/guide'), isNull);
    });

    test('relativeRoot walks up to the site root', () {
      const resolver = UrlResolver(StardustConfig(name: 'T'));
      expect(resolver.relativeRoot('/'), equals('.'));
      expect(resolver.relativeRoot('/guide'), equals('..'));
      expect(resolver.relativeRoot('/guide/intro'), equals('../..'));
    });
  });

  group('subpath deploy regressions', () {
    const config = StardustConfig(name: 'T', url: 'https://example.com/docs');
    const page = Page(path: '/guide', sourcePath: 'c/guide.md', title: 'G', content: '');

    test('og:image is not double-prefixed with the base path', () {
      final meta = PageMetaBuilder(config: config).build(page);

      expect(meta, contains('https://example.com/docs/images/og/guide.png'));
      expect(meta, isNot(contains('/docs/docs/')));
    });

    test('canonical and og:image agree on the subpath', () {
      final meta = PageMetaBuilder(config: config).build(page);

      expect(meta, contains('href="https://example.com/docs/guide"'));
    });

    test('version dropdown links carry the base path', () {
      const versioned = StardustConfig(
        name: 'T',
        url: 'https://example.com/docs',
        versions: VersionsConfig(
          enabled: true,
          current: '2.0',
          list: [VersionEntry(version: '2.0', path: '/'), VersionEntry(version: '1.0', path: '/v1/')],
        ),
      );

      final header = PageLayoutBuilder(config: versioned).buildHeader();

      expect(header, contains('href="/docs/v1/"'));
    });

    test('locale dropdown links carry the base path', () {
      const localized = StardustConfig(
        name: 'T',
        url: 'https://example.com/docs',
        i18n: I18nConfig(
          enabled: true,
          defaultLocale: 'en',
          locales: [
            LocaleConfig(code: 'en', label: 'English', path: '/'),
            LocaleConfig(code: 'ar', label: 'Arabic', path: '/ar/'),
          ],
        ),
      );

      final header = PageLayoutBuilder(config: localized).buildHeader();

      expect(header, contains('href="/docs/ar/"'));
    });
  });
}
