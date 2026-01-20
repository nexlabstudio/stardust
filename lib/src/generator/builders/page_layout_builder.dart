import '../../config/config.dart';
import '../../content/markdown_parser.dart';
import '../../models/page.dart';

/// Builds layout components: header, sidebar, footer, navigation
class PageLayoutBuilder {
  final StardustConfig config;
  late final String _basePath;

  PageLayoutBuilder({required this.config}) : _basePath = config.basePath;

  String _prefixPath(String path) => '$_basePath$path';

  String buildHeader() {
    final navLinks = config.nav.map((item) {
      final external = item.external ? ' target="_blank" rel="noopener"' : '';
      final href = item.external ? item.href : _prefixPath(item.href);
      return '<a href="$href"$external>${item.label}</a>';
    }).join('\n          ');

    final socialLinks = _buildSocialLinks();
    final logoHtml = _buildLogo();

    return '''
    <header class="header">
      <div class="header-inner">
        <a href="${_prefixPath('/')}" class="logo">
          $logoHtml
          ${config.header.showName ? '<span class="logo-text">${config.name}</span>' : ''}
        </a>
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

  String _buildLogo() {
    final logo = config.logo;

    if (logo == null) {
      return '';
    }

    final lightLogo = logo.effectiveLight;
    final darkLogo = logo.effectiveDark;

    if (lightLogo != null && darkLogo != null && lightLogo != darkLogo) {
      return '''
        <img src="${_prefixPath(lightLogo)}" alt="${config.name}" class="logo-image logo-light" />
        <img src="${_prefixPath(darkLogo)}" alt="${config.name}" class="logo-image logo-dark" />
      ''';
    } else if (lightLogo != null) {
      return '<img src="${_prefixPath(lightLogo)}" alt="${config.name}" class="logo-image" />';
    }

    return '';
  }

  String _buildSocialLinks() {
    final links = <String>[];

    if (config.social.pubdev case final pubdev?) {
      links.add('''
        <a href="$pubdev" target="_blank" rel="noopener" class="social-badge" aria-label="pub.dev">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
            <path fill-rule="evenodd" d="M4.105 4.105S9.158 1.58 11.684.316a3.079 3.079 0 0 1 1.481-.315c.766.047 1.677.788 1.677.788L24 9.948v9.789h-4.263V24H9.789l-9-9C.303 14.5 0 13.795 0 13.105c0-.319.18-.818.316-1.105l3.789-7.895zm.679.679v11.787c.002.543.021 1.024.498 1.508L10.204 23h8.533v-4.263L4.784 4.784zm12.055-.678c-.899-.896-1.809-1.78-2.74-2.643-.302-.267-.567-.468-1.07-.462-.37.014-.87.195-.87.195L6.341 4.105l10.498.001z"/>
          </svg>
          <span>pub.dev</span>
        </a>
      ''');
    }

    if (config.social.github case final github?) {
      links.add('''
        <a href="$github" target="_blank" rel="noopener" class="social-link" aria-label="GitHub">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.discord case final discord?) {
      links.add('''
        <a href="$discord" target="_blank" rel="noopener" class="social-link" aria-label="Discord">
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

    if (config.social.pubdev case final pubdev?) {
      links.add('''
        <a href="$pubdev" target="_blank" rel="noopener" class="footer-social-link" aria-label="pub.dev">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path fill-rule="evenodd" d="M4.105 4.105S9.158 1.58 11.684.316a3.079 3.079 0 0 1 1.481-.315c.766.047 1.677.788 1.677.788L24 9.948v9.789h-4.263V24H9.789l-9-9C.303 14.5 0 13.795 0 13.105c0-.319.18-.818.316-1.105l3.789-7.895zm.679.679v11.787c.002.543.021 1.024.498 1.508L10.204 23h8.533v-4.263L4.784 4.784zm12.055-.678c-.899-.896-1.809-1.78-2.74-2.643-.302-.267-.567-.468-1.07-.462-.37.014-.87.195-.87.195L6.341 4.105l10.498.001z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.github case final github?) {
      links.add('''
        <a href="$github" target="_blank" rel="noopener" class="footer-social-link" aria-label="GitHub">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.twitter case final twitter?) {
      links.add('''
        <a href="$twitter" target="_blank" rel="noopener" class="footer-social-link" aria-label="Twitter">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
          </svg>
        </a>
      ''');
    }

    if (config.social.discord case final discord?) {
      links.add('''
        <a href="$discord" target="_blank" rel="noopener" class="footer-social-link" aria-label="Discord">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
          </svg>
        </a>
      ''');
    }

    return links.isEmpty ? '' : '<div class="footer-social">${links.join('\n')}</div>';
  }

  String buildSidebar(List<SidebarGroup> sidebar, String currentPath) {
    final groups = sidebar.map((group) {
      final links = group.pages.map((page) {
        final pagePath = '/${page.slug}';
        final isActive = pagePath == currentPath || (currentPath == '/' && page.slug == 'index');
        final activeClass = isActive ? ' active' : '';
        final label = page.label ?? _titleCase(page.slug);
        return '<li><a href="${_prefixPath(pagePath)}" class="sidebar-link$activeClass">$label</a></li>';
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

  String buildToc(List<TocEntry> toc) {
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

  String buildEditLink(Page page) {
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

  String buildPageNav(Page page) {
    final buffer = StringBuffer();
    buffer.writeln('<nav class="page-nav">');

    if (page.prev case final prev?) {
      buffer.writeln('''
        <a href="${_prefixPath(prev.path)}" class="page-nav-link prev">
          <span class="page-nav-label">← Previous</span>
          <span class="page-nav-title">${prev.title}</span>
        </a>
''');
    } else {
      buffer.writeln('<div></div>');
    }

    if (page.next case final next?) {
      buffer.writeln('''
        <a href="${_prefixPath(next.path)}" class="page-nav-link next">
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

  String buildFooter() {
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

  String _titleCase(String text) => text
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
