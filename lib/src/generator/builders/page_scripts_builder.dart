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
  <style id="pagefind-theme">
    /* Pagefind CSS custom properties */
    :root {
      --pagefind-ui-scale: 0.9;
      --pagefind-ui-primary: var(--color-primary);
      --pagefind-ui-text: var(--color-text);
      --pagefind-ui-background: var(--color-bg);
      --pagefind-ui-border: var(--color-border);
      --pagefind-ui-tag: var(--color-bg-secondary);
      --pagefind-ui-border-width: 1px;
      --pagefind-ui-border-radius: 8px;
      --pagefind-ui-font: var(--font-sans);
    }

    .pagefind-ui {
      font-family: var(--font-sans) !important;
    }

    /* ===== SEARCH INPUT AREA ===== */
    .pagefind-ui__form {
      position: relative;
      border-bottom: 1px solid var(--color-border);
    }

    .pagefind-ui__search-input {
      width: 100% !important;
      padding: 1rem 1rem 1rem 3rem !important;
      font-size: 1rem !important;
      font-family: var(--font-sans) !important;
      background: transparent !important;
      border: none !important;
      border-radius: 0 !important;
      color: var(--color-text) !important;
      outline: none !important;
    }

    .pagefind-ui__search-input::placeholder {
      color: var(--color-text-secondary) !important;
      opacity: 0.7;
    }

    .pagefind-ui__search-input:focus {
      outline: none !important;
      box-shadow: none !important;
    }

    /* Search icon */
    .pagefind-ui__form::before {
      content: '';
      position: absolute;
      left: 1rem;
      top: 50%;
      transform: translateY(-50%);
      width: 18px;
      height: 18px;
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='11' cy='11' r='8'/%3E%3Cpath d='m21 21-4.35-4.35'/%3E%3C/svg%3E");
      background-repeat: no-repeat;
      background-size: contain;
      pointer-events: none;
      opacity: 0.6;
    }

    .dark .pagefind-ui__form::before {
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='%239ca3af' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='11' cy='11' r='8'/%3E%3Cpath d='m21 21-4.35-4.35'/%3E%3C/svg%3E");
    }

    /* Hide default search icon */
    .pagefind-ui__search-icon {
      display: none !important;
    }

    /* Clear button */
    .pagefind-ui__search-clear {
      position: absolute !important;
      right: 0.75rem !important;
      top: 50% !important;
      transform: translateY(-50%) !important;
      width: 1.5rem !important;
      height: 1.5rem !important;
      padding: 0 !important;
      background: var(--color-bg-secondary) !important;
      border: none !important;
      border-radius: 4px !important;
      color: var(--color-text-secondary) !important;
      cursor: pointer !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      transition: all 0.15s ease !important;
    }

    .pagefind-ui__search-clear:hover {
      background: var(--color-border) !important;
      color: var(--color-text) !important;
    }

    .pagefind-ui__search-clear::before {
      content: '×';
      font-size: 1.25rem;
      line-height: 1;
    }

    .pagefind-ui__search-clear svg {
      display: none !important;
    }

    /* ===== RESULTS AREA ===== */
    .pagefind-ui__results-area {
      margin: 0 !important;
      padding: 0 !important;
    }

    .pagefind-ui__results {
      padding: 0.5rem !important;
    }

    .pagefind-ui__message {
      padding: 2.5rem 1.5rem !important;
      text-align: center !important;
      color: var(--color-text-secondary) !important;
      font-size: 0.9375rem !important;
    }

    /* ===== INDIVIDUAL RESULTS ===== */
    .pagefind-ui__result {
      padding: 0.875rem 1rem !important;
      margin: 0.125rem 0 !important;
      background: transparent !important;
      border: none !important;
      border-radius: 8px !important;
      cursor: pointer !important;
      transition: background-color 0.15s ease !important;
    }

    .pagefind-ui__result:hover,
    .pagefind-ui__result:focus-within {
      background: var(--color-bg-secondary) !important;
    }

    .pagefind-ui__result-link {
      text-decoration: none !important;
    }

    .pagefind-ui__result-title {
      font-size: 0.9375rem !important;
      font-weight: 600 !important;
      color: var(--color-text) !important;
      margin-bottom: 0.25rem !important;
      line-height: 1.4 !important;
      display: flex !important;
      align-items: center !important;
      gap: 0.5rem !important;
    }

    .pagefind-ui__result:hover .pagefind-ui__result-title,
    .pagefind-ui__result:focus-within .pagefind-ui__result-title {
      color: var(--color-primary) !important;
    }

    .pagefind-ui__result-excerpt {
      font-size: 0.8125rem !important;
      color: var(--color-text-secondary) !important;
      line-height: 1.6 !important;
      margin-top: 0.25rem !important;
      display: -webkit-box !important;
      -webkit-line-clamp: 2 !important;
      line-clamp: 2 !important;
      -webkit-box-orient: vertical !important;
      overflow: hidden !important;
    }

    /* Sub-results */
    .pagefind-ui__result-nested {
      margin-left: 1rem !important;
      padding-left: 0.75rem !important;
      border-left: 2px solid var(--color-border) !important;
    }

    /* Result tags/breadcrumbs */
    .pagefind-ui__result-tag {
      font-size: 0.6875rem !important;
      font-weight: 500 !important;
      text-transform: uppercase !important;
      letter-spacing: 0.03em !important;
      color: var(--color-text-secondary) !important;
      background: var(--color-bg-secondary) !important;
      padding: 0.125rem 0.5rem !important;
      border-radius: 4px !important;
    }

    /* ===== HIGHLIGHT MATCHES ===== */
    mark.pagefind-ui__result-highlight {
      background: linear-gradient(120deg,
        color-mix(in srgb, var(--color-primary) 20%, transparent) 0%,
        color-mix(in srgb, var(--color-primary) 30%, transparent) 100%) !important;
      color: inherit !important;
      padding: 0.0625rem 0.25rem !important;
      border-radius: 3px !important;
      font-weight: 500 !important;
    }

    /* ===== LOAD MORE BUTTON ===== */
    .pagefind-ui__button {
      display: block !important;
      width: calc(100% - 2rem) !important;
      margin: 0.5rem 1rem 1rem !important;
      padding: 0.75rem 1rem !important;
      background: var(--color-bg-secondary) !important;
      border: 1px solid var(--color-border) !important;
      border-radius: 8px !important;
      color: var(--color-text) !important;
      font-size: 0.875rem !important;
      font-weight: 500 !important;
      cursor: pointer !important;
      transition: all 0.15s ease !important;
    }

    .pagefind-ui__button:hover {
      background: var(--color-border) !important;
      border-color: var(--color-text-secondary) !important;
    }

    /* ===== DRAWER (hidden) ===== */
    .pagefind-ui__drawer {
      display: none !important;
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
  <div id="search-modal" class="search-modal" aria-hidden="true" role="dialog" aria-modal="true">
    <div class="search-modal-backdrop"></div>
    <div class="search-modal-container">
      <div id="pagefind-container"></div>
      <div class="search-modal-footer">
        <div class="search-shortcuts">
          <span><kbd>Enter</kbd> to select</span>
          <span><kbd>↑</kbd> <kbd>↓</kbd> to navigate</span>
          <span><kbd>Esc</kbd> to close</span>
        </div>
        <span class="search-powered">Search by Pagefind</span>
      </div>
    </div>
  </div>
  <script>
    (function() {
      const searchModal = document.getElementById('search-modal');
      const searchTrigger = document.getElementById('search-trigger');
      const searchBackdrop = searchModal?.querySelector('.search-modal-backdrop');
      const container = document.getElementById('pagefind-container');
      let pagefindUI = null;
      let pagefindLoaded = false;
      let searchUnavailable = false;

      function showLoadingState() {
        if (container) {
          container.innerHTML = '<div class="search-loading"><div class="search-loading-spinner"></div><span>Loading search...</span></div>';
        }
      }

      function showErrorState(message) {
        if (container) {
          container.innerHTML = '<div class="search-error"><svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/><path d="M8 8l6 6M14 8l-6 6"/></svg><p>' + message + '</p></div>';
        }
      }

      function initPagefind() {
        if (pagefindUI || searchUnavailable) return;

        if (typeof PagefindUI === 'undefined') {
          console.warn('[Stardust] PagefindUI not loaded yet');
          return;
        }

        if (container) container.innerHTML = '';

        try {
          pagefindUI = new PagefindUI({
            element: '#pagefind-container',
            baseUrl: '${config.basePath}/',
            showSubResults: true,
            showImages: false,
            excerptLength: 20,
            resetStyles: false,
            autofocus: true,
            translations: {
              placeholder: '${config.search.placeholder}',
              zero_results: 'No results found for "[SEARCH_TERM]"',
              many_results: '{count} results',
              one_result: '1 result',
              searching: 'Searching...',
            }
          });
        } catch (e) {
          console.error('[Stardust] Failed to initialize PagefindUI:', e);
          showErrorState('Failed to initialize search.');
        }
      }

      if (location.protocol === 'file:') {
        searchUnavailable = true;
        showErrorState('Search requires a web server.<br><small>Run <code>stardust dev</code> to start one.</small>');
      } else {
        showLoadingState();

        const script = document.createElement('script');
        script.src = '$basePath/_pagefind/pagefind-ui.js';
        script.onload = () => {
          pagefindLoaded = true;
          if (searchModal?.classList.contains('active')) {
            initPagefind();
          }
        };
        script.onerror = () => {
          searchUnavailable = true;
          showErrorState('Search index not found.<br><small>Run <code>stardust build</code> to generate it.</small>');
        };
        document.head.appendChild(script);

        setTimeout(() => {
          if (!pagefindLoaded && !searchUnavailable && typeof PagefindUI === 'undefined') {
            searchUnavailable = true;
            showErrorState('Search unavailable.<br><small>Run <code>stardust build</code> to generate the index.</small>');
          }
        }, 5000);
      }

      function openSearch() {
        if (!searchModal) return;

        searchModal.classList.add('active');
        searchModal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        // Initialize PagefindUI if not done yet
        if (pagefindLoaded && !pagefindUI && !searchUnavailable) {
          initPagefind();
        }

        // Focus the search input after a brief delay
        setTimeout(() => {
          const input = searchModal.querySelector('.pagefind-ui__search-input');
          if (input) {
            input.focus();
            input.select();
          }
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

      document.addEventListener('keydown', (e) => {
        const isSearchOpen = searchModal?.classList.contains('active');

        if (e.key === '${config.search.hotkey}' && !e.ctrlKey && !e.metaKey && !isSearchOpen) {
          const active = document.activeElement;
          if (active?.tagName !== 'INPUT' && active?.tagName !== 'TEXTAREA' && !active?.isContentEditable) {
            e.preventDefault();
            openSearch();
          }
        }

        if (e.key === 'Escape' && isSearchOpen) {
          e.preventDefault();
          closeSearch();
        }

        if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
          e.preventDefault();
          isSearchOpen ? closeSearch() : openSearch();
        }
      });
    })();
  </script>
''';
    }

    return '';
  }
}
