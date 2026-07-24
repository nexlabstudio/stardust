import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../content/frontmatter_parser.dart';
import '../content/markdown_parser.dart';
import '../core/file_system.dart';
import '../core/interfaces.dart';
import '../models/page.dart';
import '../utils/concurrency.dart';
import '../utils/exceptions.dart';
import '../utils/html_utils.dart';
import '../utils/logger.dart';
import 'og_image_generator.dart';
import 'page_builder.dart';
import 'page_info.dart';
import 'redirect_generator.dart';
import 'robots_generator.dart';
import 'url_resolver.dart';

class SiteGenerator {
  final StardustConfig config;
  final String outputDir;
  final Logger logger;
  final FileSystem fileSystem;
  final ContentParser contentParser;
  final PageBuilder pageBuilder;

  SiteGenerator({
    required this.config,
    required this.outputDir,
    this.logger = const Logger(),
    FileSystem? fileSystem,
    ContentParser? contentParser,
    PageBuilder? pageBuilder,
  })  : fileSystem = fileSystem ?? const LocalFileSystem(),
        contentParser = contentParser ?? MarkdownParser(config: config),
        pageBuilder = pageBuilder ?? PageBuilder(config: config);

  /// Generate the static site, returns number of pages generated
  Future<int> generate() async {
    final cssFile = config.theme.custom?.cssFile;
    if (cssFile case final cssFile? when cssFile.isNotEmpty && await fileSystem.fileExists(cssFile)) {
      pageBuilder.stylesBuilder.resolvedCssFileContent = await fileSystem.readFile(cssFile);
    }

    await _writeSharedAssets();
    await fileSystem.writeFile(p.join(outputDir, '.nojekyll'), '');

    final contentDir = p.join(Directory.current.path, config.content.dir);
    final files = await _findMarkdownFiles(contentDir);

    logger.log('📄 Found ${files.length} markdown files');

    final pages = await _parsePages(files, contentDir);
    final pagesWithNav = _addNavigation(pages);

    if (config.pageInfo.needsGit) {
      if (await const GitMetadataCollector().collect() case final git?) {
        pageBuilder.gitMetadata = {
          for (final page in pagesWithNav)
            if (git.files[p.relative(page.sourcePath, from: git.root).replaceAll('\\', '/')] case final meta?)
              page.sourcePath: meta,
        };
      }
    }

    for (final chunk in chunked(pagesWithNav, Platform.numberOfProcessors)) {
      await Future.wait(chunk.map((page) async {
        await _generatePage(page);
        if (config.build.llms.enabled) await _writePageMarkdown(page);
      }));
      for (final page in chunk) {
        logger.log('  ✅ ${page.path}');
      }
    }
    final count = pagesWithNav.length;

    await _copyPublicAssets();

    if (config.build.sitemap.enabled) {
      await _generateSitemap(pagesWithNav);
    }

    if (config.build.robots.enabled && config.activeVersion == null) {
      await _generateRobots();
    }

    if (config.build.llms.enabled) {
      await _generateLlms(pagesWithNav);
      await _generateLlmsFull(pagesWithNav);
    }

    if (config.seo.ogImage == null && !config.devMode) {
      await _generateOgImages(pagesWithNav);
    }

    await _generateRedirects(pagesWithNav);

    return count;
  }

  /// Write the shared stylesheet and script once; pages link them by content hash.
  Future<void> _writeSharedAssets() async {
    final css = pageBuilder.stylesBuilder.buildCss();
    final js = pageBuilder.scriptsBuilder.buildAppJs();

    await fileSystem.writeFile(p.join(outputDir, 'assets', 'styles.css'), css);
    await fileSystem.writeFile(p.join(outputDir, 'assets', 'app.js'), js);

    pageBuilder.assetVersions = (css: _contentHash(css), js: _contentHash(js));
  }

  String _contentHash(String content) => sha256.convert(utf8.encode(content)).toString().substring(0, 8);

  Future<void> _generateOgImages(List<Page> pages) async {
    logger.log('🖼️  Generating OG images...');

    final generator = OgImageGenerator(
      config: config,
      outputDir: outputDir,
      logger: logger,
      fileSystem: fileSystem,
    );

    final results = await generator.generateAll(pages);
    logger.log('   ✓ Generated ${results.length} OG images');
  }

  Future<List<File>> _findMarkdownFiles(String contentDir) async {
    if (!await fileSystem.directoryExists(contentDir)) {
      throw GeneratorException('Content directory not found: $contentDir');
    }

    final includes = config.content.include.map(Glob.new).toList();
    final excludes = config.content.exclude.map(Glob.new).toList();
    final paths = <String>{};

    await for (final entity in fileSystem.listDirectory(contentDir, recursive: true)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: contentDir).replaceAll('\\', '/');
      if (includes.isNotEmpty && !includes.any((g) => g.matches(relative))) continue;
      if (excludes.any((g) => g.matches(relative))) continue;
      paths.add(entity.path);
    }

    return (paths.toList()..sort()).map(File.new).toList();
  }

  /// Parsed pages cached across dev rebuilds, keyed by source path.
  final _parseCache = <String, ({DateTime modified, Page page})>{};

  Future<List<Page>> _parsePages(List<File> files, String contentDir) async {
    if (config.devMode) return _parsePagesIncremental(files, contentDir);
    if (files.isEmpty) return [];

    final sources = <(String, String)>[];
    for (final file in files) {
      sources.add((file.path, await fileSystem.readFile(file.path)));
    }

    final chunkSize = (sources.length / Platform.numberOfProcessors).ceil();
    // captured locally so the isolate closure does not capture `this`
    final parseConfig = config;
    final outcomes = await Future.wait([
      for (final chunk in chunked(sources, chunkSize)) Isolate.run(() => _parseChunk(parseConfig, contentDir, chunk)),
    ]);

    final pages = <Page>[];
    for (final (page, draftSlug, error) in outcomes.expand((chunk) => chunk)) {
      if (draftSlug case final slug?) logger.log('⏭️  Skipping draft: $slug');
      if (error case final message?) logger.error(message);
      if (page case final page?) pages.add(page);
    }
    return pages;
  }

  /// Dev rebuilds re-parse only files whose mtime changed.
  Future<List<Page>> _parsePagesIncremental(List<File> files, String contentDir) async {
    final pages = <Page>[];
    final seen = <String>{};

    for (final file in files) {
      seen.add(file.path);
      final modified = await fileSystem.lastModified(file.path);
      if (_parseCache[file.path] case final cached? when cached.modified == modified) {
        pages.add(cached.page);
        continue;
      }

      final content = await fileSystem.readFile(file.path);
      final (page, draftSlug, error) = _parseSource(contentParser, contentDir, file.path, content);
      if (draftSlug case final slug?) logger.log('⏭️  Skipping draft: $slug');
      if (error case final message?) logger.error(message);
      if (page case final page?) {
        _parseCache[file.path] = (modified: modified, page: page);
        pages.add(page);
      } else {
        _parseCache.remove(file.path);
      }
    }

    _parseCache.removeWhere((path, _) => !seen.contains(path));
    return pages;
  }

  static List<(Page?, String?, String?)> _parseChunk(
      StardustConfig config, String contentDir, List<(String, String)> sources) {
    final parser = MarkdownParser(config: config);
    return [for (final (path, content) in sources) _parseSource(parser, contentDir, path, content)];
  }

  static (Page? page, String? draftSlug, String? error) _parseSource(
      ContentParser parser, String contentDir, String path, String content) {
    try {
      final slug = _pathToSlug(path, contentDir);
      final parsed = parser.parse(content, defaultTitle: _slugToTitle(slug));

      if (parsed.frontmatter['draft'] == true) return (null, slug, null);

      final redirectFrom = switch (parsed.frontmatter['redirect_from']) {
        final List list => list.whereType<String>().toList(),
        final String single => [single],
        _ => <String>[],
      };

      final page = Page(
        path: slug == 'index' ? '/' : '/$slug',
        sourcePath: path,
        title: parsed.title,
        description: parsed.description,
        content: parsed.html,
        toc: parsed.toc,
        frontmatter: parsed.frontmatter,
        redirectFrom: redirectFrom,
      );
      return (page, null, null);
    } catch (e) {
      return (null, null, '  ❌ Error parsing $path: $e');
    }
  }

  static String _pathToSlug(String filePath, String contentDir) {
    var relative = p.relative(filePath, from: contentDir);
    relative = p.withoutExtension(relative);
    relative = relative.replaceAll('\\', '/');
    return relative;
  }

  static String _slugToTitle(String slug) {
    if (slug == 'index') return 'Home';
    final name = p.basename(slug);
    return name
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  List<Page> _addNavigation(List<Page> pages) {
    final orderedPaths = <String>[];

    for (final group in config.sidebar) {
      for (final page in group.pages) {
        final path = page.slug == 'index' ? '/' : '/${page.slug}';
        orderedPaths.add(path);
      }
    }

    final sortedPages = List<Page>.from(pages);
    sortedPages.sort((a, b) {
      final aIndex = orderedPaths.indexOf(a.path);
      final bIndex = orderedPaths.indexOf(b.path);

      if (aIndex == -1 && bIndex == -1) {
        return a.path.compareTo(b.path);
      }
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });

    final result = <Page>[];
    for (var i = 0; i < sortedPages.length; i++) {
      final page = sortedPages[i];
      final prev = i > 0
          ? PageLink(
              path: sortedPages[i - 1].path,
              title: sortedPages[i - 1].title,
            )
          : null;
      final next = i < sortedPages.length - 1
          ? PageLink(
              path: sortedPages[i + 1].path,
              title: sortedPages[i + 1].title,
            )
          : null;

      result.add(Page(
        path: page.path,
        sourcePath: page.sourcePath,
        title: page.title,
        description: page.description,
        content: page.content,
        toc: page.toc,
        frontmatter: page.frontmatter,
        prev: prev,
        next: next,
        breadcrumbs: _buildBreadcrumbs(page.path),
        redirectFrom: page.redirectFrom,
      ));
    }

    return result;
  }

  List<PageLink> _buildBreadcrumbs(String path) {
    if (path == '/') return [];

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final breadcrumbs = <PageLink>[
      const PageLink(path: '/', title: 'Home'),
    ];

    var currentPath = '';
    for (var i = 0; i < parts.length - 1; i++) {
      currentPath += '/${parts[i]}';
      breadcrumbs.add(PageLink(
        path: currentPath,
        title: _slugToTitle(parts[i]),
      ));
    }

    return breadcrumbs;
  }

  Future<void> _generatePage(Page page) async {
    final html = pageBuilder.build(page, sidebar: config.sidebar);
    final outputPath = p.join(outputDir, page.outputPath);
    await fileSystem.writeFile(outputPath, html);
  }

  Future<void> _copyPublicAssets() async {
    if (!await fileSystem.directoryExists(config.build.assets.dir)) return;

    logger.log('📦 Copying public assets');

    await for (final entity in fileSystem.listDirectory(config.build.assets.dir, recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: config.build.assets.dir);
        final destPath = p.join(outputDir, relativePath);
        await fileSystem.copyFile(entity.path, destPath);
        logger.log('  📄 $relativePath');
      }
    }
  }

  Future<void> _generateSitemap(List<Page> pages) async {
    if (config.url == null) {
      logger.log('⏭️  Skipping sitemap.xml (no url configured)');
      return;
    }

    if (config.activeVersion case final active? when active.version != config.versions?.current) {
      logger.log('⏭️  Skipping sitemap.xml (noindex version ${active.version})');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

    final urls = UrlResolver(config);
    for (final page in pages) {
      final url = urls.absolute(page.path) ?? page.path;
      buffer.writeln('  <url>');
      buffer.writeln('    <loc>${encodeXml(url)}</loc>');

      if (await fileSystem.fileExists(page.sourcePath)) {
        final lastMod = await fileSystem.lastModified(page.sourcePath);
        final formatted =
            '${lastMod.year}-${lastMod.month.toString().padLeft(2, '0')}-${lastMod.day.toString().padLeft(2, '0')}';
        buffer.writeln('    <lastmod>$formatted</lastmod>');
      }

      buffer.writeln('    <changefreq>${encodeXml(config.build.sitemap.changefreq)}</changefreq>');
      buffer.writeln('    <priority>${config.build.sitemap.priority}</priority>');
      buffer.writeln('  </url>');
    }

    buffer.writeln('</urlset>');

    await fileSystem.writeFile(p.join(outputDir, 'sitemap.xml'), buffer.toString());
    logger.log('🗺️  Generated sitemap.xml');
  }

  Future<void> _generateRobots() async {
    final sitemapUrl = switch (config.url) {
      final url? when config.build.sitemap.enabled => '$url/sitemap.xml',
      _ => null,
    };
    await RobotsGenerator(
      outputDir: outputDir,
      robots: config.build.robots,
      sitemapUrl: sitemapUrl,
      logger: logger,
      fileSystem: fileSystem,
    ).generate();
  }

  Future<void> _generateLlms(List<Page> pages) async {
    final urls = UrlResolver(config);
    final buffer = StringBuffer();
    final visiblePages = pages.where((page) => page.frontmatter['llm'] != false).toList();
    final pagesByPath = {for (final page in visiblePages) page.path: page};

    buffer.writeln('# ${config.name}');
    buffer.writeln('');

    if (config.description case final desc?) {
      buffer.writeln('> $desc');
      buffer.writeln('');
    }

    if (config.url case final url?) {
      buffer.writeln('Website: $url');
      buffer.writeln('');
    }

    if (config.sidebar.isNotEmpty) {
      for (final group in config.sidebar) {
        buffer.writeln('## ${group.group}');
        buffer.writeln('');

        for (final sidebarPage in group.pages) {
          final path = sidebarPage.slug == 'index' ? '/' : '/${sidebarPage.slug}';
          if (pagesByPath[path] case final page?) {
            final title = sidebarPage.label ?? page.title;
            buffer.write('- [$title](${urls.absolute(path) ?? path})');
            if (page.description case final desc?) {
              buffer.write(': $desc');
            }
            buffer.writeln('');
          }
        }

        buffer.writeln('');
      }
    } else {
      buffer.writeln('## Pages');
      buffer.writeln('');

      for (final page in visiblePages) {
        buffer.write('- [${page.title}](${urls.absolute(page.path) ?? page.path})');
        if (page.description case final desc?) {
          buffer.write(': $desc');
        }
        buffer.writeln('');
      }
    }

    await fileSystem.writeFile(p.join(outputDir, 'llms.txt'), buffer.toString());
    logger.log('🤖 Generated llms.txt');
  }

  /// The raw page source served at `<path>.md`, so agents and the copy
  /// button can fetch clean markdown for any page.
  Future<void> _writePageMarkdown(Page page) async {
    if (page.frontmatter['llm'] == false) return;
    final source = await fileSystem.readFile(page.sourcePath);
    final target = page.path == '/' ? 'index.md' : '${page.path.substring(1)}.md';
    await fileSystem.writeFile(p.join(outputDir, target), source);
  }

  Future<void> _generateLlmsFull(List<Page> pages) async {
    final urls = UrlResolver(config);
    final buffer = StringBuffer();

    buffer.writeln('# ${config.name} — full documentation');
    if (config.description case final desc?) {
      buffer.writeln('\n> $desc');
    }

    for (final page in pages.where((page) => page.frontmatter['llm'] != false)) {
      final source = await fileSystem.readFile(page.sourcePath);
      buffer.writeln('\n---\n');
      buffer.writeln('## ${page.title}');
      buffer.writeln('\nURL: ${urls.absolute(page.path) ?? page.path}\n');
      buffer.writeln(FrontmatterParser.parse(source).content.trim());
    }

    await fileSystem.writeFile(p.join(outputDir, 'llms-full.txt'), buffer.toString());
    logger.log('🤖 Generated llms-full.txt');
  }

  Future<void> _generateRedirects(List<Page> pages) async {
    final hasConfigRedirects = config.build.redirects.isNotEmpty;
    final hasFrontmatterRedirects = pages.any((p) => p.redirectFrom.isNotEmpty);

    if (!hasConfigRedirects && !hasFrontmatterRedirects) return;

    final generator = RedirectGenerator(
      outputDir: outputDir,
      basePath: config.basePath,
      logger: logger,
      fileSystem: fileSystem,
    );

    await generator.generateAll(configRedirects: config.build.redirects, pages: pages);
  }
}
