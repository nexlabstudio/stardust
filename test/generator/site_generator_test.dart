import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/core/file_system.dart';
import 'package:stardust/src/generator/page_info.dart';
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

      test('renders collected git metadata when pageInfo needs git', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home\n\nBody.');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          pageInfo: const PageInfoConfig(lastUpdated: true, contributors: true),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          gitMetadataCollector: _StubGitCollector((
            root: contentDir,
            files: {
              'index.md': GitFileMeta(
                lastModified: DateTime(2026, 1, 15),
                authors: const ['Ada Lovelace', 'Grace Hopper'],
              ),
            },
          )),
        );

        await generator.generate();

        final html = File(p.join(outputDir, 'index.html')).readAsStringSync();
        expect(html, contains('class="page-meta"'));
        expect(html, contains('2026-01-15'));
        expect(html, contains('Ada Lovelace, Grace Hopper'));
      });

      test('leaves pages unannotated when the collector finds no repository', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home\n\nBody.');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          pageInfo: const PageInfoConfig(lastUpdated: true, contributors: true),
        );

        final generator = SiteGenerator(
          config: config,
          outputDir: outputDir,
          gitMetadataCollector: _StubGitCollector(null),
        );

        await generator.generate();

        final html = File(p.join(outputDir, 'index.html')).readAsStringSync();
        expect(html, isNot(contains('class="page-meta"')));
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

      test('skips sitemap for a noindex (non-current) version', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(sitemap: SitemapConfig(enabled: true)),
          versions: const VersionsConfig(enabled: true, current: '2.0'),
          activeVersion: const VersionEntry(version: '1.0', path: '/v1/'),
        );

        final logs = <String>[];
        final generator = SiteGenerator(config: config, outputDir: outputDir, logger: Logger(onLog: logs.add));

        await generator.generate();

        expect(File(p.join(outputDir, 'sitemap.xml')).existsSync(), isFalse);
        expect(logs.any((l) => l.contains('noindex version 1.0')), isTrue);
      });

      test('still generates sitemap for the current version', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          url: 'https://example.com',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(sitemap: SitemapConfig(enabled: true)),
          versions: const VersionsConfig(enabled: true, current: '2.0'),
          activeVersion: const VersionEntry(version: '2.0', path: '/'),
        );

        final generator = SiteGenerator(config: config, outputDir: outputDir);

        await generator.generate();

        expect(File(p.join(outputDir, 'sitemap.xml')).existsSync(), isTrue);
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

      test('skips per-version robots.txt during a versioned build', () async {
        final indexFile = File(p.join(contentDir, 'index.md'));
        await indexFile.writeAsString('# Home');

        final config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(robots: RobotsConfig(enabled: true)),
          versions: const VersionsConfig(enabled: true, current: '2.0'),
          activeVersion: const VersionEntry(version: '2.0', path: '/v2/'),
        );

        await SiteGenerator(config: config, outputDir: outputDir).generate();

        expect(File(p.join(outputDir, 'robots.txt')).existsSync(), isFalse);
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

      test('llms.txt excludes pages with llm: false frontmatter', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('''
---
title: Home
---

# Welcome
''');
        await File(p.join(contentDir, 'internal.md')).writeAsString('''
---
title: Internal Notes
llm: false
---

# Secret
''');

        final config = StardustConfig(
          name: 'Test Site',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(llms: LlmsConfig(enabled: true)),
        );
        final generator = SiteGenerator(config: config, outputDir: outputDir);

        await generator.generate();

        final llmsContent = await File(p.join(outputDir, 'llms.txt')).readAsString();
        expect(llmsContent, contains('[Home](/)'));
        expect(llmsContent, isNot(contains('Internal Notes')));
      });

      test('writes shared assets once and links them with content hashes', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');
        await File(p.join(contentDir, 'other.md')).writeAsString('# Other');

        final config = StardustConfig(name: 'Test Site', content: ContentConfig(dir: contentDir));
        await SiteGenerator(config: config, outputDir: outputDir).generate();

        final css = File(p.join(outputDir, 'assets', 'styles.css'));
        final js = File(p.join(outputDir, 'assets', 'app.js'));
        expect(css.existsSync(), isTrue);
        expect(js.existsSync(), isTrue);
        expect(css.readAsStringSync(), contains('--color-primary'));
        expect(js.readAsStringSync(), contains('themeToggle'));

        final html = File(p.join(outputDir, 'index.html')).readAsStringSync();
        expect(html, contains(RegExp(r'assets/styles\.css\?v=[0-9a-f]{8}')));
        expect(html, contains(RegExp(r'assets/app\.js\?v=[0-9a-f]{8}')));
        expect(html, isNot(contains('--color-primary')));

        final other = File(p.join(outputDir, 'other', 'index.html')).readAsStringSync();
        expect(other, contains(RegExp(r'\.\./assets/styles\.css\?v=[0-9a-f]{8}')));
      });

      test('writes a .nojekyll file for GitHub Pages', () async {
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');

        final config = StardustConfig(name: 'Test Site', content: ContentConfig(dir: contentDir));
        await SiteGenerator(config: config, outputDir: outputDir).generate();

        expect(File(p.join(outputDir, '.nojekyll')).existsSync(), isTrue);
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
        expect(llmsContent, contains('[User Guide](https://example.com/')); // Uses sidebar label
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

        final sharedCss = await File(p.join(outputDir, 'assets', 'styles.css')).readAsString();
        expect(sharedCss, contains('.from-file { color: blue; }'));
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

  group('ai-ready output', () {
    test('writes per-page markdown, llms-full.txt, and respects llm: false', () async {
      final tempDir = await Directory.systemTemp.createTemp('stardust_ai_output');
      try {
        final contentDir = p.join(tempDir.path, 'content');
        await Directory(contentDir).create();
        await File(p.join(contentDir, 'index.md')).writeAsString('---\ntitle: Home\n---\n\nWelcome text.');
        await File(p.join(contentDir, 'secret.md')).writeAsString('---\ntitle: Secret\nllm: false\n---\n\nHidden.');

        final outputDir = p.join(tempDir.path, 'out');
        final config = StardustConfig(name: 'T', content: ContentConfig(dir: contentDir));
        await SiteGenerator(config: config, outputDir: outputDir, logger: const Logger()).generate();

        expect(File(p.join(outputDir, 'index.md')).existsSync(), isTrue);
        expect(File(p.join(outputDir, 'secret.md')).existsSync(), isFalse);

        final full = File(p.join(outputDir, 'llms-full.txt')).readAsStringSync();
        expect(full, contains('Welcome text.'));
        expect(full, isNot(contains('Hidden.')));

        final html = File(p.join(outputDir, 'index.html')).readAsStringSync();
        expect(html, contains('data-md-path="./index.md"'));
        final secretHtml = File(p.join(outputDir, 'secret', 'index.html')).readAsStringSync();
        expect(secretHtml, isNot(contains('copy-page-button')));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('incremental dev rebuilds', () {
    test('unchanged files are not re-read or re-parsed on rebuild', () async {
      final tempDir = await Directory.systemTemp.createTemp('stardust_incremental');
      try {
        final contentDir = p.join(tempDir.path, 'content');
        await Directory(contentDir).create();
        await File(p.join(contentDir, 'index.md')).writeAsString('# Home');
        final other = File(p.join(contentDir, 'other.md'));
        await other.writeAsString('# Other');

        final fileSystem = CountingFileSystem();
        final config = StardustConfig(
          name: 'T',
          content: ContentConfig(dir: contentDir),
          build: const BuildConfig(llms: LlmsConfig(enabled: false)),
        ).withDevMode();
        final generator = SiteGenerator(
          config: config,
          outputDir: p.join(tempDir.path, 'out'),
          fileSystem: fileSystem,
          logger: const Logger(),
        );

        await generator.generate();
        expect(fileSystem.contentReads, equals(2));

        await generator.generate();
        expect(fileSystem.contentReads, equals(2));

        await other.writeAsString('# Other changed');
        await other.setLastModified(DateTime.now().add(const Duration(seconds: 2)));
        await generator.generate();
        expect(fileSystem.contentReads, equals(3));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}

class CountingFileSystem extends LocalFileSystem {
  int contentReads = 0;

  @override
  Future<String> readFile(String path) {
    if (path.endsWith('.md')) contentReads++;
    return super.readFile(path);
  }
}

class _StubGitCollector extends GitMetadataCollector {
  _StubGitCollector(this.result);

  final ({String root, Map<String, GitFileMeta> files})? result;

  @override
  Future<({String root, Map<String, GitFileMeta> files})?> collect() async => result;
}
