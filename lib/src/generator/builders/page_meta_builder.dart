import '../../config/config.dart';
import '../../models/page.dart';
import '../../utils/html_utils.dart';

/// Builds meta tags, Open Graph, Twitter Cards, and JSON-LD structured data
class PageMetaBuilder {
  final StardustConfig config;

  PageMetaBuilder({required this.config});

  String buildFavicon() {
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

    return '<link rel="icon" type="$type" href="${encodeHtmlAttribute(href)}">';
  }

  String build(Page page) {
    final buffer = StringBuffer();

    if (config.url case final url?) {
      final baseUrl = _normalizeUrl(url);
      final pagePath = switch (page.path) { '/' => '', final p => p };
      buffer.writeln('  <link rel="canonical" href="${encodeHtmlAttribute('$baseUrl$pagePath')}">');
    }

    if (page.description case final description?) {
      buffer.writeln('  <meta name="description" content="${encodeHtml(description)}">');
    }

    buffer.writeln('  <meta property="og:title" content="${encodeHtml(page.title)}">');
    if (page.description case final description?) {
      buffer.writeln('  <meta property="og:description" content="${encodeHtml(description)}">');
    }
    buffer.writeln('  <meta property="og:type" content="article">');
    if (config.url case final url?) {
      final baseUrl = _normalizeUrl(url);
      final pagePath = switch (page.path) { '/' => '', final p => p };
      buffer.writeln('  <meta property="og:url" content="${encodeHtmlAttribute('$baseUrl$pagePath')}">');
    }
    final ogImage = _getOgImage(page);
    if (ogImage != null) {
      buffer.writeln('  <meta property="og:image" content="${encodeHtmlAttribute(ogImage)}">');
    }

    buffer.writeln('  <meta name="twitter:card" content="${config.seo.twitterCard}">');
    if (config.seo.twitterHandle case final handle?) {
      buffer.writeln('  <meta name="twitter:site" content="${encodeHtmlAttribute(handle)}">');
    }

    if (config.seo.structuredData) {
      buffer.writeln(_buildStructuredData(page));
    }

    buffer.write(_buildHreflangTags(page));

    return buffer.toString();
  }

  String _buildHreflangTags(Page page) {
    final i18n = config.i18n;
    if (i18n == null || !i18n.enabled || i18n.locales.isEmpty) return '';
    if (config.url == null) return '';

    final baseUrl = _normalizeUrl(config.url!);
    final pagePath = switch (page.path) { '/' => '/', final p => p };
    final buffer = StringBuffer();

    for (final locale in i18n.locales) {
      final localePath = locale.path.endsWith('/') ? locale.path.substring(0, locale.path.length - 1) : locale.path;
      buffer.writeln(
          '  <link rel="alternate" hreflang="${encodeHtmlAttribute(locale.code)}" href="${encodeHtmlAttribute('$baseUrl$localePath$pagePath')}">');
    }

    // x-default points to the default locale
    final defaultLocale = i18n.locales.where((l) => l.code == i18n.defaultLocale).firstOrNull;
    if (defaultLocale != null) {
      final defaultPath = defaultLocale.path.endsWith('/')
          ? defaultLocale.path.substring(0, defaultLocale.path.length - 1)
          : defaultLocale.path;
      buffer.writeln(
          '  <link rel="alternate" hreflang="x-default" href="${encodeHtmlAttribute('$baseUrl$defaultPath$pagePath')}">');
    }

    return buffer.toString();
  }

  String _buildStructuredData(Page page) {
    final buffer = StringBuffer();

    if (config.url case final url?) {
      final baseUrl = _normalizeUrl(url);
      final pagePath = switch (page.path) { '/' => '', final p => p };
      final pageUrl = '$baseUrl$pagePath';

      buffer.writeln(_buildArticleSchema(page, pageUrl));

      if (page.breadcrumbs.isNotEmpty) {
        buffer.writeln(_buildBreadcrumbSchema(page, baseUrl, pageUrl));
      }

      if (page.path == '/') {
        buffer.writeln(_buildWebsiteSchema(baseUrl));
      }
    }

    return buffer.toString();
  }

  String _buildArticleSchema(Page page, String pageUrl) {
    final json = StringBuffer()
      ..write('{"@context":"https://schema.org"')
      ..write(',"@type":"Article"')
      ..write(',"headline":"${_escapeJson(page.title)}"')
      ..write(',"url":"${_escapeJson(pageUrl)}"');

    if (page.description case final desc?) {
      json.write(',"description":"${_escapeJson(desc)}"');
    }

    if (_getOgImage(page) case final image?) {
      json.write(',"image":"${_escapeJson(image)}"');
    }

    json
      ..write(',"publisher":{"@type":"Organization","name":"${_escapeJson(config.name)}"')
      ..write('}')
      ..write('}');

    return '  <script type="application/ld+json">${json.toString()}</script>';
  }

  String _buildBreadcrumbSchema(Page page, String baseUrl, String pageUrl) {
    final json = StringBuffer()
      ..write('{"@context":"https://schema.org"')
      ..write(',"@type":"BreadcrumbList"')
      ..write(',"itemListElement":[');

    final items = <String>[];
    for (final (index, crumb) in page.breadcrumbs.indexed) {
      final crumbUrl = '$baseUrl${crumb.path}';
      items.add(
          '{"@type":"ListItem","position":${index + 1},"name":"${_escapeJson(crumb.title)}","item":"${_escapeJson(crumbUrl)}"}');
    }
    items.add(
        '{"@type":"ListItem","position":${page.breadcrumbs.length + 1},"name":"${_escapeJson(page.title)}","item":"${_escapeJson(pageUrl)}"}');

    json
      ..write(items.join(','))
      ..write(']}');

    return '  <script type="application/ld+json">${json.toString()}</script>';
  }

  String _buildWebsiteSchema(String baseUrl) {
    final json = StringBuffer()
      ..write('{"@context":"https://schema.org"')
      ..write(',"@type":"WebSite"')
      ..write(',"name":"${_escapeJson(config.name)}"')
      ..write(',"url":"${_escapeJson(baseUrl)}"');

    if (config.description case final desc?) {
      json.write(',"description":"${_escapeJson(desc)}"');
    }

    json.write('}');

    return '  <script type="application/ld+json">${json.toString()}</script>';
  }

  String? _getOgImage(Page page) {
    if (page.frontmatter['ogImage'] case final String image?) {
      return image;
    }

    if (config.seo.ogImage case final ogImage?) {
      return ogImage;
    }

    if (config.url case final url?) {
      final baseUrl = _normalizeUrl(url);
      final fileName = _pagePathToOgFileName(page.path);
      return '$baseUrl${config.basePath}/images/og/$fileName';
    }

    return null;
  }

  String _pagePathToOgFileName(String path) {
    if (path == '/') return 'index.png';
    final slug = path.substring(1).replaceAll('/', '-');
    return '$slug.png';
  }

  String _normalizeUrl(String url) => switch (url) {
        final u when u.endsWith('/') => u.substring(0, u.length - 1),
        _ => url,
      };

  String _escapeJson(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t')
      .replaceAll('<', '\\u003C');
}
