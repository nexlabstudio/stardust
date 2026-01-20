import '../config/config.dart';
import '../models/page.dart';
import 'builders/page_layout_builder.dart';
import 'builders/page_meta_builder.dart';
import 'builders/page_scripts_builder.dart';
import 'builders/page_styles_builder.dart';

/// Builds HTML pages from parsed content
class PageBuilder {
  final StardustConfig config;

  late final PageMetaBuilder _metaBuilder;
  late final PageStylesBuilder _stylesBuilder;
  late final PageLayoutBuilder _layoutBuilder;
  late final PageScriptsBuilder _scriptsBuilder;

  PageBuilder({required this.config}) {
    _metaBuilder = PageMetaBuilder(config: config);
    _stylesBuilder = PageStylesBuilder(config: config);
    _layoutBuilder = PageLayoutBuilder(config: config);
    _scriptsBuilder = PageScriptsBuilder(config: config);
  }

  String _getBasePath(String pagePath) {
    final segments = pagePath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '.';
    return List.filled(segments.length, '..').join('/');
  }

  String _buildFavicon(String basePath) {
    final favicon = config.favicon;
    if (favicon == null) return '';

    final href = '${config.basePath}$favicon';
    final ext = favicon.split('.').last.toLowerCase();

    final type = switch (ext) {
      'svg' => 'image/svg+xml',
      'png' => 'image/png',
      'ico' => 'image/x-icon',
      _ => 'image/x-icon',
    };

    return '<link rel="icon" type="$type" href="$href">';
  }

  /// Build a complete HTML page
  String build(Page page, {required List<SidebarGroup> sidebar}) {
    final seoTitle = config.seo.titleTemplate.replaceAll('%s', page.title);
    final basePath = _getBasePath(page.path);

    return '''
<!DOCTYPE html>
<html lang="en" class="dark-mode-${config.theme.darkMode.defaultMode}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$seoTitle</title>
  ${_buildFavicon(basePath)}
  ${_metaBuilder.build(page)}
  ${_stylesBuilder.buildFonts()}
  ${_stylesBuilder.buildStyles()}
  ${_scriptsBuilder.buildPagefindStyles(basePath)}
</head>
<body>
  <div class="layout">
    ${_layoutBuilder.buildHeader()}
    <div class="main-container">
      ${_layoutBuilder.buildSidebar(sidebar, page.path)}
      <main class="content">
        <article class="prose">
          ${page.content}
        </article>
        ${_layoutBuilder.buildEditLink(page)}
        ${_layoutBuilder.buildPageNav(page)}
      </main>
      ${_layoutBuilder.buildToc(page.toc)}
    </div>
    ${_layoutBuilder.buildFooter()}
  </div>
  ${_scriptsBuilder.buildSearchModal(basePath)}
  ${_scriptsBuilder.buildScripts()}
</body>
</html>
''';
  }
}
