import '../../config/config.dart';

/// Builds JavaScript and search functionality for pages
class PageScriptsBuilder {
  final StardustConfig config;

  PageScriptsBuilder({required this.config});

  String buildScripts() => '''
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

  String buildPagefindStyles(String basePath) {
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

  String buildSearchModal(String basePath) {
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
}
