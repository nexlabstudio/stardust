import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../content/markdown_parser.dart';
import '../models/page.dart';
import '../utils/exceptions.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import 'page_builder.dart';

/// Generates static documentation site
class SiteGenerator {
  final StardustConfig config;
  final String outputDir;
  final Logger logger;

  late final MarkdownParser _markdownParser;
  late final PageBuilder _pageBuilder;

  SiteGenerator({
    required this.config,
    required this.outputDir,
    this.logger = const Logger(),
  }) {
    _markdownParser = MarkdownParser(config: config);
    _pageBuilder = PageBuilder(config: config);
  }

  /// Generate the static site, returns number of pages generated
  Future<int> generate() async {
    final contentDir = p.join(Directory.current.path, config.content.dir);
    final files = await _findMarkdownFiles(contentDir);

    logger.log('📄 Found ${files.length} markdown files');

    final pages = <Page>[];
    final pagesBySlug = <String, Page>{};

    for (final file in files) {
      final page = await _parsePage(file, contentDir);
      if (page != null) {
        pages.add(page);
        final slug = _pathToSlug(file.path, contentDir);
        pagesBySlug[slug] = page;
      }
    }

    final pagesWithNav = _addNavigation(pages);

    var count = 0;
    for (final page in pagesWithNav) {
      await _generatePage(page);
      count++;
      logger.log('  ✅ ${page.path}');
    }

    await _copyPublicAssets();

    if (config.build.sitemap.enabled) {
      await _generateSitemap(pagesWithNav);
    }

    if (config.build.robots.enabled) {
      await _generateRobots();
    }

    if (config.build.llms.enabled) {
      await _generateLlms(pagesWithNav);
    }

    return count;
  }

  Future<List<File>> _findMarkdownFiles(String contentDir) async {
    if (!FileUtils.directoryExists(contentDir)) {
      throw GeneratorException('Content directory not found: $contentDir');
    }

    final paths = <String>{};

    for (final pattern in config.content.include) {
      final glob = Glob(pattern);
      await for (final entity in glob.list(root: contentDir)) {
        if (entity case final File file) {
          final relativePath = p.relative(file.path, from: contentDir);

          var excluded = false;
          for (final excludePattern in config.content.exclude) {
            if (Glob(excludePattern).matches(relativePath)) {
              excluded = true;
              break;
            }
          }

          if (!excluded) {
            paths.add(file.path);
          }
        }
      }
    }

    return (paths.toList()..sort()).map(File.new).toList();
  }

  Future<Page?> _parsePage(File file, String contentDir) async {
    try {
      final content = await file.readAsString();
      final slug = _pathToSlug(file.path, contentDir);
      final defaultTitle = _slugToTitle(slug);

      final parsed = _markdownParser.parse(content, defaultTitle: defaultTitle);

      if (parsed.frontmatter['draft'] == true) {
        logger.log('⏭️  Skipping draft: $slug');
        return null;
      }

      final pagePath = slug == 'index' ? '/' : '/$slug';

      return Page(
        path: pagePath,
        sourcePath: file.path,
        title: parsed.title,
        description: parsed.description,
        content: parsed.html,
        toc: parsed.toc,
        frontmatter: parsed.frontmatter,
      );
    } catch (e) {
      logger.error('  ❌ Error parsing ${file.path}: $e');
      return null;
    }
  }

  String _pathToSlug(String filePath, String contentDir) {
    var relative = p.relative(filePath, from: contentDir);
    relative = p.withoutExtension(relative);
    relative = relative.replaceAll('\\', '/');
    return relative;
  }

  String _slugToTitle(String slug) {
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
    final html = _pageBuilder.build(page, sidebar: config.sidebar);
    final outputPath = p.join(outputDir, page.outputPath);
    await FileUtils.writeFile(outputPath, html);
  }

  Future<void> _copyPublicAssets() async {
    final publicDir = Directory(config.build.assets.dir);
    if (!FileUtils.directoryExists(config.build.assets.dir)) return;

    logger.log('📦 Copying public assets');

    await for (final entity in publicDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: publicDir.path);
        final destPath = p.join(outputDir, relativePath);
        await FileUtils.copyFile(entity.path, destPath);
        logger.log('  📄 $relativePath');
      }
    }
  }

  Future<void> _generateSitemap(List<Page> pages) async {
    if (config.url == null) {
      logger.log('⏭️  Skipping sitemap.xml (no url configured)');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

    for (final page in pages) {
      final url = '${config.url}${page.path}';
      buffer.writeln('  <url>');
      buffer.writeln('    <loc>$url</loc>');

      if (FileUtils.fileExists(page.sourcePath)) {
        final lastMod = File(page.sourcePath).lastModifiedSync();
        final formatted =
            '${lastMod.year}-${lastMod.month.toString().padLeft(2, '0')}-${lastMod.day.toString().padLeft(2, '0')}';
        buffer.writeln('    <lastmod>$formatted</lastmod>');
      }

      buffer.writeln('    <changefreq>${config.build.sitemap.changefreq}</changefreq>');
      buffer.writeln('    <priority>${config.build.sitemap.priority}</priority>');
      buffer.writeln('  </url>');
    }

    buffer.writeln('</urlset>');

    await FileUtils.writeFile(p.join(outputDir, 'sitemap.xml'), buffer.toString());
    logger.log('🗺️  Generated sitemap.xml');
  }

  Future<void> _generateRobots() async {
    final buffer = StringBuffer();
    buffer.writeln('User-agent: *');

    for (final path in config.build.robots.allow) {
      buffer.writeln('Allow: $path');
    }

    for (final path in config.build.robots.disallow) {
      buffer.writeln('Disallow: $path');
    }

    if (config.url != null && config.build.sitemap.enabled) {
      buffer.writeln('');
      buffer.writeln('Sitemap: ${config.url}/sitemap.xml');
    }

    await FileUtils.writeFile(p.join(outputDir, 'robots.txt'), buffer.toString());
    logger.log('🤖 Generated robots.txt');
  }

  Future<void> _generateLlms(List<Page> pages) async {
    final buffer = StringBuffer();
    final pagesByPath = {for (final page in pages) page.path: page};

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
            buffer.write('- [$title]($path)');
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

      for (final page in pages) {
        buffer.write('- [${page.title}](${page.path})');
        if (page.description case final desc?) {
          buffer.write(': $desc');
        }
        buffer.writeln('');
      }
    }

    await FileUtils.writeFile(p.join(outputDir, 'llms.txt'), buffer.toString());
    logger.log('🤖 Generated llms.txt');
  }
}
