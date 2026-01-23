import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:stardust/src/config/build_config.dart';
import 'package:stardust/src/generator/redirect_generator.dart';
import 'package:stardust/src/models/page.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('RedirectGenerator', () {
    late MockFileSystem fileSystem;
    late List<String> logs;
    late List<String> errors;
    late Logger logger;

    setUp(() {
      fileSystem = MockFileSystem();
      logs = [];
      errors = [];
      logger = Logger(
        onLog: logs.add,
        onError: errors.add,
      );
    });

    group('generateAll', () {
      test('returns 0 when no redirects configured', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        final count = await generator.generateAll(
          configRedirects: [],
          pages: [],
        );

        expect(count, 0);
        expect(logs, isEmpty);
      });

      test('generates HTML redirects for exact paths', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        final count = await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old-page', to: '/new-page'),
            const RedirectConfig(from: '/docs/old', to: '/docs/new', status: 302),
          ],
          pages: [],
        );

        expect(count, 2);

        final html1 = fileSystem.files[p.join('dist', 'old-page', 'index.html')];
        expect(html1, isNotNull);
        expect(html1, contains('url=/new-page'));
        expect(html1, contains('href="/new-page"'));

        final html2 = fileSystem.files[p.join('dist', 'docs', 'old', 'index.html')];
        expect(html2, isNotNull);
        expect(html2, contains('url=/docs/new'));
      });

      test('generates HTML redirects with basePath', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          basePath: '/mysite',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old', to: '/new'),
          ],
          pages: [],
        );

        final html = fileSystem.files[p.join('dist', 'old', 'index.html')];
        expect(html, contains('url=/mysite/new'));
        expect(html, contains('href="/mysite/new"'));
      });

      test('skips HTML generation for root redirect', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/', to: '/home'),
          ],
          pages: [],
        );

        expect(errors, contains(contains('Cannot redirect from "/"')));
        expect(fileSystem.files.containsKey(p.join('dist', 'index.html')), isFalse);
      });

      test('generates _redirects file for Netlify/Cloudflare', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old', to: '/new', status: 301),
            const RedirectConfig(from: '/temp', to: '/other', status: 302),
          ],
          pages: [],
        );

        final redirects = fileSystem.files[p.join('dist', '_redirects')];
        expect(redirects, isNotNull);
        expect(redirects, contains('/old    /new    301'));
        expect(redirects, contains('/temp    /other    302'));
      });

      test('converts wildcards to Netlify :splat format', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/docs/*', to: '/documentation/:splat'),
          ],
          pages: [],
        );

        final redirects = fileSystem.files[p.join('dist', '_redirects')];
        expect(redirects, contains('/docs/:splat    /documentation/:splat    301'));
      });

      test('generates vercel.json for Vercel', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old', to: '/new', status: 301),
            const RedirectConfig(from: '/temp', to: '/other', status: 302),
          ],
          pages: [],
        );

        final vercelJson = fileSystem.files[p.join('dist', 'vercel.json')];
        expect(vercelJson, isNotNull);

        final config = jsonDecode(vercelJson!) as Map<String, dynamic>;
        final redirects = config['redirects'] as List;

        expect(redirects.length, 2);
        expect(redirects[0]['source'], '/old');
        expect(redirects[0]['destination'], '/new');
        expect(redirects[0]['permanent'], true);
        expect(redirects[1]['permanent'], false);
        expect(redirects[1]['statusCode'], 302);
      });

      test('converts wildcards to Vercel :path* format', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/docs/*', to: '/documentation/:path*'),
          ],
          pages: [],
        );

        final vercelJson = fileSystem.files[p.join('dist', 'vercel.json')];
        final config = jsonDecode(vercelJson!) as Map<String, dynamic>;
        final redirects = config['redirects'] as List;

        expect(redirects[0]['source'], '/docs/:path*');
      });

      test('collects redirects from page frontmatter', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        final pages = [
          const Page(
            path: '/new-guide',
            sourcePath: 'docs/new-guide.md',
            title: 'New Guide',
            content: '',
            redirectFrom: ['/old-guide', '/legacy/guide'],
          ),
        ];

        final count = await generator.generateAll(
          configRedirects: [],
          pages: pages,
        );

        expect(count, 2);

        final html1 = fileSystem.files[p.join('dist', 'old-guide', 'index.html')];
        expect(html1, contains('url=/new-guide'));

        final html2 = fileSystem.files[p.join('dist', 'legacy', 'guide', 'index.html')];
        expect(html2, contains('url=/new-guide'));
      });

      test('combines config and frontmatter redirects', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        final pages = [
          const Page(
            path: '/docs',
            sourcePath: 'docs/index.md',
            title: 'Docs',
            content: '',
            redirectFrom: ['/documentation'],
          ),
        ];

        final count = await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old', to: '/new'),
          ],
          pages: pages,
        );

        expect(count, 2);

        final redirects = fileSystem.files[p.join('dist', '_redirects')];
        expect(redirects, contains('/old    /new    301'));
        expect(redirects, contains('/documentation    /docs    301'));
      });

      test('does not generate HTML for wildcard redirects', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/blog/*', to: '/articles/:splat'),
          ],
          pages: [],
        );

        expect(fileSystem.files.keys.where((k) => k.endsWith('.html')), isEmpty);

        final redirects = fileSystem.files[p.join('dist', '_redirects')];
        expect(redirects, isNotNull);
      });

      test('does not generate HTML for named param redirects', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/posts/:slug', to: '/blog/:slug'),
          ],
          pages: [],
        );

        expect(fileSystem.files.keys.where((k) => k.endsWith('.html')), isEmpty);
      });

      test('logs correct count for mixed redirects', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old', to: '/new'),
            const RedirectConfig(from: '/docs/*', to: '/documentation/:splat'),
          ],
          pages: [],
        );

        expect(logs, contains(contains('1 HTML redirects')));
        expect(logs, contains(contains('1 pattern rules')));
      });

      test('handles paths with trailing slashes', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old/', to: '/new'),
          ],
          pages: [],
        );

        final html = fileSystem.files[p.join('dist', 'old', 'index.html')];
        expect(html, isNotNull);
        expect(html, contains('url=/new'));
      });

      test('generates canonical link in HTML redirect', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old', to: '/new'),
          ],
          pages: [],
        );

        final html = fileSystem.files[p.join('dist', 'old', 'index.html')];
        expect(html, contains('<link rel="canonical" href="/new">'));
      });

      test('generates JavaScript fallback in HTML redirect', () async {
        final generator = RedirectGenerator(
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await generator.generateAll(
          configRedirects: [
            const RedirectConfig(from: '/old', to: '/new'),
          ],
          pages: [],
        );

        final html = fileSystem.files[p.join('dist', 'old', 'index.html')];
        expect(html, contains('window.location.href = "/new"'));
      });
    });

    group('RedirectConfig', () {
      test('fromYaml parses basic config', () {
        final config = RedirectConfig.fromYaml({
          'from': '/old',
          'to': '/new',
        });

        expect(config.from, '/old');
        expect(config.to, '/new');
        expect(config.status, 301);
      });

      test('fromYaml parses custom status', () {
        final config = RedirectConfig.fromYaml({
          'from': '/old',
          'to': '/new',
          'status': 302,
        });

        expect(config.status, 302);
      });
    });
  });
}
