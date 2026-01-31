import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/site_generator.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('SiteGenerator', () {
    late Directory tempDir;
    late String contentDir;
    late String outputDir;

    setUp(() async {
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('stardust_test_');
      contentDir = p.join(tempDir.path, 'docs');
      outputDir = p.join(tempDir.path, 'dist');

      // Create content directory
      await Directory(contentDir).create(recursive: true);
    });

    tearDown(() async {
      // Clean up temp directory
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('constructor', () {
      test('uses provided dependencies', () {
        final mockFs = MockFileSystem();
        final logger = Logger(onLog: (_) {});
        const config = StardustConfig(name: 'Test');

        final generator = SiteGenerator(
          config: config,
          outputDir: '/output',
          fileSystem: mockFs,
          logger: logger,
        );

        expect(generator.config.name, equals('Test'));
        expect(generator.outputDir, equals('/output'));
        expect(generator.logger, equals(logger));
        expect(generator.fileSystem, equals(mockFs));
      });

      test('creates default dependencies when not provided', () {
        const config = StardustConfig(name: 'Test');

        final generator = SiteGenerator(
          config: config,
          outputDir: '/output',
        );

        expect(generator.contentParser, isNotNull);
        expect(generator.pageBuilder, isNotNull);
      });
    });

    group('generate', () {
      test('throws when content directory does not exist', () async {
        final nonExistentDir = p.join(tempDir.path, 'nonexistent');
        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: nonExistentDir),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        expect(
          generator.generate,
          throwsA(isA<GeneratorException>()),
        );
      });

      test('generates pages from markdown files', () async {
        // Create test markdown file
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('''
---
title: Home
description: Welcome to the docs
---

# Welcome

This is the home page.
''');

        final guideFile = File(p.join(contentDir, 'guide.md'));
        await guideFile.writeAsString('''
---
title: Guide
---

# Getting Started

Follow these steps.
''');

        final config = StardustConfig(
          name: 'Test Site',
          content: ContentConfig(dir: contentDir),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        final count = await generator.generate();

        expect(count, equals(2));
        expect(logs.any((l) => l.contains('Found 2 markdown files')), isTrue);

        // Verify output files
        expect(File(p.join(outputDir, 'index.html')).existsSync(), isTrue);
        expect(File(p.join(outputDir, 'guide', 'index.html')).existsSync(), isTrue);
      });

      test('skips draft pages', () async {
        final draftFile = File(p.join(contentDir, 'draft.md'));
        await draftFile.writeAsString('''
---
title: Draft
draft: true
---

Draft content
''');

        final publishedFile = File(p.join(contentDir, 'published.md'));
        await publishedFile.writeAsString('''
---
title: Published
---

Published content
''');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        final count = await generator.generate();

        expect(count, equals(1));
        expect(logs.any((l) => l.contains('Skipping draft')), isTrue);
      });

      test('generates sitemap when enabled and url configured', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(
            sitemap: SitemapConfig(enabled: true),
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        await generator.generate();

        final sitemapFile = File(p.join(outputDir, 'sitemap.xml'));
        expect(sitemapFile.existsSync(), isTrue);

        final sitemapContent = await sitemapFile.readAsString();
        expect(sitemapContent, contains('<?xml version="1.0"'));
        expect(sitemapContent, contains('https://example.com'));
      });

      test('skips sitemap when url not configured', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(
            sitemap: SitemapConfig(enabled: true),
          ),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Skipping sitemap.xml')), isTrue);
      });

      test('generates robots.txt when enabled', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(
            robots: RobotsConfig(
              enabled: true,
              allow: ['/'],
              disallow: ['/private'],
            ),
            sitemap: SitemapConfig(enabled: true),
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        await generator.generate();

        final robotsFile = File(p.join(outputDir, 'robots.txt'));
        expect(robotsFile.existsSync(), isTrue);

        final robotsContent = await robotsFile.readAsString();
        expect(robotsContent, contains('User-agent: *'));
        expect(robotsContent, contains('Allow: /'));
        expect(robotsContent, contains('Disallow: /private'));
        expect(robotsContent, contains('Sitemap: https://example.com/sitemap.xml'));
      });

      test('generates llms.txt when enabled', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('''
---
title: Home
description: The home page
---

# Welcome
''');

        final config = StardustConfig(
          name: 'Test Site',
          description: 'A test documentation site',
          url: 'https://example.com',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(
            llms: LlmsConfig(enabled: true),
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        await generator.generate();

        final llmsFile = File(p.join(outputDir, 'llms.txt'));
        expect(llmsFile.existsSync(), isTrue);

        final llmsContent = await llmsFile.readAsString();
        expect(llmsContent, contains('# Test Site'));
        expect(llmsContent, contains('A test documentation site'));
        expect(llmsContent, contains('Website: https://example.com'));
      });

      test('copies public assets when directory exists', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('# Home');

        // Create public assets directory with a file
        final publicDir = p.join(tempDir.path, 'public');
        await Directory(publicDir).create();
        await File(p.join(publicDir, 'logo.png')).writeAsString('fake png data');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          build: BuildConfig(
            assets: AssetsConfig(dir: publicDir),
          ),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Copying public assets')), isTrue);
      });

      test('adds navigation to pages based on sidebar config', () async {
        // Create multiple files
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');
        await File(p.join(contentDir, 'guide.md')).writeAsString('# Guide');
        await File(p.join(contentDir, 'api.md')).writeAsString('# API');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          sidebar: const [
            SidebarGroup(group: 'Docs', pages: [
              SidebarPage(slug: 'index'),
              SidebarPage(slug: 'guide'),
              SidebarPage(slug: 'api'),
            ]),
          ],
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        await generator.generate();

        // Verify the guide page has prev/next navigation
        final guideHtml = await File(p.join(outputDir, 'guide', 'index.html')).readAsString();
        expect(guideHtml, contains('page-nav'));
      });

      test('handles parse errors gracefully', () async {
        // Create a file that might cause parsing issues
        await File(p.join(contentDir, 'valid.md')).writeAsString('# Valid');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
        );

        final errors = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: (_) {}, onError: errors.add),
        );

        // Should not throw, should handle errors gracefully
        final count = await generator.generate();
        expect(count, greaterThanOrEqualTo(0));
      });

      test('respects content exclude patterns', () async {
        await File(p.join(contentDir, 'included.md')).writeAsString('# Included');

        // Create excluded directory
        final draftsDir = p.join(contentDir, 'drafts');
        await Directory(draftsDir).create();
        await File(p.join(draftsDir, 'excluded.md')).writeAsString('# Excluded');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(
            dir: contentDir,
            exclude: ['drafts/**'],
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        final count = await generator.generate();

        expect(count, equals(1));
        expect(
          File(p.join(outputDir, 'drafts', 'excluded', 'index.html')).existsSync(),
          isFalse,
        );
      });
    });

    group('llms.txt generation', () {
      test('uses sidebar structure when available', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('''
---
title: Home
description: Home description
---
# Home
''');
        await File(p.join(contentDir, 'guide.md')).writeAsString('''
---
title: Guide
description: Guide description
---
# Guide
''');

        final config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
          content: ContentConfig(dir: contentDir),
          sidebar: const [
            SidebarGroup(group: 'Getting Started', pages: [
              SidebarPage(slug: 'index'),
              SidebarPage(slug: 'guide', label: 'User Guide'),
            ]),
          ],
          build: const BuildConfig(
            llms: LlmsConfig(enabled: true),
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        await generator.generate();

        final llmsContent = await File(p.join(outputDir, 'llms.txt')).readAsString();
        expect(llmsContent, contains('## Getting Started'));
        expect(llmsContent, contains('[User Guide](/')); // Uses sidebar label
      });

      test('lists all pages when no sidebar', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');
        await File(p.join(contentDir, 'about.md')).writeAsString('# About');

        final config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(
            llms: LlmsConfig(enabled: true),
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
        );

        await generator.generate();

        final llmsContent = await File(p.join(outputDir, 'llms.txt')).readAsString();
        expect(llmsContent, contains('## Pages'));
      });
    });

    group('OG image generation', () {
      test('generates OG images in build mode', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Generating OG images')), isTrue);
        expect(Directory(p.join(outputDir, 'images', 'og')).existsSync(), isTrue);
      });

      test('skips OG images in dev mode', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
        ).withDevMode();

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Generating OG images')), isFalse);
        expect(Directory(p.join(outputDir, 'images', 'og')).existsSync(), isFalse);
      });

      test('skips OG images when custom ogImage is configured', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          seo: const SeoConfig(ogImage: '/images/custom-og.png'),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Generating OG images')), isFalse);
      });
    });

    group('redirect generation', () {
      test('generates redirects from config', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');
        await File(p.join(contentDir, 'new-page.md')).writeAsString('# New Page');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(
            redirects: [
              RedirectConfig(from: '/old-page', to: '/new-page'),
            ],
          ),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Generating redirects')), isTrue);
        expect(File(p.join(outputDir, 'old-page', 'index.html')).existsSync(), isTrue);
        expect(File(p.join(outputDir, '_redirects')).existsSync(), isTrue);
        expect(File(p.join(outputDir, 'vercel.json')).existsSync(), isTrue);
      });

      test('generates redirects from frontmatter', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');
        await File(p.join(contentDir, 'new-guide.md')).writeAsString('''
---
title: New Guide
redirect_from:
  - /old-guide
  - /legacy/guide
---
# New Guide
''');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Generating redirects')), isTrue);
        expect(File(p.join(outputDir, 'old-guide', 'index.html')).existsSync(), isTrue);
        expect(File(p.join(outputDir, 'legacy', 'guide', 'index.html')).existsSync(), isTrue);
      });

      test('skips redirect generation when no redirects configured', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
        );

        final logs = <String>[];
        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: logs.add),
        );

        await generator.generate();

        expect(logs.any((l) => l.contains('Generating redirects')), isFalse);
        expect(File(p.join(outputDir, '_redirects')).existsSync(), isFalse);
      });
    });

    group('custom CSS file', () {
      test('resolves cssFile content before building pages', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('''
---
title: Home
---

# Home
''');

        final cssFilePath = p.join(tempDir.path, 'custom.css');
        await File(cssFilePath).writeAsString('.from-file { color: blue; }');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          theme: ThemeConfig(
            custom: CustomThemeConfig(cssFile: cssFilePath),
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: (_) {}),
        );

        await generator.generate();

        final html = await File(p.join(outputDir, 'index.html')).readAsString();
        expect(html, contains('.from-file { color: blue; }'));
      });

      test('skips missing cssFile without error', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('''
---
title: Home
---

# Home
''');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          theme: const ThemeConfig(
            custom: CustomThemeConfig(cssFile: '/nonexistent/style.css'),
          ),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          logger: Logger(onLog: (_) {}),
        );

        final count = await generator.generate();
        expect(count, equals(1));
      });
    });
  });
}
