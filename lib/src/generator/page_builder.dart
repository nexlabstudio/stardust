import '../config/config.dart';
import '../content/markdown_parser.dart';
import '../models/page.dart';

/// Builds HTML pages from parsed content
class PageBuilder {
  final StardustConfig config;

  PageBuilder({required this.config});

  String _getBasePath(String pagePath) {
    final segments = pagePath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '.';
    return List.filled(segments.length, '..').join('/');
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
  ${_buildMeta(page)}
  ${_buildFonts()}
  ${_buildStyles()}
  ${_buildPagefindStyles(basePath)}
</head>
<body>
  <div class="layout">
    ${_buildHeader()}
    <div class="main-container">
      ${_buildSidebar(sidebar, page.path)}
      <main class="content">
        <article class="prose">
          ${page.content}
        </article>
        ${_buildEditLink(page)}
        ${_buildPageNav(page)}
      </main>
      ${_buildToc(page.toc)}
    </div>
    ${_buildFooter()}
  </div>
  ${_buildSearchModal(basePath)}
  ${_buildScripts()}
</body>
</html>
''';
  }

  String _buildMeta(Page page) {
    final buffer = StringBuffer();

    if (config.url case final url?) {
      final baseUrl = switch (url) {
        final u when u.endsWith('/') => u.substring(0, u.length - 1),
        _ => url,
      };
      final pagePath = switch (page.path) { '/' => '', final p => p };
      buffer.writeln('  <link rel="canonical" href="$baseUrl$pagePath">');
    }

    if (page.description case final description?) {
      buffer.writeln('  <meta name="description" content="${_escapeHtml(description)}">');
    }

    buffer.writeln('  <meta property="og:title" content="${_escapeHtml(page.title)}">');
    if (page.description case final description?) {
      buffer.writeln('  <meta property="og:description" content="${_escapeHtml(description)}">');
    }
    buffer.writeln('  <meta property="og:type" content="article">');
    if (config.url case final url?) {
      final baseUrl = switch (url) {
        final u when u.endsWith('/') => u.substring(0, u.length - 1),
        _ => url,
      };
      final pagePath = switch (page.path) { '/' => '', final p => p };
      buffer.writeln('  <meta property="og:url" content="$baseUrl$pagePath">');
    }
    if (config.seo.ogImage case final ogImage?) {
      buffer.writeln('  <meta property="og:image" content="$ogImage">');
    }

    buffer.writeln('  <meta name="twitter:card" content="${config.seo.twitterCard}">');
    if (config.seo.twitterHandle case final handle?) {
      buffer.writeln('  <meta name="twitter:site" content="$handle">');
    }

    if (config.seo.structuredData) {
      buffer.writeln(_buildStructuredData(page));
    }

    return buffer.toString();
  }

  String _buildStructuredData(Page page) {
    final buffer = StringBuffer();

    if (config.url case final url?) {
      final baseUrl = switch (url) {
        final u when u.endsWith('/') => u.substring(0, u.length - 1),
        _ => url,
      };
      final pagePath = switch (page.path) { '/' => '', final p => p };
      final pageUrl = '$baseUrl$pagePath';

      final articleJson = StringBuffer()
        ..write('{"@context":"https://schema.org"')
        ..write(',"@type":"Article"')
        ..write(',"headline":"${_escapeJson(page.title)}"')
        ..write(',"url":"$pageUrl"');

      if (page.description case final desc?) {
        articleJson.write(',"description":"${_escapeJson(desc)}"');
      }

      if (config.seo.ogImage case final image?) {
        articleJson.write(',"image":"$image"');
      }

      articleJson
        ..write(',"publisher":{"@type":"Organization","name":"${_escapeJson(config.name)}"')
        ..write('}')
        ..write('}');

      buffer.writeln('  <script type="application/ld+json">${articleJson.toString()}</script>');

      if (page.breadcrumbs.isNotEmpty) {
        final breadcrumbJson = StringBuffer()
          ..write('{"@context":"https://schema.org"')
          ..write(',"@type":"BreadcrumbList"')
          ..write(',"itemListElement":[');

        final items = <String>[];
        for (final (index, crumb) in page.breadcrumbs.indexed) {
          final crumbUrl = '$baseUrl${crumb.path}';
          items.add(
              '{"@type":"ListItem","position":${index + 1},"name":"${_escapeJson(crumb.title)}","item":"$crumbUrl"}');
        }
        items.add(
            '{"@type":"ListItem","position":${page.breadcrumbs.length + 1},"name":"${_escapeJson(page.title)}","item":"$pageUrl"}');

        breadcrumbJson
          ..write(items.join(','))
          ..write(']}');

        buffer.writeln('  <script type="application/ld+json">${breadcrumbJson.toString()}</script>');
      }

      if (page.path == '/') {
        final websiteJson = StringBuffer()
          ..write('{"@context":"https://schema.org"')
          ..write(',"@type":"WebSite"')
          ..write(',"name":"${_escapeJson(config.name)}"')
          ..write(',"url":"$baseUrl"');

        if (config.description case final desc?) {
          websiteJson.write(',"description":"${_escapeJson(desc)}"');
        }

        websiteJson.write('}');

        buffer.writeln('  <script type="application/ld+json">${websiteJson.toString()}</script>');
      }
    }

    return buffer.toString();
  }

  String _escapeJson(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');

  String _buildFonts() {
    final sans = config.theme.fonts.sans;
    final mono = config.theme.fonts.mono;

    return '''
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=${sans.replaceAll(' ', '+')}:wght@400;500;600;700&family=${mono.replaceAll(' ', '+')}:wght@400;500&display=swap" rel="stylesheet">
''';
  }

  String _buildStyles() {
    final primary = config.theme.colors.primary;
    final bgLight = config.theme.colors.background?.light ?? '#ffffff';
    final bgDark = config.theme.colors.background?.dark ?? '#0f172a';
    final textLight = config.theme.colors.text?.light ?? '#1e293b';
    final textDark = config.theme.colors.text?.dark ?? '#e2e8f0';
    final sans = config.theme.fonts.sans;
    final mono = config.theme.fonts.mono;
    final radius = config.theme.radius;

    return '''
  <style>
    :root {
      --color-primary: $primary;
      --color-bg: $bgLight;
      --color-bg-secondary: #f8fafc;
      --color-text: $textLight;
      --color-text-secondary: #64748b;
      --color-border: #e2e8f0;
      --font-sans: '$sans', system-ui, sans-serif;
      --font-mono: '$mono', monospace;
      --radius: $radius;
    }

    .dark {
      --color-bg: $bgDark;
      --color-bg-secondary: #1e293b;
      --color-text: $textDark;
      --color-text-secondary: #94a3b8;
      --color-border: #334155;
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      font-family: var(--font-sans);
      background: var(--color-bg);
      color: var(--color-text);
      line-height: 1.7;
    }

    .layout {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    /* Header */
    .header {
      position: sticky;
      top: 0;
      z-index: 100;
      background: var(--color-bg);
      border-bottom: 1px solid var(--color-border);
      padding: 0 1.5rem;
    }

    .header-inner {
      max-width: 90rem;
      margin: 0 auto;
      height: 4rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .logo {
      font-weight: 700;
      font-size: 1.25rem;
      color: var(--color-text);
      text-decoration: none;
    }

    .nav {
      display: flex;
      align-items: center;
      gap: 1.5rem;
    }

    .nav a {
      color: var(--color-text-secondary);
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 500;
      transition: color 0.15s;
    }

    .nav a:hover {
      color: var(--color-text);
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }

    .search-button {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 0.75rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      color: var(--color-text-secondary);
      font-size: 0.875rem;
      cursor: pointer;
      min-width: 200px;
    }

    .search-button kbd {
      margin-left: auto;
      padding: 0.125rem 0.375rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 4px;
      font-size: 0.75rem;
    }

    /* Search Modal */
    .search-modal {
      position: fixed;
      inset: 0;
      z-index: 1000;
      display: flex;
      align-items: flex-start;
      justify-content: center;
      padding: 10vh 1rem 1rem;
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.15s, visibility 0.15s;
    }

    .search-modal.active {
      opacity: 1;
      visibility: visible;
    }

    .search-modal-backdrop {
      position: absolute;
      inset: 0;
      background: rgba(0, 0, 0, 0.5);
      backdrop-filter: blur(4px);
    }

    .search-modal-container {
      position: relative;
      width: 100%;
      max-width: 640px;
      max-height: 80vh;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: calc(var(--radius) * 1.5);
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      transform: translateY(-10px);
      transition: transform 0.15s;
    }

    .search-modal.active .search-modal-container {
      transform: translateY(0);
    }

    .search-modal-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 1rem;
      border-bottom: 1px solid var(--color-border);
    }

    .search-modal-title {
      font-weight: 600;
      font-size: 0.875rem;
      color: var(--color-text-secondary);
    }

    .search-modal-close {
      padding: 0.25rem;
      background: transparent;
      border: none;
      color: var(--color-text-secondary);
      cursor: pointer;
      border-radius: 4px;
    }

    .search-modal-close:hover {
      background: var(--color-bg-secondary);
      color: var(--color-text);
    }

    #pagefind-container {
      flex: 1;
      overflow-y: auto;
      padding: 0;
    }

    .search-modal-footer {
      padding: 0.75rem 1rem;
      border-top: 1px solid var(--color-border);
      background: var(--color-bg-secondary);
    }

    .search-shortcuts {
      display: flex;
      gap: 1rem;
      font-size: 0.75rem;
      color: var(--color-text-secondary);
    }

    .search-shortcuts kbd {
      padding: 0.125rem 0.375rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 4px;
      font-family: var(--font-mono);
      font-size: 0.6875rem;
    }

    /* Pagefind UI overrides */
    .pagefind-ui {
      --pagefind-ui-scale: 1;
      --pagefind-ui-primary: var(--color-primary);
      --pagefind-ui-text: var(--color-text);
      --pagefind-ui-background: var(--color-bg);
      --pagefind-ui-border: var(--color-border);
      --pagefind-ui-tag: var(--color-bg-secondary);
      font-family: var(--font-sans);
    }

    .pagefind-ui__search-input {
      font-family: var(--font-sans) !important;
      font-size: 1rem !important;
      padding: 0.875rem 1rem !important;
      border-radius: 0 !important;
      border: none !important;
      border-bottom: 1px solid var(--color-border) !important;
      background: transparent !important;
    }

    .pagefind-ui__search-input:focus {
      outline: none !important;
      box-shadow: none !important;
    }

    .pagefind-ui__search-clear {
      top: 50% !important;
      transform: translateY(-50%) !important;
      right: 1rem !important;
    }

    .pagefind-ui__results-area {
      margin-top: 0 !important;
    }

    .pagefind-ui__results {
      padding: 0.5rem !important;
    }

    .pagefind-ui__result {
      padding: 0.75rem !important;
      border-radius: var(--radius) !important;
      border: none !important;
    }

    .pagefind-ui__result:hover {
      background: var(--color-bg-secondary) !important;
    }

    .pagefind-ui__result-link {
      color: var(--color-text) !important;
      font-weight: 600 !important;
    }

    .pagefind-ui__result-title {
      font-weight: 600 !important;
    }

    .pagefind-ui__result-excerpt {
      color: var(--color-text-secondary) !important;
      font-size: 0.875rem !important;
    }

    mark.pagefind-ui__result-highlight {
      background: color-mix(in srgb, var(--color-primary) 30%, transparent) !important;
      color: inherit !important;
    }

    .pagefind-ui__message {
      padding: 2rem 1rem !important;
      color: var(--color-text-secondary) !important;
    }

    .pagefind-ui__button {
      background: var(--color-primary) !important;
      color: white !important;
      border-radius: var(--radius) !important;
    }

    .theme-toggle {
      padding: 0.5rem;
      background: transparent;
      border: none;
      color: var(--color-text-secondary);
      cursor: pointer;
      border-radius: var(--radius);
    }

    .theme-toggle:hover {
      background: var(--color-bg-secondary);
    }

    /* Main container */
    .main-container {
      flex: 1;
      max-width: 90rem;
      margin: 0 auto;
      width: 100%;
      display: grid;
      grid-template-columns: 280px 1fr 220px;
      gap: 1px;
    }

    /* Sidebar */
    .sidebar {
      position: sticky;
      top: 4rem;
      height: calc(100vh - 4rem);
      overflow-y: auto;
      padding: 2rem 1rem;
      border-right: 1px solid var(--color-border);
    }

    .sidebar-group {
      margin-bottom: 1.5rem;
    }

    .sidebar-group-title {
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--color-text-secondary);
      margin-bottom: 0.5rem;
      padding: 0 0.75rem;
    }

    .sidebar-links {
      list-style: none;
    }

    .sidebar-link {
      display: block;
      padding: 0.375rem 0.75rem;
      color: var(--color-text-secondary);
      text-decoration: none;
      font-size: 0.875rem;
      border-radius: var(--radius);
      transition: all 0.15s;
    }

    .sidebar-link:hover {
      color: var(--color-text);
      background: var(--color-bg-secondary);
    }

    .sidebar-link.active {
      color: var(--color-primary);
      background: color-mix(in srgb, var(--color-primary) 10%, transparent);
    }

    /* Content */
    .content {
      padding: 2rem 3rem;
      min-width: 0;
    }

    .prose {
      max-width: 48rem;
    }

    .prose h1 {
      font-size: 2.25rem;
      font-weight: 700;
      margin-bottom: 1rem;
      letter-spacing: -0.025em;
    }

    .prose h2 {
      font-size: 1.5rem;
      font-weight: 600;
      margin-top: 2.5rem;
      margin-bottom: 1rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid var(--color-border);
    }

    .prose h3 {
      font-size: 1.25rem;
      font-weight: 600;
      margin-top: 2rem;
      margin-bottom: 0.75rem;
    }

    .prose h4 {
      font-size: 1rem;
      font-weight: 600;
      margin-top: 1.5rem;
      margin-bottom: 0.5rem;
    }

    .prose p {
      margin-bottom: 1rem;
    }

    .prose a {
      color: var(--color-primary);
      text-decoration: underline;
      text-underline-offset: 2px;
    }

    .prose ul, .prose ol {
      margin-bottom: 1rem;
      padding-left: 1.5rem;
    }

    .prose li {
      margin-bottom: 0.25rem;
    }

    .prose blockquote {
      border-left: 3px solid var(--color-primary);
      padding-left: 1rem;
      color: var(--color-text-secondary);
      font-style: italic;
      margin: 1.5rem 0;
    }

    .prose hr {
      border: none;
      border-top: 1px solid var(--color-border);
      margin: 2rem 0;
    }

    .prose table {
      width: 100%;
      border-collapse: collapse;
      margin: 1.5rem 0;
    }

    .prose th, .prose td {
      padding: 0.75rem 1rem;
      text-align: left;
      border: 1px solid var(--color-border);
    }

    .prose th {
      background: var(--color-bg-secondary);
      font-weight: 600;
    }

    .prose img {
      max-width: 100%;
      border-radius: var(--radius);
    }

    /* Code blocks */
    .prose code {
      font-family: var(--font-mono);
      font-size: 0.875em;
      background: var(--color-bg-secondary);
      padding: 0.125rem 0.375rem;
      border-radius: 4px;
    }

    .prose pre code {
      background: none;
      padding: 0;
    }

    .code-block {
      margin: 1.5rem 0;
      background: var(--color-bg-secondary);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .code-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0.5rem 1rem;
      background: color-mix(in srgb, var(--color-bg-secondary) 50%, var(--color-bg));
      border-bottom: 1px solid var(--color-border);
    }

    .code-language {
      font-size: 0.75rem;
      font-weight: 500;
      color: var(--color-text-secondary);
      text-transform: uppercase;
    }

    .copy-button {
      padding: 0.25rem 0.5rem;
      font-size: 0.75rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 4px;
      color: var(--color-text-secondary);
      cursor: pointer;
      transition: all 0.15s;
    }

    .copy-button:hover {
      background: var(--color-bg-secondary);
      color: var(--color-text);
    }

    .code-pre {
      margin: 0;
      padding: 1rem;
      overflow-x: auto;
      font-size: 0.875rem;
      line-height: 1.6;
    }

    /* ==========================================
       CALLOUTS
       ========================================== */
    .callout {
      margin: 1.5rem 0;
      padding: 1rem 1.25rem;
      border-radius: var(--radius);
      border-left: 4px solid var(--callout-color);
      background: color-mix(in srgb, var(--callout-color) 8%, var(--color-bg));
    }

    .callout-title {
      font-weight: 600;
      margin-bottom: 0.5rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .callout-content {
      color: var(--color-text);
    }

    .callout-content p:last-child {
      margin-bottom: 0;
    }

    /* Callout variants */
    .callout-info { --callout-color: #3b82f6; }
    .callout-warning { --callout-color: #f59e0b; }
    .callout-danger { --callout-color: #ef4444; }
    .callout-tip { --callout-color: #22c55e; }
    .callout-note { --callout-color: #8b5cf6; }
    .callout-success { --callout-color: #10b981; }

    /* ==========================================
       TABS & CODE GROUPS
       ========================================== */
    .tabs,
    .code-group {
      margin: 1.5rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .tabs .tab-buttons,
    .code-group .tab-buttons {
      display: flex;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
      overflow-x: auto;
      scrollbar-width: none;
    }

    .tabs .tab-buttons::-webkit-scrollbar,
    .code-group .tab-buttons::-webkit-scrollbar {
      display: none;
    }

    .tab-button {
      padding: 0.75rem 1rem;
      background: none;
      border: none;
      font-family: var(--font-sans);
      font-size: 0.875rem;
      font-weight: 500;
      color: var(--color-text-secondary);
      cursor: pointer;
      transition: all 0.15s;
      white-space: nowrap;
      position: relative;
    }

    .tab-button:hover {
      color: var(--color-text);
      background: color-mix(in srgb, var(--color-bg-secondary) 50%, var(--color-bg));
    }

    .tab-button.active {
      color: var(--color-primary);
    }

    .tab-button.active::after {
      content: '';
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 2px;
      background: var(--color-primary);
    }

    .tab-panel {
      padding: 1rem;
    }

    .tab-panel[hidden] {
      display: none;
    }

    /* Code group specific */
    .code-group .tab-button {
      font-family: var(--font-mono);
      font-size: 0.8125rem;
    }

    .code-group .tab-panel {
      padding: 0;
    }

    .code-group .tab-panel .code-block {
      margin: 0;
      border: none;
      border-radius: 0;
    }

    .code-group .tab-panel pre {
      margin: 0;
    }

    /* ==========================================
       ACCORDION
       ========================================== */
    .accordion {
      margin: 1rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .accordion-group .accordion {
      margin: 0;
      border-radius: 0;
      border-bottom: none;
    }

    .accordion-group .accordion:first-child {
      border-top-left-radius: var(--radius);
      border-top-right-radius: var(--radius);
    }

    .accordion-group .accordion:last-child {
      border-bottom-left-radius: var(--radius);
      border-bottom-right-radius: var(--radius);
      border-bottom: 1px solid var(--color-border);
    }

    .accordion-group {
      margin: 1.5rem 0;
      border-radius: var(--radius);
    }

    .accordion-summary {
      padding: 0.875rem 1rem;
      cursor: pointer;
      font-weight: 500;
      background: var(--color-bg-secondary);
      display: flex;
      align-items: center;
      gap: 0.5rem;
      list-style: none;
      transition: background 0.15s;
    }

    .accordion-summary::-webkit-details-marker {
      display: none;
    }

    .accordion-summary::before {
      content: '';
      width: 0.5rem;
      height: 0.5rem;
      border-right: 2px solid var(--color-text-secondary);
      border-bottom: 2px solid var(--color-text-secondary);
      transform: rotate(-45deg);
      transition: transform 0.2s;
      flex-shrink: 0;
    }

    .accordion[open] .accordion-summary::before {
      transform: rotate(45deg);
    }

    .accordion-summary:hover {
      background: color-mix(in srgb, var(--color-bg-secondary) 70%, var(--color-bg));
    }

    .accordion-icon {
      margin-right: 0.25rem;
    }

    .accordion-content {
      padding: 1rem;
      border-top: 1px solid var(--color-border);
    }

    .accordion-content p:last-child {
      margin-bottom: 0;
    }

    /* ==========================================
       STEPS
       ========================================== */
    .steps {
      margin: 1.5rem 0;
      padding-left: 0;
    }

    .step {
      display: flex;
      position: relative;
      padding-bottom: 1.5rem;
    }

    .step:last-child {
      padding-bottom: 0;
    }

    .step:last-child .step-line {
      display: none;
    }

    .step-indicator {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-right: 1rem;
      flex-shrink: 0;
    }

    .step-number {
      width: 2rem;
      height: 2rem;
      background: var(--color-primary);
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      font-size: 0.875rem;
      flex-shrink: 0;
    }

    .step-line {
      width: 2px;
      flex: 1;
      background: var(--color-border);
      margin-top: 0.5rem;
      min-height: 1rem;
    }

    .step-body {
      flex: 1;
      padding-top: 0.25rem;
      min-width: 0;
    }

    .step-title {
      font-weight: 600;
      font-size: 1rem;
      margin: 0 0 0.5rem 0;
      color: var(--color-text);
    }

    .step-content {
      color: var(--color-text-secondary);
    }

    .step-content p:last-child {
      margin-bottom: 0;
    }

    /* ==========================================
       CARDS
       ========================================== */
    .cards {
      display: grid;
      grid-template-columns: repeat(var(--cards-columns, 2), 1fr);
      gap: 1rem;
      margin: 1.5rem 0;
    }

    @media (max-width: 640px) {
      .cards {
        grid-template-columns: 1fr;
      }
    }

    .card {
      padding: 1.25rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      transition: all 0.2s;
    }

    .card:not(.cards .card) {
      margin: 1.5rem 0;
    }

    .card-link {
      text-decoration: none;
      color: inherit;
      display: block;
    }

    .card-link:hover {
      border-color: var(--color-primary);
      box-shadow: 0 4px 12px color-mix(in srgb, var(--color-primary) 10%, transparent);
      transform: translateY(-2px);
    }

    .card-icon {
      font-size: 1.25rem;
      margin-right: 0.5rem;
    }

    .card-title {
      font-weight: 600;
      font-size: 1rem;
      margin: 0 0 0.5rem 0;
      color: var(--color-text);
      display: flex;
      align-items: center;
    }

    .card-link:hover .card-title {
      color: var(--color-primary);
    }

    .card-content {
      color: var(--color-text-secondary);
      font-size: 0.875rem;
      line-height: 1.5;
    }

    .card-content p:last-child {
      margin-bottom: 0;
    }

    /* Empty states */
    .tabs-empty,
    .code-group-empty,
    .steps-empty,
    .tiles-empty {
      padding: 2rem;
      text-align: center;
      color: var(--color-text-secondary);
      font-style: italic;
    }

    /* ==========================================
       COLUMNS (Phase 3b)
       ========================================== */
    .columns {
      display: flex;
      gap: var(--columns-gap, 1rem);
      margin: 1.5rem 0;
    }

    .column {
      flex: 1;
      min-width: 0;
    }

    .column > *:first-child {
      margin-top: 0;
    }

    .column > *:last-child {
      margin-bottom: 0;
    }

    @media (max-width: 768px) {
      .columns {
        flex-direction: column;
      }
    }

    /* ==========================================
       TILES (Phase 3b)
       ========================================== */
    .tiles {
      display: grid;
      grid-template-columns: repeat(var(--tiles-columns, 3), 1fr);
      gap: 1rem;
      margin: 1.5rem 0;
    }

    @media (max-width: 1024px) {
      .tiles {
        grid-template-columns: repeat(2, 1fr);
      }
    }

    @media (max-width: 640px) {
      .tiles {
        grid-template-columns: 1fr;
      }
    }

    .tile {
      padding: 1.5rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      text-align: center;
      transition: all 0.2s;
    }

    .tile-link {
      text-decoration: none;
      color: inherit;
      display: block;
    }

    .tile-link:hover {
      border-color: var(--color-primary);
      box-shadow: 0 4px 12px color-mix(in srgb, var(--color-primary) 10%, transparent);
      transform: translateY(-2px);
    }

    .tile-icon {
      font-size: 2rem;
      margin-bottom: 0.75rem;
    }

    .tile-title {
      font-weight: 600;
      font-size: 0.9375rem;
      margin: 0 0 0.5rem 0;
      color: var(--color-text);
    }

    .tile-link:hover .tile-title {
      color: var(--color-primary);
    }

    .tile-content {
      color: var(--color-text-secondary);
      font-size: 0.8125rem;
      line-height: 1.5;
    }

    .tile-content p:last-child {
      margin-bottom: 0;
    }

    /* ==========================================
       PANEL (Phase 3b)
       ========================================== */
    .panel {
      margin: 1.5rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .panel-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.75rem 1rem;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
    }

    .panel-icon {
      font-size: 1.125rem;
    }

    .panel-title {
      font-weight: 600;
      font-size: 0.9375rem;
    }

    .panel-content {
      padding: 1rem;
    }

    .panel-content > *:first-child {
      margin-top: 0;
    }

    .panel-content > *:last-child {
      margin-bottom: 0;
    }

    /* Panel variants */
    .panel-primary {
      border-color: var(--color-primary);
    }

    .panel-primary .panel-header {
      background: color-mix(in srgb, var(--color-primary) 10%, var(--color-bg));
      border-bottom-color: var(--color-primary);
    }

    .panel-success {
      border-color: #10b981;
    }

    .panel-success .panel-header {
      background: color-mix(in srgb, #10b981 10%, var(--color-bg));
      border-bottom-color: #10b981;
    }

    .panel-warning {
      border-color: #f59e0b;
    }

    .panel-warning .panel-header {
      background: color-mix(in srgb, #f59e0b 10%, var(--color-bg));
      border-bottom-color: #f59e0b;
    }

    .panel-danger {
      border-color: #ef4444;
    }

    .panel-danger .panel-header {
      background: color-mix(in srgb, #ef4444 10%, var(--color-bg));
      border-bottom-color: #ef4444;
    }

    /* ==========================================
       BADGE (Phase 3b)
       ========================================== */
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.25rem;
      font-weight: 500;
      border-radius: 9999px;
      white-space: nowrap;
    }

    .badge-icon {
      font-size: 0.875em;
    }

    /* Badge sizes */
    .badge-sm {
      padding: 0.125rem 0.5rem;
      font-size: 0.6875rem;
    }

    .badge-md {
      padding: 0.25rem 0.625rem;
      font-size: 0.75rem;
    }

    .badge-lg {
      padding: 0.375rem 0.75rem;
      font-size: 0.8125rem;
    }

    /* Badge variants */
    .badge-default {
      background: var(--color-bg-secondary);
      color: var(--color-text-secondary);
      border: 1px solid var(--color-border);
    }

    .badge-primary {
      background: color-mix(in srgb, var(--color-primary) 15%, var(--color-bg));
      color: var(--color-primary);
      border: 1px solid color-mix(in srgb, var(--color-primary) 30%, transparent);
    }

    .badge-success {
      background: color-mix(in srgb, #10b981 15%, var(--color-bg));
      color: #10b981;
      border: 1px solid color-mix(in srgb, #10b981 30%, transparent);
    }

    .badge-warning {
      background: color-mix(in srgb, #f59e0b 15%, var(--color-bg));
      color: #b45309;
      border: 1px solid color-mix(in srgb, #f59e0b 30%, transparent);
    }

    .badge-danger {
      background: color-mix(in srgb, #ef4444 15%, var(--color-bg));
      color: #dc2626;
      border: 1px solid color-mix(in srgb, #ef4444 30%, transparent);
    }

    .badge-info {
      background: color-mix(in srgb, #3b82f6 15%, var(--color-bg));
      color: #2563eb;
      border: 1px solid color-mix(in srgb, #3b82f6 30%, transparent);
    }

    /* ==========================================
       ICON (Phase 3b)
       ========================================== */
    .icon {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      vertical-align: middle;
    }

    .icon-emoji {
      line-height: 1;
    }

    .icon-svg svg {
      display: block;
    }

    .icon-text {
      font-family: var(--font-mono);
      font-size: 0.875em;
    }

    /* Lucide icons */
    [data-lucide] {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      vertical-align: middle;
      stroke: currentColor;
      stroke-width: 2;
      stroke-linecap: round;
      stroke-linejoin: round;
      fill: none;
    }

    /* ==========================================
       IMAGE (Phase 3c)
       ========================================== */
    .image-component {
      margin: 1.5rem 0;
    }

    .image-component img {
      max-width: 100%;
      height: auto;
      display: block;
    }

    .image-rounded img {
      border-radius: var(--radius);
    }

    .image-bordered img {
      border: 1px solid var(--color-border);
    }

    .image-zoom-wrapper {
      position: relative;
      display: inline-block;
      cursor: zoom-in;
    }

    .image-zoom-hint {
      position: absolute;
      bottom: 0.5rem;
      right: 0.5rem;
      padding: 0.25rem;
      background: color-mix(in srgb, var(--color-bg) 80%, transparent);
      border-radius: 4px;
      opacity: 0;
      transition: opacity 0.2s;
      pointer-events: none;
    }

    .image-zoom-wrapper:hover .image-zoom-hint {
      opacity: 1;
    }

    .image-caption {
      margin-top: 0.5rem;
      font-size: 0.875rem;
      color: var(--color-text-secondary);
      text-align: center;
    }

    /* Image zoom modal */
    .image-zoom-overlay {
      position: fixed;
      inset: 0;
      z-index: 1000;
      background: color-mix(in srgb, var(--color-bg) 95%, transparent);
      backdrop-filter: blur(4px);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: zoom-out;
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.2s, visibility 0.2s;
    }

    .image-zoom-overlay.active {
      opacity: 1;
      visibility: visible;
    }

    .image-zoom-overlay img {
      max-width: 90vw;
      max-height: 90vh;
      object-fit: contain;
      border-radius: var(--radius);
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }

    /* ==========================================
       TREE (Phase 3c)
       ========================================== */
    .tree {
      margin: 1.5rem 0;
      padding: 1rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      font-family: var(--font-mono);
      font-size: 0.875rem;
    }

    .tree-root {
      list-style: none;
      padding: 0;
      margin: 0;
    }

    .tree-children {
      list-style: none;
      padding-left: 1.25rem;
      margin: 0;
      border-left: 1px dashed var(--color-border);
      margin-left: 0.5rem;
    }

    .tree-folder,
    .tree-file {
      padding: 0.25rem 0;
    }

    .tree-folder > details > summary {
      cursor: pointer;
      list-style: none;
      display: flex;
      align-items: center;
      gap: 0.375rem;
    }

    .tree-folder > details > summary::-webkit-details-marker {
      display: none;
    }

    .tree-folder > details > summary::before {
      content: '▶';
      font-size: 0.625rem;
      transition: transform 0.15s;
      color: var(--color-text-secondary);
    }

    .tree-folder > details[open] > summary::before {
      transform: rotate(90deg);
    }

    .tree-folder-name {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      font-weight: 500;
    }

    .tree-file {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      padding-left: 1rem;
    }

    .tree-icon {
      font-size: 1rem;
      line-height: 1;
    }

    .tree-file-name {
      color: var(--color-text-secondary);
    }

    /* ==========================================
       MERMAID (Phase 3c)
       ========================================== */
    .mermaid-figure {
      margin: 1.5rem 0;
    }

    .mermaid-diagram {
      padding: 1.5rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow-x: auto;
      text-align: center;
    }

    .mermaid-diagram .mermaid {
      margin: 0;
      background: none;
    }

    .mermaid-caption {
      margin-top: 0.5rem;
      font-size: 0.875rem;
      color: var(--color-text-secondary);
      text-align: center;
    }

    /* ==========================================
       TOOLTIP (Phase 3c)
       ========================================== */
    .tooltip {
      position: relative;
      text-decoration: underline;
      text-decoration-style: dotted;
      text-underline-offset: 2px;
      cursor: help;
    }

    .tooltip::before,
    .tooltip::after {
      position: absolute;
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.15s, visibility 0.15s;
      pointer-events: none;
      z-index: 100;
    }

    .tooltip::before {
      content: attr(data-tooltip);
      padding: 0.5rem 0.75rem;
      background: var(--color-text);
      color: var(--color-bg);
      font-size: 0.8125rem;
      font-weight: 500;
      line-height: 1.4;
      border-radius: var(--radius);
      white-space: nowrap;
      max-width: 280px;
      white-space: normal;
      text-align: center;
    }

    .tooltip::after {
      content: '';
      border: 6px solid transparent;
    }

    .tooltip:hover::before,
    .tooltip:hover::after {
      opacity: 1;
      visibility: visible;
    }

    /* Tooltip positions */
    .tooltip-top::before {
      bottom: calc(100% + 8px);
      left: 50%;
      transform: translateX(-50%);
    }

    .tooltip-top::after {
      bottom: calc(100% + 2px);
      left: 50%;
      transform: translateX(-50%);
      border-top-color: var(--color-text);
    }

    .tooltip-bottom::before {
      top: calc(100% + 8px);
      left: 50%;
      transform: translateX(-50%);
    }

    .tooltip-bottom::after {
      top: calc(100% + 2px);
      left: 50%;
      transform: translateX(-50%);
      border-bottom-color: var(--color-text);
    }

    .tooltip-left::before {
      right: calc(100% + 8px);
      top: 50%;
      transform: translateY(-50%);
    }

    .tooltip-left::after {
      right: calc(100% + 2px);
      top: 50%;
      transform: translateY(-50%);
      border-left-color: var(--color-text);
    }

    .tooltip-right::before {
      left: calc(100% + 8px);
      top: 50%;
      transform: translateY(-50%);
    }

    .tooltip-right::after {
      left: calc(100% + 2px);
      top: 50%;
      transform: translateY(-50%);
      border-right-color: var(--color-text);
    }

    /* ==========================================
       EMBEDS (Phase 3d)
       ========================================== */
    .embed {
      margin: 1.5rem 0;
      border-radius: var(--radius);
      overflow: hidden;
      background: var(--color-bg-secondary);
    }

    .embed iframe,
    .embed video {
      width: 100%;
      height: 100%;
      display: block;
    }

    .embed-youtube,
    .embed-vimeo {
      position: relative;
      width: 100%;
    }

    .embed-video video {
      max-width: 100%;
      height: auto;
    }

    .embed-zapp,
    .embed-stackblitz,
    .embed-codepen {
      border: 1px solid var(--color-border);
    }

    .embed-error {
      padding: 1rem;
      background: color-mix(in srgb, #ef4444 10%, var(--color-bg));
      border: 1px solid #ef4444;
      border-radius: var(--radius);
      color: #ef4444;
      font-size: 0.875rem;
      text-align: center;
    }

    /* Responsive embeds */
    @media (max-width: 640px) {
      .embed-zapp,
      .embed-stackblitz,
      .embed-codepen {
        height: 400px !important;
      }
    }

    /* ==========================================
       API DOCS (Phase 3e)
       ========================================== */
    .field {
      margin: 1rem 0;
      padding: 1rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
    }

    .field + .field {
      margin-top: 0.5rem;
    }

    .field-is-deprecated {
      opacity: 0.7;
    }

    .field-header {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
    }

    .field-name {
      font-weight: 600;
      color: var(--color-text);
      background: none;
      padding: 0;
    }

    .field-type {
      font-family: var(--font-mono);
      font-size: 0.8125rem;
      color: var(--color-primary);
    }

    .field-badge {
      font-size: 0.6875rem;
      font-weight: 600;
      text-transform: uppercase;
      padding: 0.125rem 0.375rem;
      border-radius: 4px;
    }

    .field-required {
      background: color-mix(in srgb, #ef4444 15%, var(--color-bg));
      color: #ef4444;
    }

    .field-optional {
      background: var(--color-bg);
      color: var(--color-text-secondary);
      border: 1px solid var(--color-border);
    }

    .field-nullable {
      background: color-mix(in srgb, #f59e0b 15%, var(--color-bg));
      color: #b45309;
    }

    .field-deprecated {
      background: color-mix(in srgb, #6b7280 15%, var(--color-bg));
      color: #6b7280;
      text-decoration: line-through;
    }

    .field-param-type {
      background: color-mix(in srgb, #8b5cf6 15%, var(--color-bg));
      color: #7c3aed;
    }

    .field-default {
      display: block;
      font-size: 0.8125rem;
      color: var(--color-text-secondary);
      margin-bottom: 0.5rem;
    }

    .field-default code {
      background: var(--color-bg);
      padding: 0.125rem 0.25rem;
      border-radius: 3px;
    }

    .field-description {
      font-size: 0.875rem;
      color: var(--color-text-secondary);
    }

    .field-description p:last-child {
      margin-bottom: 0;
    }

    /* API Endpoint */
    .api-endpoint {
      margin: 1.5rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .api-header {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
    }

    .api-method {
      font-size: 0.75rem;
      font-weight: 700;
      padding: 0.25rem 0.5rem;
      border-radius: 4px;
      text-transform: uppercase;
    }

    .api-method-get { background: #10b981; color: white; }
    .api-method-post { background: #3b82f6; color: white; }
    .api-method-put { background: #f59e0b; color: white; }
    .api-method-patch { background: #8b5cf6; color: white; }
    .api-method-delete { background: #ef4444; color: white; }

    .api-path {
      font-family: var(--font-mono);
      font-size: 0.875rem;
      font-weight: 500;
      background: none;
      padding: 0;
    }

    .api-auth {
      margin-left: auto;
      font-size: 0.75rem;
      color: var(--color-text-secondary);
    }

    .api-title {
      padding: 0.75rem 1rem;
      font-weight: 600;
      border-bottom: 1px solid var(--color-border);
    }

    .api-content {
      padding: 1rem;
    }

    /* ==========================================
       FRAME (Phase 3f)
       ========================================== */
    .frame {
      margin: 1.5rem 0;
      border-radius: var(--radius);
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .frame-browser {
      border: 1px solid var(--color-border);
    }

    .frame-header {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
    }

    .frame-buttons {
      display: flex;
      gap: 0.5rem;
    }

    .frame-button {
      width: 12px;
      height: 12px;
      border-radius: 50%;
    }

    .frame-close { background: #ef4444; }
    .frame-minimize { background: #f59e0b; }
    .frame-maximize { background: #22c55e; }

    .frame-url {
      flex: 1;
      padding: 0.375rem 0.75rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 4px;
      font-family: var(--font-mono);
      font-size: 0.75rem;
      color: var(--color-text-secondary);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .frame-content {
      padding: 0;
      background: var(--color-bg);
    }

    .frame-content img {
      display: block;
      width: 100%;
      height: auto;
    }

    /* Phone frame */
    .frame-phone {
      max-width: 375px;
      margin-left: auto;
      margin-right: auto;
      border: 8px solid #1f2937;
      border-radius: 40px;
      background: #1f2937;
    }

    .frame-phone-notch {
      width: 150px;
      height: 28px;
      margin: 0 auto 8px;
      background: #1f2937;
      border-bottom-left-radius: 16px;
      border-bottom-right-radius: 16px;
    }

    .frame-phone .frame-content {
      border-radius: 32px;
      overflow: hidden;
      aspect-ratio: 9/19.5;
    }

    .frame-phone-home {
      width: 120px;
      height: 5px;
      margin: 8px auto 0;
      background: #6b7280;
      border-radius: 3px;
    }

    /* ==========================================
       UPDATE (Phase 3f)
       ========================================== */
    .update {
      margin: 1.5rem 0;
      padding-left: 1rem;
      border-left: 3px solid var(--color-border);
    }

    .update-header {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
    }

    .update-label {
      font-weight: 600;
      font-size: 0.9375rem;
    }

    .update-version {
      font-family: var(--font-mono);
      font-size: 0.8125rem;
      padding: 0.125rem 0.375rem;
      background: var(--color-bg-secondary);
      border-radius: 4px;
    }

    .update-date {
      font-size: 0.8125rem;
      color: var(--color-text-secondary);
    }

    .update-content {
      font-size: 0.9375rem;
    }

    .update-content p:last-child {
      margin-bottom: 0;
    }

    /* Update types */
    .update-feature { border-left-color: #22c55e; }
    .update-feature .update-label { color: #22c55e; }

    .update-fix { border-left-color: #3b82f6; }
    .update-fix .update-label { color: #3b82f6; }

    .update-breaking { border-left-color: #ef4444; }
    .update-breaking .update-label { color: #ef4444; }

    .update-deprecation { border-left-color: #f59e0b; }
    .update-deprecation .update-label { color: #f59e0b; }

    .update-improvement { border-left-color: #8b5cf6; }
    .update-improvement .update-label { color: #8b5cf6; }

    /* Table of contents */
    .toc {
      position: sticky;
      top: 4rem;
      height: calc(100vh - 4rem);
      overflow-y: auto;
      padding: 2rem 1rem;
      border-left: 1px solid var(--color-border);
    }

    .toc-title {
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--color-text-secondary);
      margin-bottom: 0.75rem;
    }

    .toc-list {
      list-style: none;
    }

    .toc-link {
      display: block;
      padding: 0.25rem 0;
      color: var(--color-text-secondary);
      text-decoration: none;
      font-size: 0.8125rem;
      transition: color 0.15s;
    }

    .toc-link:hover {
      color: var(--color-text);
    }

    .toc-link.active {
      color: var(--color-primary);
    }

    .toc-link[data-level="3"] {
      padding-left: 0.75rem;
    }

    .toc-link[data-level="4"] {
      padding-left: 1.5rem;
    }

    /* Edit link */
    .edit-link {
      margin-top: 2rem;
      padding-top: 1.5rem;
      border-top: 1px solid var(--color-border);
    }

    .edit-link a {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      color: var(--color-text-secondary);
      font-size: 0.875rem;
      text-decoration: none;
      transition: color 0.15s;
    }

    .edit-link a:hover {
      color: var(--color-primary);
    }

    .edit-link svg {
      flex-shrink: 0;
    }

    /* Page navigation */
    .page-nav {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
      margin-top: 3rem;
      padding-top: 2rem;
      border-top: 1px solid var(--color-border);
    }

    .page-nav-link {
      display: flex;
      flex-direction: column;
      padding: 1rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      text-decoration: none;
      transition: border-color 0.15s;
    }

    .page-nav-link:hover {
      border-color: var(--color-primary);
    }

    .page-nav-link.next {
      text-align: right;
    }

    .page-nav-label {
      font-size: 0.75rem;
      color: var(--color-text-secondary);
      margin-bottom: 0.25rem;
    }

    .page-nav-title {
      font-weight: 500;
      color: var(--color-text);
    }

    /* Footer */
    .footer {
      border-top: 1px solid var(--color-border);
      padding: 1.5rem 2rem;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.75rem;
      color: var(--color-text-secondary);
      font-size: 0.875rem;
    }

    .footer-social {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .footer-social-link {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 32px;
      height: 32px;
      color: var(--color-text-secondary);
      border-radius: var(--radius);
      transition: all 0.15s;
    }

    .footer-social-link:hover {
      color: var(--color-text);
      background: var(--color-bg-secondary);
    }

    .footer-powered {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      font-size: 0.8125rem;
    }

    .footer-hex {
      color: var(--color-primary);
    }

    .footer-powered a {
      color: var(--color-text);
      text-decoration: none;
      font-weight: 500;
    }

    .footer-powered a:hover {
      color: var(--color-primary);
    }

    /* Header social links */
    .social-link {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      color: var(--color-text-secondary);
      border-radius: var(--radius);
      transition: all 0.15s;
    }

    .social-link:hover {
      color: var(--color-text);
      background: var(--color-bg-secondary);
    }

    .social-badge {
      display: inline-flex;
      align-items: center;
      gap: 0.375rem;
      padding: 0.375rem 0.75rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      color: var(--color-text-secondary);
      font-size: 0.8125rem;
      font-weight: 500;
      text-decoration: none;
      transition: all 0.15s;
    }

    .social-badge:hover {
      color: var(--color-text);
      border-color: var(--color-primary);
    }

    .social-badge svg {
      fill: #0175C2;
    }

    /* Syntax highlighting - GitHub-like theme */
    .hljs-comment, .hljs-quote { color: #6e7781; }
    .hljs-keyword, .hljs-selector-tag { color: #cf222e; }
    .hljs-string, .hljs-attr { color: #0a3069; }
    .hljs-number, .hljs-literal { color: #0550ae; }
    .hljs-variable, .hljs-template-variable { color: #953800; }
    .hljs-title, .hljs-section { color: #8250df; }
    .hljs-type, .hljs-built_in { color: #0550ae; }
    .hljs-name, .hljs-selector-id, .hljs-selector-class { color: #116329; }
    .hljs-addition { color: #116329; background: #dafbe1; }
    .hljs-deletion { color: #82071e; background: #ffebe9; }

    .dark .hljs-comment, .dark .hljs-quote { color: #8b949e; }
    .dark .hljs-keyword, .dark .hljs-selector-tag { color: #ff7b72; }
    .dark .hljs-string, .dark .hljs-attr { color: #a5d6ff; }
    .dark .hljs-number, .dark .hljs-literal { color: #79c0ff; }
    .dark .hljs-variable, .dark .hljs-template-variable { color: #ffa657; }
    .dark .hljs-title, .dark .hljs-section { color: #d2a8ff; }
    .dark .hljs-type, .dark .hljs-built_in { color: #79c0ff; }
    .dark .hljs-name, .dark .hljs-selector-id, .dark .hljs-selector-class { color: #7ee787; }

    /* Responsive */
    @media (max-width: 1280px) {
      .main-container {
        grid-template-columns: 260px 1fr;
      }
      .toc {
        display: none;
      }
    }

    @media (max-width: 768px) {
      .main-container {
        grid-template-columns: 1fr;
      }
      .sidebar {
        display: none;
      }
      .content {
        padding: 1.5rem;
      }
      .search-button {
        min-width: auto;
      }
      .search-button span {
        display: none;
      }
    }
  </style>
''';
  }

  String _buildHeader() {
    final navLinks = config.nav.map((item) {
      final external = item.external ? ' target="_blank" rel="noopener"' : '';
      return '<a href="${item.href}"$external>${item.label}</a>';
    }).join('\n          ');

    final socialLinks = _buildSocialLinks();

    return '''
    <header class="header">
      <div class="header-inner">
        <a href="/" class="logo">${config.name}</a>
        <nav class="nav">
          $navLinks
        </nav>
        <div class="header-actions">
          ${config.search.enabled ? '''
          <button class="search-button" id="search-trigger">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"/>
              <path d="M21 21l-4.35-4.35"/>
            </svg>
            <span>${config.search.placeholder}</span>
            <kbd>${config.search.hotkey}</kbd>
          </button>
          ''' : ''}
          ${config.theme.darkMode.enabled ? '''
          <button class="theme-toggle" id="theme-toggle" aria-label="Toggle dark mode">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="5"/>
              <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/>
            </svg>
          </button>
          ''' : ''}
          $socialLinks
        </div>
      </div>
    </header>
''';
  }

  String _buildSocialLinks() {
    final links = <String>[];

    if (config.social.pubdev != null) {
      links.add('''
        <a href="${config.social.pubdev}" target="_blank" rel="noopener" class="social-badge" aria-label="pub.dev">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
            <path fill-rule="evenodd" d="M4.105 4.105S9.158 1.58 11.684.316a3.079 3.079 0 0 1 1.481-.315c.766.047 1.677.788 1.677.788L24 9.948v9.789h-4.263V24H9.789l-9-9C.303 14.5 0 13.795 0 13.105c0-.319.18-.818.316-1.105l3.789-7.895zm.679.679v11.787c.002.543.021 1.024.498 1.508L10.204 23h8.533v-4.263L4.784 4.784zm12.055-.678c-.899-.896-1.809-1.78-2.74-2.643-.302-.267-.567-.468-1.07-.462-.37.014-.87.195-.87.195L6.341 4.105l10.498.001z"/>
          </svg>
          <span>pub.dev</span>
        </a>
      ''');
    }

    if (config.social.github != null) {
      links.add('''
        <a href="${config.social.github}" target="_blank" rel="noopener" class="social-link" aria-label="GitHub">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.discord != null) {
      links.add('''
        <a href="${config.social.discord}" target="_blank" rel="noopener" class="social-link" aria-label="Discord">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
          </svg>
        </a>
      ''');
    }

    return links.join('\n');
  }

  String _buildFooterSocialLinks() {
    final links = <String>[];

    if (config.social.pubdev != null) {
      links.add('''
        <a href="${config.social.pubdev}" target="_blank" rel="noopener" class="footer-social-link" aria-label="pub.dev">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path fill-rule="evenodd" d="M4.105 4.105S9.158 1.58 11.684.316a3.079 3.079 0 0 1 1.481-.315c.766.047 1.677.788 1.677.788L24 9.948v9.789h-4.263V24H9.789l-9-9C.303 14.5 0 13.795 0 13.105c0-.319.18-.818.316-1.105l3.789-7.895zm.679.679v11.787c.002.543.021 1.024.498 1.508L10.204 23h8.533v-4.263L4.784 4.784zm12.055-.678c-.899-.896-1.809-1.78-2.74-2.643-.302-.267-.567-.468-1.07-.462-.37.014-.87.195-.87.195L6.341 4.105l10.498.001z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.github != null) {
      links.add('''
        <a href="${config.social.github}" target="_blank" rel="noopener" class="footer-social-link" aria-label="GitHub">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.twitter != null) {
      links.add('''
        <a href="${config.social.twitter}" target="_blank" rel="noopener" class="footer-social-link" aria-label="Twitter">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.discord != null) {
      links.add('''
        <a href="${config.social.discord}" target="_blank" rel="noopener" class="footer-social-link" aria-label="Discord">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
          </svg>
        </a>
      ''');
    }

    return links.isEmpty ? '' : '<div class="footer-social">${links.join('\n')}</div>';
  }

  String _buildSidebar(List<SidebarGroup> sidebar, String currentPath) {
    final groups = sidebar.map((group) {
      final links = group.pages.map((page) {
        final pagePath = '/${page.slug}';
        final isActive = pagePath == currentPath || (currentPath == '/' && page.slug == 'index');
        final activeClass = isActive ? ' active' : '';
        final label = page.label ?? _titleCase(page.slug);
        return '<li><a href="$pagePath" class="sidebar-link$activeClass">$label</a></li>';
      }).join('\n          ');

      return '''
      <div class="sidebar-group">
        <div class="sidebar-group-title">${group.group}</div>
        <ul class="sidebar-links">
          $links
        </ul>
      </div>
''';
    }).join('\n');

    return '''
      <aside class="sidebar">
        $groups
      </aside>
''';
  }

  String _buildToc(List<TocEntry> toc) {
    if (toc.isEmpty || !config.toc.enabled) {
      return '<aside class="toc"></aside>';
    }

    final links = toc
        .map(
            (entry) => '<li><a href="#${entry.id}" class="toc-link" data-level="${entry.level}">${entry.text}</a></li>')
        .join('\n          ');

    return '''
      <aside class="toc">
        <div class="toc-title">${config.toc.title}</div>
        <ul class="toc-list">
          $links
        </ul>
      </aside>
''';
  }

  String _buildEditLink(Page page) {
    final editConfig = config.integrations.editLink;

    if (editConfig == null || !editConfig.enabled || editConfig.repo == null) {
      return '';
    }

    final contentDir = config.content.dir;
    final sourcePath = page.sourcePath;

    String relativePath;
    if (sourcePath.contains(contentDir)) {
      final contentIndex = sourcePath.indexOf(contentDir);
      relativePath = sourcePath.substring(contentIndex + contentDir.length);
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
    } else {
      relativePath = page.path == '/' ? 'index.md' : '${page.path.substring(1)}.md';
    }

    final repo = editConfig.repo!;
    final branch = editConfig.branch;
    final basePath = editConfig.path.endsWith('/') ? editConfig.path : '${editConfig.path}/';

    final editUrl = '$repo/edit/$branch/$basePath$relativePath';

    return '''
        <div class="edit-link">
          <a href="$editUrl" target="_blank" rel="noopener">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
            ${editConfig.text}
          </a>
        </div>
''';
  }

  String _buildPageNav(Page page) {
    final buffer = StringBuffer();
    buffer.writeln('<nav class="page-nav">');

    if (page.prev case final prev?) {
      buffer.writeln('''
        <a href="${prev.path}" class="page-nav-link prev">
          <span class="page-nav-label">← Previous</span>
          <span class="page-nav-title">${prev.title}</span>
        </a>
''');
    } else {
      buffer.writeln('<div></div>');
    }

    if (page.next case final next?) {
      buffer.writeln('''
        <a href="${next.path}" class="page-nav-link next">
          <span class="page-nav-label">Next →</span>
          <span class="page-nav-title">${next.title}</span>
        </a>
''');
    } else {
      buffer.writeln('<div></div>');
    }

    buffer.writeln('</nav>');
    return buffer.toString();
  }

  String _buildFooter() {
    final footerSocial = _buildFooterSocialLinks();

    return '''
    <footer class="footer">
      $footerSocial
      <div class="footer-powered">
        Powered by
        <svg class="footer-hex" width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2l9 5v10l-9 5-9-5V7l9-5z"/>
        </svg>
        <a href="https://github.com/nexlabstudio/stardust" target="_blank" rel="noopener">nexlabstudio/stardust</a>
      </div>
    </footer>
''';
  }

  String _buildScripts() => '''
  <script>
    const themeToggle = document.getElementById('theme-toggle');
    const html = document.documentElement;

    function getTheme() {
      return localStorage.getItem('theme') || '${config.theme.darkMode.defaultMode}';
    }

    function setTheme(theme) {
      if (theme === 'system') {
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        html.classList.toggle('dark', prefersDark);
      } else {
        html.classList.toggle('dark', theme === 'dark');
      }
      localStorage.setItem('theme', theme);
    }

    setTheme(getTheme());

    themeToggle?.addEventListener('click', () => {
      const current = getTheme();
      const next = current === 'dark' ? 'light' : 'dark';
      setTheme(next);
    });

    document.querySelectorAll('.copy-button').forEach(button => {
      button.addEventListener('click', async () => {
        const code = button.closest('.code-block').querySelector('code').textContent;
        await navigator.clipboard.writeText(code);
        button.textContent = 'Copied!';
        setTimeout(() => button.textContent = 'Copy', 2000);
      });
    });

    document.querySelectorAll('.tabs').forEach(tabs => {
      const buttons = tabs.querySelectorAll('.tab-button');
      const panels = tabs.querySelectorAll('.tab-panel');

      buttons.forEach(button => {
        button.addEventListener('click', () => {
          const tabId = button.dataset.tab;

          buttons.forEach(b => {
            b.classList.toggle('active', b === button);
            b.setAttribute('aria-selected', b === button);
          });

          panels.forEach(panel => {
            const isActive = panel.id === tabId;
            panel.classList.toggle('active', isActive);
            panel.hidden = !isActive;
          });
        });
      });
    });

    const tocLinks = document.querySelectorAll('.toc-link');
    const headings = Array.from(tocLinks).map(link => 
      document.getElementById(link.getAttribute('href').slice(1))
    ).filter(Boolean);

    function updateToc() {
      const scrollY = window.scrollY;
      let current = null;

      headings.forEach(heading => {
        if (heading.offsetTop - 100 <= scrollY) {
          current = heading;
        }
      });

      tocLinks.forEach(link => {
        link.classList.toggle('active', 
          current && link.getAttribute('href') === '#' + current.id
        );
      });
    }

    window.addEventListener('scroll', updateToc, { passive: true });
    updateToc();

    document.querySelectorAll('.code-group').forEach(group => {
      const buttons = group.querySelectorAll('.tab-button');
      const panels = group.querySelectorAll('.tab-panel');

      buttons.forEach(button => {
        button.addEventListener('click', () => {
          const tabId = button.dataset.tab;

          buttons.forEach(b => {
            b.classList.toggle('active', b === button);
            b.setAttribute('aria-selected', b === button);
          });

          panels.forEach(panel => {
            const isActive = panel.id === tabId;
            panel.classList.toggle('active', isActive);
            panel.hidden = !isActive;
          });
        });
      });
    });

    (function() {
      const zoomableImages = document.querySelectorAll('.image-zoomable .image-zoom-wrapper');
      if (zoomableImages.length === 0) return;

      const overlay = document.createElement('div');
      overlay.className = 'image-zoom-overlay';
      document.body.appendChild(overlay);

      zoomableImages.forEach(wrapper => {
        wrapper.addEventListener('click', () => {
          const src = wrapper.dataset.zoomSrc;
          overlay.innerHTML = '<img src="' + src + '" alt="Zoomed image" />';
          overlay.classList.add('active');
          document.body.style.overflow = 'hidden';
        });
      });

      overlay.addEventListener('click', () => {
        overlay.classList.remove('active');
        document.body.style.overflow = '';
      });

      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && overlay.classList.contains('active')) {
          overlay.classList.remove('active');
          document.body.style.overflow = '';
        }
      });
    })();

    (function() {
      const mermaidDiagrams = document.querySelectorAll('.mermaid');
      if (mermaidDiagrams.length === 0) return;

      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js';
      script.onload = () => {
        mermaid.initialize({
          startOnLoad: true,
          theme: document.documentElement.classList.contains('dark') ? 'dark' : 'default',
          securityLevel: 'loose',
        });
      };
      document.head.appendChild(script);
    })();

    (function() {
      const lucideIcons = document.querySelectorAll('[data-lucide]');
      if (lucideIcons.length === 0) return;

      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/lucide@latest/dist/umd/lucide.min.js';
      script.onload = () => {
        lucide.createIcons();
      };
      document.head.appendChild(script);
    })();
  </script>
''';

  String _buildPagefindStyles(String basePath) {
    if (!config.search.enabled || config.search.provider != 'pagefind') {
      return '';
    }

    return '''
  <link href="$basePath/_pagefind/pagefind-ui.css" rel="stylesheet">
  <style>
    :root {
      --pagefind-ui-scale: 1;
      --pagefind-ui-primary: var(--color-primary);
      --pagefind-ui-text: var(--color-text);
      --pagefind-ui-background: var(--color-bg);
      --pagefind-ui-border: var(--color-border);
      --pagefind-ui-tag: var(--color-bg-secondary);
      --pagefind-ui-border-width: 1px;
      --pagefind-ui-border-radius: var(--radius);
      --pagefind-ui-font: var(--font-sans);
    }
  </style>
''';
  }

  String _buildSearchModal(String basePath) {
    if (!config.search.enabled) {
      return '';
    }

    if (config.search.provider == 'pagefind') {
      return '''
  <div id="search-modal" class="search-modal" aria-hidden="true">
    <div class="search-modal-backdrop"></div>
    <div class="search-modal-container">
      <div class="search-modal-header">
        <div class="search-modal-title">Search Documentation</div>
        <button class="search-modal-close" aria-label="Close search">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6L6 18M6 6l12 12"/>
          </svg>
        </button>
      </div>
      <div id="pagefind-container"></div>
      <div class="search-modal-footer">
        <div class="search-shortcuts">
          <span><kbd>↵</kbd> to select</span>
          <span><kbd>↑</kbd><kbd>↓</kbd> to navigate</span>
          <span><kbd>esc</kbd> to close</span>
        </div>
      </div>
    </div>
  </div>
  <script>
    (function() {
      const searchModal = document.getElementById('search-modal');
      const searchTrigger = document.getElementById('search-trigger');
      const searchBackdrop = searchModal?.querySelector('.search-modal-backdrop');
      const searchClose = searchModal?.querySelector('.search-modal-close');
      const container = document.getElementById('pagefind-container');
      let pagefindUI = null;
      let searchUnavailable = false;

      if (location.protocol === 'file:') {
        searchUnavailable = true;
        if (container) {
          container.innerHTML = '<p style="padding: 2rem; text-align: center; color: var(--color-text-secondary);">Search requires a web server.<br><small>Run <code>stardust dev</code> or use a local server.</small></p>';
        }
      } else {
        const script = document.createElement('script');
        script.src = '$basePath/_pagefind/pagefind-ui.js';
        script.onload = () => {};
        script.onerror = () => {
          searchUnavailable = true;
          if (container) {
            container.innerHTML = '<p style="padding: 2rem; text-align: center; color: var(--color-text-secondary);">Search index not found.<br><small>Run <code>stardust build</code> to generate it.</small></p>';
          }
        };
        document.head.appendChild(script);
      }

      function openSearch() {
        if (!searchModal) return;

        if (!pagefindUI && !searchUnavailable && typeof PagefindUI !== 'undefined') {
          pagefindUI = new PagefindUI({
            element: '#pagefind-container',
            baseUrl: '$basePath/',
            showSubResults: true,
            showImages: false,
            excerptLength: 15,
            resetStyles: false,
            translations: {
              placeholder: '${config.search.placeholder}',
              zero_results: 'No results found for [SEARCH_TERM]',
            }
          });
        }

        searchModal.classList.add('active');
        searchModal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        setTimeout(() => {
          const input = searchModal.querySelector('.pagefind-ui__search-input');
          input?.focus();
        }, 100);
      }

      function closeSearch() {
        if (!searchModal) return;
        searchModal.classList.remove('active');
        searchModal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
      }

      searchTrigger?.addEventListener('click', openSearch);
      searchBackdrop?.addEventListener('click', closeSearch);
      searchClose?.addEventListener('click', closeSearch);

      document.addEventListener('keydown', (e) => {
        if (e.key === '${config.search.hotkey}' && !e.ctrlKey && !e.metaKey) {
          const active = document.activeElement;
          if (active.tagName !== 'INPUT' && active.tagName !== 'TEXTAREA') {
            e.preventDefault();
            openSearch();
          }
        }

        if (e.key === 'Escape' && searchModal?.classList.contains('active')) {
          closeSearch();
        }

        if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
          e.preventDefault();
          if (searchModal?.classList.contains('active')) {
            closeSearch();
          } else {
            openSearch();
          }
        }
      });
    })();
  </script>
''';
    }

    return '';
  }

  String _escapeHtml(String text) =>
      text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

  String _titleCase(String text) => text
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
