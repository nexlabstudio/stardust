import '../config/config.dart';
import '../models/page.dart';
import '../utils/html_utils.dart';
import '../utils/patterns.dart';
import 'builders/page_analytics_builder.dart';
import 'builders/page_layout_builder.dart';
import 'builders/page_meta_builder.dart';
import 'builders/page_scripts_builder.dart';
import 'builders/page_styles_builder.dart';
import 'url_resolver.dart';

/// Builds HTML pages from parsed content
class PageBuilder {
  final StardustConfig config;

  late final PageMetaBuilder _metaBuilder;
  late final PageStylesBuilder stylesBuilder;
  late final PageLayoutBuilder _layoutBuilder;
  late final PageScriptsBuilder scriptsBuilder;
  late final PageAnalyticsBuilder _analyticsBuilder;

  /// Content hashes for the shared assets, set by the site generator after
  /// writing assets/styles.css and assets/app.js; used for cache busting.
  ({String css, String js})? assetVersions;

  PageBuilder({required this.config}) {
    _metaBuilder = PageMetaBuilder(config: config);
    stylesBuilder = PageStylesBuilder(config: config);
    _layoutBuilder = PageLayoutBuilder(config: config);
    scriptsBuilder = PageScriptsBuilder(config: config);
    _analyticsBuilder = PageAnalyticsBuilder(analytics: config.integrations.analytics);
  }

  /// Site-absolute links and images written in markdown get the base path
  /// applied, so content works on subpath deploys. Code samples are immune:
  /// their attributes are already HTML-escaped.
  String _prefixContentPaths(String content) => switch (config.basePath) {
        '' => content,
        final basePath => content.replaceAllMapped(
            rootRelativeAttrPattern,
            (match) => '${match.group(1)}="$basePath/',
          ),
      };

  /// Build a complete HTML page
  String build(Page page, {required List<SidebarGroup> sidebar}) {
    final seoTitle = config.seo.titleTemplate.replaceAll('%s', page.title);
    final basePath = UrlResolver(config).relativeRoot(page.path);
    final pagefindAttr = page.frontmatter['search'] == false ? '' : ' data-pagefind-body';
    final (cssQuery, jsQuery) = switch (assetVersions) {
      (:final css, :final js)? => ('?v=$css', '?v=$js'),
      null => ('', ''),
    };
    final body = page.frontmatter['layout'] == 'splash'
        ? _splashBody(page, pagefindAttr)
        : _docsBody(page, sidebar, basePath, pagefindAttr);

    return '''
<!DOCTYPE html>
<html lang="${config.lang}" dir="${config.dir}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${encodeHtml(seoTitle)}</title>
  ${scriptsBuilder.buildThemeInit()}
  ${_metaBuilder.buildFavicon()}
  ${_metaBuilder.build(page)}
  ${_analyticsBuilder.build()}
  ${stylesBuilder.buildFonts()}
  <link rel="stylesheet" href="$basePath/assets/styles.css$cssQuery">
</head>
<body>
  <div class="layout">
    ${_layoutBuilder.buildHeader(page.path)}
    $body
    ${_layoutBuilder.buildFooter()}
  </div>
  ${scriptsBuilder.buildSearchModal(basePath)}
  <script src="$basePath/assets/app.js$jsQuery" defer></script>
</body>
</html>
''';
  }

  String _docsBody(Page page, List<SidebarGroup> sidebar, String basePath, String pagefindAttr) {
    final markdownTwin = page.path == '/' ? 'index.md' : '${page.path.substring(1)}.md';
    final copyPageButton = config.build.llms.enabled && page.frontmatter['llm'] != false
        ? '''
        <div class="page-actions">
          <button class="copy-page-button" data-md-path="$basePath/$markdownTwin">Copy page as Markdown</button>
        </div>'''
        : '';

    return '''
    <div class="mobile-overlay" id="mobile-overlay"></div>
    <div class="main-container">
      ${_layoutBuilder.buildSidebar(sidebar, page.path)}
      <main class="content">
$copyPageButton
        <article class="prose"$pagefindAttr>
          ${_prefixContentPaths(page.content)}
        </article>
        ${_layoutBuilder.buildEditLink(page)}
        ${_layoutBuilder.buildPageNav(page)}
      </main>
      ${_layoutBuilder.buildToc(page.toc)}
    </div>''';
  }

  String _splashBody(Page page, String pagefindAttr) => '''
    ${_buildHero(page)}
    <main class="splash">
      <article class="prose"$pagefindAttr>
        ${_prefixContentPaths(page.content)}
      </article>
    </main>''';

  /// Renders the frontmatter `hero` on a splash page. Absent or malformed hero
  /// data degrades to no hero rather than throwing.
  String _buildHero(Page page) {
    if (page.frontmatter['hero'] is! Map) return '';
    final hero = page.frontmatter['hero'] as Map;

    final title = switch (hero['title']) { final String t => t, _ => page.title };
    final image = switch (hero['image']) { final String s when s.isNotEmpty => _heroImage(s, title), _ => '' };
    final tagline = switch (hero['tagline']) {
      final String t => '<p class="hero-tagline">${encodeHtml(t)}</p>',
      _ => '',
    };
    final actions = switch (hero['actions']) {
      final List list => list.map(_heroAction).whereType<String>().join('\n        '),
      _ => '',
    };

    return '''
    <section class="hero">
      <div class="hero-inner">
        $image
        <h1 class="hero-title">${encodeHtml(title)}</h1>
        $tagline
        <div class="hero-actions">
        $actions
        </div>
      </div>
    </section>''';
  }

  String _heroImage(String src, String alt) {
    final url = src.startsWith('http') || src.startsWith('data:') ? src : UrlResolver(config).href(src);
    return '<img class="hero-image" src="${encodeHtmlAttribute(sanitizeUrl(url))}" alt="${encodeHtmlAttribute(alt)}">';
  }

  String? _heroAction(Object? action) {
    if (action is! Map) return null;
    final (label, href) = switch ((action['label'], action['href'])) {
      (final String label, final String href) => (label, href),
      _ => (null, null),
    };
    if (label == null || href == null) return null;

    final external = action['external'] == true;
    final variant = action['variant'] == 'primary' ? 'primary' : 'secondary';
    final url = sanitizeUrl(external ? href : UrlResolver(config).href(href));
    final externalAttrs = external ? ' target="_blank" rel="noopener"' : '';

    return '<a class="hero-action hero-action--$variant" '
        'href="${encodeHtmlAttribute(url)}"$externalAttrs>${encodeHtml(label)}</a>';
  }
}
