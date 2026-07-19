import '../../config/config.dart';
import '../../utils/html_utils.dart';

/// Builds JavaScript and search functionality for pages
class PageScriptsBuilder {
  final StardustConfig config;

  PageScriptsBuilder({required this.config});

  /// Blocking snippet for `<head>`: applies the theme class before first paint.
  String buildThemeInit() => '''
  <script>
    (function() {
      const theme = localStorage.getItem('theme') || '${encodeJsString(config.theme.darkMode.defaultMode)}';
      const dark = theme === 'dark' || (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
      document.documentElement.classList.toggle('dark', dark);
    })();
  </script>''';

  String buildScripts() => '''
  <script>
${buildAppJs()}
  </script>
''';

  /// The site's shared JavaScript, written once per build to assets/app.js.
  String buildAppJs() => '''
    const themeToggle = document.getElementById('theme-toggle');
    const html = document.documentElement;

    function getTheme() {
      return localStorage.getItem('theme') || '${encodeJsString(config.theme.darkMode.defaultMode)}';
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

    themeToggle?.addEventListener('click', () => {
      const current = getTheme();
      const effective = current === 'system'
        ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
        : current;
      setTheme(effective === 'dark' ? 'light' : 'dark');
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

    document.querySelectorAll('.sidebar-group').forEach(group => {
      const title = group.querySelector('.sidebar-group-title');
      if (!title || !title.hasAttribute('data-collapsible')) return;
      const key = 'sidebar-' + title.textContent.trim();
      const stored = localStorage.getItem(key);
      if (stored === 'true') group.classList.add('collapsed');
      else if (stored === 'false') group.classList.remove('collapsed');
      title.addEventListener('click', () => {
        group.classList.toggle('collapsed');
        localStorage.setItem(key, group.classList.contains('collapsed'));
      });
    });

    const activeSidebarLink = document.querySelector('.sidebar-link.active');
    if (activeSidebarLink) {
      activeSidebarLink.scrollIntoView({ block: 'center', behavior: 'instant' });
    }

    const menuToggle = document.getElementById('mobile-menu-toggle');
    const mobileSidebar = document.querySelector('.sidebar');
    const mobileOverlay = document.getElementById('mobile-overlay');
    if (menuToggle && mobileSidebar && mobileOverlay) {
      const closeMenu = () => {
        mobileSidebar.classList.remove('open');
        mobileOverlay.classList.remove('active');
        document.body.style.overflow = '';
      };
      menuToggle.addEventListener('click', () => {
        const isOpen = mobileSidebar.classList.toggle('open');
        mobileOverlay.classList.toggle('active');
        document.body.style.overflow = isOpen ? 'hidden' : '';
      });
      mobileOverlay.addEventListener('click', closeMenu);
      const sidebarClose = document.getElementById('sidebar-close');
      if (sidebarClose) sidebarClose.addEventListener('click', closeMenu);
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && mobileSidebar.classList.contains('open')) closeMenu();
      });
      mobileSidebar.querySelectorAll('.sidebar-link').forEach(link => {
        link.addEventListener('click', closeMenu);
      });
    }

    const announcement = document.getElementById('announcement');
    if (announcement) {
      const text = announcement.textContent.trim();
      const key = 'stardust-dismiss-' + text.substring(0, 50).replace(/\\s+/g, '-').toLowerCase();
      if (localStorage.getItem(key) === 'dismissed') {
        announcement.classList.add('dismissed');
      }
      const dismissBtn = announcement.querySelector('.announcement-dismiss');
      if (dismissBtn) {
        dismissBtn.addEventListener('click', () => {
          announcement.classList.add('dismissed');
          localStorage.setItem(key, 'dismissed');
        });
      }
    }

    const versionBanner = document.getElementById('version-banner');
    if (versionBanner) {
      const key = 'stardust-dismiss-version-' + versionBanner.dataset.version;
      if (localStorage.getItem(key) === 'dismissed') {
        versionBanner.classList.add('dismissed');
      }
      const btn = versionBanner.querySelector('.version-banner-dismiss');
      if (btn) {
        btn.addEventListener('click', () => {
          versionBanner.classList.add('dismissed');
          localStorage.setItem(key, 'dismissed');
        });
      }
    }

    (function() {
      const dropdown = document.getElementById('version-dropdown');
      if (!dropdown) return;
      const trigger = dropdown.querySelector('.version-dropdown-trigger');
      trigger.addEventListener('click', () => dropdown.classList.toggle('open'));
      document.addEventListener('click', (e) => {
        if (!dropdown.contains(e.target)) dropdown.classList.remove('open');
      });
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') dropdown.classList.remove('open');
      });
    })();

    (function() {
      const dropdown = document.getElementById('locale-dropdown');
      if (!dropdown) return;
      const trigger = dropdown.querySelector('.locale-dropdown-trigger');
      trigger.addEventListener('click', () => dropdown.classList.toggle('open'));
      document.addEventListener('click', (e) => {
        if (!dropdown.contains(e.target)) dropdown.classList.remove('open');
      });
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') dropdown.classList.remove('open');
      });
    })();

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
          overlay.textContent = '';
          const zoomed = document.createElement('img');
          zoomed.src = src;
          zoomed.alt = 'Zoomed image';
          overlay.appendChild(zoomed);
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
      script.src = '${encodeJsString(config.components.mermaidScriptUrl)}';${_mermaidIntegrity()}
      script.onload = () => {
        mermaid.initialize({
          startOnLoad: true,
          theme: document.documentElement.classList.contains('dark') ? 'dark' : 'default',
          securityLevel: 'loose',
        });
      };
      document.head.appendChild(script);
    })();

''';

  String _mermaidIntegrity() {
    if (config.components.mermaidScriptUrl != ComponentsConfig.defaultMermaidScriptUrl) return '';
    return '''

      script.integrity = 'sha384-qX9VvWkP79m/O121ZE6sOYp0nf/pldQgtvWDbkpzi+3mUo4Wn4Ix4cFzNPay3VaB';
      script.crossOrigin = 'anonymous';''';
  }

  String buildPagefindStyles(String basePath) {
    if (!config.search.enabled || config.search.provider != 'pagefind') {
      return '';
    }

    return '  <link href="${encodeHtmlAttribute(basePath)}/_pagefind/pagefind-ui.css" rel="stylesheet">';
  }

  String buildSearchModal(String basePath) {
    if (!config.search.enabled || config.search.provider != 'pagefind') {
      return '';
    }

    return '''
  <script src="${encodeHtmlAttribute(basePath)}/_pagefind/pagefind-ui.js"></script>
  <div id="search-modal" class="search-modal">
    <div class="search-backdrop"></div>
    <div class="search-container">
      <div id="pagefind-search"></div>
    </div>
  </div>
  <script>
    (function() {
      const modal = document.getElementById('search-modal');
      const trigger = document.getElementById('search-trigger');
      const backdrop = modal.querySelector('.search-backdrop');
      let ui = null;

      function open() {
        modal.classList.add('open');
        document.body.style.overflow = 'hidden';
        if (!ui && typeof PagefindUI !== 'undefined') {
          ui = new PagefindUI({
            element: '#pagefind-search',
            showSubResults: true,
            baseUrl: '${encodeJsString(config.basePath)}/',
            showImages: false,
            excerptLength: 20,
            resetStyles: false,
            autofocus: true,
            translations: {
              placeholder: '${encodeJsString(config.search.placeholder)}',
              zero_results: '${encodeJsString(config.i18nStrings.searchNoResults.replaceAll('%s', '[SEARCH_TERM]'))}',
              many_results: '${encodeJsString(config.i18nStrings.searchManyResults.replaceAll('%s', '[COUNT]'))}',
              one_result: '${encodeJsString(config.i18nStrings.searchOneResult)}',
              searching: '${encodeJsString(config.i18nStrings.searchSearching)}',
            },
          });
        }
        setTimeout(() => modal.querySelector('input')?.focus(), 100);
      }

      function close() {
        modal.classList.remove('open');
        document.body.style.overflow = '';
      }

      trigger?.addEventListener('click', open);
      backdrop?.addEventListener('click', close);

      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal.classList.contains('open')) {
          close();
        }
        if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
          e.preventDefault();
          modal.classList.contains('open') ? close() : open();
        }
        if (e.key === '/' && !modal.classList.contains('open')) {
          const t = document.activeElement?.tagName;
          if (t !== 'INPUT' && t !== 'TEXTAREA') {
            e.preventDefault();
            open();
          }
        }
      });
    })();
  </script>
''';
  }
}
