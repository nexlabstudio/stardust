import '../config/config.dart';
import '../models/page.dart';
import '../utils/html_utils.dart';
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

  /// Build a complete HTML page
  String build(Page page, {required List<SidebarGroup> sidebar}) {
    final seoTitle = config.seo.titleTemplate.replaceAll('%s', page.title);
    final basePath = UrlResolver(config).relativeRoot(page.path);
    final pagefindAttr = page.frontmatter['search'] == false ? '' : ' data-pagefind-body';
    final (cssQuery, jsQuery) = switch (assetVersions) {
      (:final css, :final js)? => ('?v=$css', '?v=$js'),
      null => ('', ''),
    };
    final markdownTwin = page.path == '/' ? 'index.md' : '${page.path.substring(1)}.md';
    final copyPageButton = config.build.llms.enabled && page.frontmatter['llm'] != false
        ? '''
        <div class="page-actions">
          <button class="copy-page-button" data-md-path="$basePath/$markdownTwin">Copy page as Markdown</button>
        </div>'''
        : '';

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
  ${scriptsBuilder.buildPagefindStyles(basePath)}
</head>
<body>
  <div class="layout">
    ${_layoutBuilder.buildHeader()}
    <div class="mobile-overlay" id="mobile-overlay"></div>
    <div class="main-container">
      ${_layoutBuilder.buildSidebar(sidebar, page.path)}
      <main class="content">
$copyPageButton
        <article class="prose"$pagefindAttr>
          ${page.content}
        </article>
        ${_layoutBuilder.buildEditLink(page)}
        ${_layoutBuilder.buildPageNav(page)}
      </main>
      ${_layoutBuilder.buildToc(page.toc)}
    </div>
    ${_layoutBuilder.buildFooter()}
  </div>
  ${scriptsBuilder.buildSearchModal(basePath)}
  <script src="$basePath/assets/app.js$jsQuery" defer></script>
</body>
</html>
''';
  }
}
