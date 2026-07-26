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
      final topBar = buildTopBar(
        name: config.name,
        homeUrl: homeHref(config),
        primaryColor: config.theme.colors.primary,
        logoLight: _prefixAsset(config.logo?.effectiveLight, config.basePath),
        logoDark: _prefixAsset(config.logo?.effectiveDark, config.basePath),
      );
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

  /// Right after `<body>`, injects a theme-sync script (mirrors the site's saved
  /// theme onto dartdoc's, two-way) and the [topBar]; and marks dartdoc's content
  /// column (`#dartdoc-main-content`) with `data-pagefind-body` so search indexes
  /// the API prose only — dartdoc's `<main>` also wraps the left/right nav
  /// sidebars. Each edit is a no-op when its target is absent (search/404 pages).
  static String injectChrome(String html, String topBar) {
    final chrome = '$_themeSync$topBar';
    final withChrome = html.replaceFirstMapped(RegExp('<body[^>]*>'), (m) => '${m[0]}$chrome');
    return withChrome.replaceFirst('id="dartdoc-main-content"', 'id="dartdoc-main-content" data-pagefind-body');
  }

  /// Runs before dartdoc's own theme init: reads the site's saved theme
  /// (`localStorage['theme']`), applies the matching dartdoc theme immediately
  /// (no flash) and stores dartdoc's `colorTheme`, then observes dartdoc's own
  /// toggle to write the site key back — so the two themes stay in lockstep.
  static const _themeSync = '<script>(function(){'
      'function d(){try{var t=localStorage.getItem("theme");'
      'if(t==="dark")return true;if(t==="light")return false;}catch(e){}'
      'return matchMedia("(prefers-color-scheme: dark)").matches;}'
      'var k=d();try{localStorage.setItem("colorTheme",k?"true":"false");}catch(e){}'
      'var b=document.body;b.classList.remove("light-theme","dark-theme");'
      'b.classList.add(k?"dark-theme":"light-theme");'
      'try{new MutationObserver(function(){var x=b.classList.contains("dark-theme");'
      'try{localStorage.setItem("theme",x?"dark":"light");}catch(e){}})'
      '.observe(b,{attributes:true,attributeFilter:["class"]});}catch(e){}'
      '})();</script>';

  /// Root-relative docs home for the "Back to docs" link — respects a subpath
  /// deploy (`build.basePath` or a path in `url`) and stays host-relative so it
  /// works in local preview and production alike.
  static String homeHref(StardustConfig config) => config.basePath.isEmpty ? '/' : '${config.basePath}/';

  /// A self-contained, theme-aware Stardust top-bar (logo + name + API badge,
  /// linking home) safe to inject into dartdoc's independently-styled pages.
  /// It is static, not sticky, so it never collides with dartdoc's
  /// fixed-on-scroll header, and it adapts to dartdoc's `light-theme`/
  /// `dark-theme` body class. [primaryColor] is sanitized for CSS.
  static String buildTopBar({
    required String name,
    required String homeUrl,
    required String primaryColor,
    String? logoLight,
    String? logoDark,
  }) {
    final accent = _safeColor(primaryColor, '#6366f1');
    final home = encodeHtmlAttribute(homeUrl);
    return '<div class="sd-apibar">'
        '<style>'
        '.sd-apibar{display:flex;align-items:center;gap:.55rem;padding:.5rem 1rem;'
        'font:600 14px/1.2 system-ui,-apple-system,BlinkMacSystemFont,sans-serif;'
        'background:#fff;color:#1a1a1a;border-bottom:1px solid rgba(0,0,0,.08)}'
        '.dark-theme .sd-apibar{background:#0d1117;color:#e6edf3;border-bottom-color:rgba(255,255,255,.1)}'
        '.sd-apibar__brand{display:flex;align-items:center;gap:.5rem;color:inherit;text-decoration:none;font-weight:700}'
        '.sd-apibar__brand img{height:22px;width:auto;display:block}'
        '.sd-apibar__badge{padding:.1rem .4rem;border-radius:5px;font-size:11px;font-weight:700;'
        'letter-spacing:.03em;background:$accent;color:#fff}'
        '.sd-apibar__home{margin-left:auto;color:inherit;text-decoration:none;font-weight:500;opacity:.7}'
        '.sd-apibar__home:hover{opacity:1;color:$accent}'
        '.sd-logo-dark{display:none}.dark-theme .sd-logo-light{display:none}.dark-theme .sd-logo-dark{display:block}'
        '</style>'
        '<a class="sd-apibar__brand" href="$home">${_logoImages(logoLight, logoDark)}'
        '<span>${encodeHtml(name)}</span><span class="sd-apibar__badge">API</span></a>'
        '<a class="sd-apibar__home" href="$home">← Back to docs</a>'
        '</div>';
  }

  static String _logoImages(String? light, String? dark) {
    if (light != null && dark != null && light != dark) {
      return '<img class="sd-logo-light" src="${encodeHtmlAttribute(light)}" alt="">'
          '<img class="sd-logo-dark" src="${encodeHtmlAttribute(dark)}" alt="">';
    }
    if (light != null) return '<img src="${encodeHtmlAttribute(light)}" alt="">';
    return '';
  }

  static String? _prefixAsset(String? path, String basePath) =>
      path == null ? null : (path.startsWith('/') ? '$basePath$path' : path);

  /// Accepts only a hex color or a plain named color, else [fallback] — so a
  /// hostile `theme.colors.primary` can't break out of the CSS value.
  static String _safeColor(String value, String fallback) {
    final v = value.trim();
    return RegExp(r'^#[0-9a-fA-F]{3,8}$').hasMatch(v) || RegExp(r'^[a-zA-Z]+$').hasMatch(v) ? v : fallback;
  }
}
