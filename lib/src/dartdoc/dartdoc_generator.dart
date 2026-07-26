import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../core/file_system.dart';
import '../utils/exceptions.dart';
import '../utils/html_utils.dart';
import '../utils/logger.dart';

/// Runs `dart doc` on a package and co-hosts the API reference inside a Stardust
/// site: every page gets a self-contained Stardust top-bar, and dartdoc's
/// `<main>` content is tagged with `data-pagefind-body` so the site's search
/// indexes the API pages (unified search) once the output is copied into the
/// build (default `public/api/`).
class DartdocGenerator {
  final String packagePath;
  final String outputDir;
  final StardustConfig config;
  final Logger logger;
  final FileSystem fileSystem;

  DartdocGenerator({
    required this.packagePath,
    required this.outputDir,
    required this.config,
    this.logger = const Logger(),
    FileSystem? fileSystem,
  }) : fileSystem = fileSystem ?? const LocalFileSystem();

  /// Generates the API docs and returns the number of HTML pages written.
  Future<int> generate() async {
    final tmp = await Directory.systemTemp.createTemp('stardust-dartdoc-');
    try {
      logger.log('📚 Running `dart doc` on $packagePath');
      final ProcessResult result;
      try {
        result = await Process.run('dart', ['doc', '--output', tmp.path, '.'], workingDirectory: packagePath);
      } on ProcessException {
        throw const ContentException('`dart doc` is unavailable — is the Dart SDK installed and on your PATH?');
      }
      if (result.exitCode != 0) {
        throw ContentException('`dart doc` failed. Run `dart pub get` in the package first.\n${result.stderr}');
      }

      if (await fileSystem.directoryExists(outputDir)) {
        await fileSystem.deleteDirectory(outputDir, recursive: true);
      }
      final topBar = buildTopBar(config.name, homeHref(config));
      var pages = 0;
      await for (final entity in fileSystem.listDirectory(tmp.path, recursive: true)) {
        if (entity is! File) continue;
        final dest = p.join(outputDir, p.relative(entity.path, from: tmp.path));
        if (entity.path.endsWith('.html')) {
          await fileSystem.writeFile(dest, injectChrome(await fileSystem.readFile(entity.path), topBar));
          pages++;
        } else {
          await fileSystem.copyFile(entity.path, dest);
        }
      }
      logger.log('   ✓ Wrote $pages API pages to $outputDir');
      return pages;
    } finally {
      await tmp.delete(recursive: true);
    }
  }

  /// Inserts [topBar] right after the `<body>` tag and marks dartdoc's content
  /// column (`#dartdoc-main-content`) with `data-pagefind-body` so search
  /// indexes the API prose only — dartdoc's `<main>` also wraps the left/right
  /// nav sidebars, which would otherwise pollute every page's search entry.
  /// Both edits are no-ops when the target isn't present (search/404 pages).
  static String injectChrome(String html, String topBar) {
    final withBar = html.replaceFirstMapped(RegExp('<body[^>]*>'), (m) => '${m[0]}$topBar');
    return withBar.replaceFirst('id="dartdoc-main-content"', 'id="dartdoc-main-content" data-pagefind-body');
  }

  /// Root-relative docs home for the "Back to docs" link — respects a subpath
  /// deploy (`build.basePath` or a path in `url`) and stays host-relative so it
  /// works in local preview and production alike.
  static String homeHref(StardustConfig config) => config.basePath.isEmpty ? '/' : '${config.basePath}/';

  /// A self-contained (scoped-CSS) Stardust top-bar linking back to the docs
  /// home, safe to inject into dartdoc's independently-styled pages.
  static String buildTopBar(String name, String homeUrl) => '<div class="sd-apibar">'
      '<style>'
      '.sd-apibar{position:sticky;top:0;z-index:1000;display:flex;align-items:center;gap:.5rem;'
      'padding:.55rem 1rem;background:#0b1020;color:#e5e7eb;'
      'font:600 14px/1.2 system-ui,-apple-system,sans-serif;border-bottom:1px solid rgba(255,255,255,.12)}'
      '.sd-apibar a{color:#fff;text-decoration:none;margin-left:auto;opacity:.85}'
      '.sd-apibar a:hover{opacity:1}'
      '</style>'
      '<span>${encodeHtml(name)} · API reference</span>'
      '<a href="${encodeHtmlAttribute(homeUrl)}">← Back to docs</a>'
      '</div>';
}
