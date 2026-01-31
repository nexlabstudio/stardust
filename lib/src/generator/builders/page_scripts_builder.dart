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
      --pagefind-ui-primary: var(--color-primary);
      --pagefind-ui-text: var(--color-text);
      --pagefind-ui-background: var(--color-bg);
      --pagefind-ui-border: var(--color-border);
      --pagefind-ui-tag: var(--color-bg-secondary);
      --pagefind-ui-border-width: 1px;
      --pagefind-ui-border-radius: 8px;
      --pagefind-ui-font: var(--font-sans);
    }

    .dark {
      --pagefind-ui-primary: var(--color-primary);
      --pagefind-ui-text: var(--color-text);
      --pagefind-ui-background: var(--color-bg);
      --pagefind-ui-border: var(--color-border);
      --pagefind-ui-tag: var(--color-bg-secondary);
    }

    .pagefind-ui {
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
  </style>
''';
  }

  String buildSearchModal(String basePath) {
    if (!config.search.enabled || config.search.provider != 'pagefind') {
      return '';
    }

    return '''
  <script src="$basePath/_pagefind/pagefind-ui.js"></script>
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
            baseUrl: '${config.basePath}/',
            showImages: false,
            excerptLength: 20,
            resetStyles: false,
            autofocus: true,
            translations: {
              placeholder: '${config.search.placeholder}',
              zero_results: 'No results found for [SEARCH_TERM]',
              many_results: '[COUNT] results',
              one_result: '1 result',
              searching: 'Searching...',
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
