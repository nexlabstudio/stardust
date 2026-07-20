import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../content/markdown_parser.dart';
import '../core/file_system.dart';
import '../core/interfaces.dart';
import '../utils/html_utils.dart';
import '../utils/text_utils.dart';

/// A problem found by [SiteChecker].
class CheckIssue {
  final String source;
  final String message;
  final bool isWarning;

  const CheckIssue(this.source, this.message, {this.isWarning = false});
}

/// Validates internal links, anchors, images, sidebar entries, and slug
/// collisions across the whole content set, without producing output.
class SiteChecker {
  final StardustConfig config;
  final FileSystem fileSystem;
  final ContentParser contentParser;

  SiteChecker({
    required this.config,
    FileSystem? fileSystem,
    ContentParser? contentParser,
  })  : fileSystem = fileSystem ?? const LocalFileSystem(),
        contentParser = contentParser ?? MarkdownParser(config: config);

  static final _linkPattern = RegExp('<a[^>]+href="([^"]*)"', caseSensitive: false);
  static final _imgPattern = RegExp('<img[^>]+src="([^"]*)"', caseSensitive: false);
  static final _headingIdPattern = RegExp('<h[1-6][^>]+id="([^"]+)"', caseSensitive: false);

  Future<List<CheckIssue>> check(String contentDir) async {
    final issues = <CheckIssue>[];

    // Links can target any page, so index every page before validating any.
    final pages = <({String path, String source, String html, bool validate})>[];
    final pathToSource = <String, String>{};
    final anchorsByPath = <String, Set<String>>{};

    for (final file in await _findMarkdownFiles(contentDir)) {
      final slug = _pathToSlug(file, contentDir);
      final path = slug == 'index' ? '/' : '/$slug';
      if (pathToSource[path] case final existing?) {
        issues.add(CheckIssue(file, 'duplicate page path "$path" (also produced by $existing)'));
        continue;
      }
      final parsed = contentParser.parse(await fileSystem.readFile(file));
      pathToSource[path] = file;
      anchorsByPath[path] = _headingIdPattern.allMatches(parsed.html).map((m) => m.group(1) ?? '').toSet();
      pages.add((path: path, source: file, html: parsed.html, validate: parsed.frontmatter['check'] != false));
    }

    final pagePaths = pathToSource.keys.toSet();

    for (final page in pages) {
      if (!page.validate) continue;
      for (final match in _linkPattern.allMatches(page.html)) {
        _checkLink(match.group(1) ?? '', page, pagePaths, anchorsByPath, issues);
      }
      for (final match in _imgPattern.allMatches(page.html)) {
        await _checkImage(match.group(1) ?? '', page.source, issues);
      }
    }

    _checkSidebar(pagePaths, issues);
    return issues;
  }

  void _checkLink(
    String href,
    ({String path, String source, String html, bool validate}) page,
    Set<String> pagePaths,
    Map<String, Set<String>> anchorsByPath,
    List<CheckIssue> issues,
  ) {
    if (href.isEmpty || !isSafeUrl(href)) return;
    if (href.startsWith('http') || href.startsWith('//') || href.startsWith('mailto:') || href.startsWith('tel:')) {
      return;
    }

    final (target, anchor) = switch (href.split('#')) {
      [final t, final a] => (t, a),
      _ => (href, null),
    };

    if (target.isEmpty) {
      if (anchor != null && !(anchorsByPath[page.path]?.contains(anchor) ?? false)) {
        issues.add(CheckIssue(page.source, 'link to missing anchor "#$anchor" on this page'));
      }
      return;
    }

    final normalized = _normalizePath(target);
    if (!pagePaths.contains(normalized)) {
      final hint = switch (closestMatch(normalized, pagePaths)) {
        final suggestion? => ' (did you mean $suggestion?)',
        null => '',
      };
      issues.add(CheckIssue(page.source, 'broken link -> $target$hint'));
      return;
    }

    if (anchor != null && !(anchorsByPath[normalized]?.contains(anchor) ?? false)) {
      issues.add(CheckIssue(page.source, 'link to missing anchor -> $target#$anchor'));
    }
  }

  Future<void> _checkImage(String src, String source, List<CheckIssue> issues) async {
    if (src.isEmpty || src.startsWith('http') || src.startsWith('//') || src.startsWith('data:')) return;
    if (!src.startsWith('/')) return;

    final assetPath = p.join(config.build.assets.dir, src.substring(1));
    if (!await fileSystem.fileExists(assetPath)) {
      issues.add(CheckIssue(source, 'missing image -> $src'));
    }
  }

  void _checkSidebar(Set<String> pagePaths, List<CheckIssue> issues) {
    for (final group in config.sidebar) {
      for (final sidebarPage in group.pages) {
        final path = sidebarPage.slug == 'index' ? '/' : '/${sidebarPage.slug}';
        if (!pagePaths.contains(path)) {
          issues.add(CheckIssue(
            'stardust.yaml',
            'sidebar entry "${sidebarPage.slug}" in group "${group.group}" has no matching page',
            isWarning: true,
          ));
        }
      }
    }
  }

  String _normalizePath(String path) {
    var result = path;
    if (result.endsWith('.html')) result = result.substring(0, result.length - 5);
    if (result.endsWith('/index')) result = result.substring(0, result.length - 6);
    if (result.length > 1 && result.endsWith('/')) result = result.substring(0, result.length - 1);
    return result.isEmpty ? '/' : result;
  }

  Future<List<String>> _findMarkdownFiles(String contentDir) async {
    final includes = config.content.include.map(Glob.new).toList();
    final excludes = config.content.exclude.map(Glob.new).toList();
    final found = <String>{};

    await for (final entity in fileSystem.listDirectory(contentDir, recursive: true)) {
      final path = entity.path;
      if (!path.endsWith('.md') && !path.endsWith('.mdx')) continue;
      final relative = p.relative(path, from: contentDir).replaceAll('\\', '/');
      if (includes.isNotEmpty && !includes.any((g) => g.matches(relative))) continue;
      if (excludes.any((g) => g.matches(relative))) continue;
      found.add(path);
    }

    return found.toList()..sort();
  }

  String _pathToSlug(String filePath, String contentDir) =>
      p.withoutExtension(p.relative(filePath, from: contentDir)).replaceAll('\\', '/');
}
