import '../../config/config.dart';
import '../../content/utils/icon_utils.dart';
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

    document.querySelectorAll('.copy-page-button').forEach(button => {
      button.addEventListener('click', async () => {
        const label = button.textContent;
        try {
          const response = await fetch(button.dataset.mdPath);
          await navigator.clipboard.writeText(await response.text());
          button.textContent = 'Copied!';
        } catch (e) {
          button.textContent = 'Copy failed';
        }
        setTimeout(() => button.textContent = label, 2000);
      });
    });

    document.querySelectorAll('.copy-button').forEach(button => {
      button.addEventListener('click', async () => {
        const code = button.closest('.code-block').querySelector('code').textContent;
        await navigator.clipboard.writeText(code);
        button.textContent = 'Copied!';
        setTimeout(() => button.textContent = 'Copy', 2000);
      });
    });

    (function() {
      const containers = document.querySelectorAll('.tabs, .code-group');
      if (!containers.length) return;

      const groups = new Map();
      const storeKey = 'stardust:tabs:';

      function apply(buttons, panels, activeButton) {
        const tabId = activeButton.dataset.tab;
        buttons.forEach(b => {
          const on = b === activeButton;
          b.classList.toggle('active', on);
          b.setAttribute('aria-selected', on);
        });
        panels.forEach(panel => {
          const on = panel.id === tabId;
          panel.classList.toggle('active', on);
          panel.hidden = !on;
        });
      }

      function selectByLabel(container, label) {
        const buttons = container.querySelectorAll('.tab-button');
        let target = null;
        buttons.forEach(b => { if (b.dataset.tabLabel === label) target = b; });
        if (target) apply(buttons, container.querySelectorAll('.tab-panel'), target);
      }

      containers.forEach(container => {
        const group = container.dataset.tabGroup;
        if (group) {
          if (!groups.has(group)) groups.set(group, []);
          groups.get(group).push(container);
        }
        const buttons = container.querySelectorAll('.tab-button');
        const panels = container.querySelectorAll('.tab-panel');
        buttons.forEach(button => {
          button.addEventListener('click', () => {
            apply(buttons, panels, button);
            if (!group) return;
            const label = button.dataset.tabLabel;
            groups.get(group).forEach(c => { if (c !== container) selectByLabel(c, label); });
            try { localStorage.setItem(storeKey + group, label); } catch (e) {}
          });
        });
      });

      groups.forEach((members, group) => {
        let saved = null;
        try { saved = localStorage.getItem(storeKey + group); } catch (e) {}
        if (saved) members.forEach(c => selectByLabel(c, saved));
      });
    })();

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

  String buildSearchModal(String basePath) {
    if (!config.search.enabled) {
      return '';
    }

    final i18n = config.i18nStrings;
    return '''
  <dialog id="search-modal" class="search-modal" aria-label="${encodeHtmlAttribute(config.search.placeholder)}">
    <div class="search-container">
      <div class="sd-search">
        <div class="sd-search__box">
          <span class="sd-search__icon">${getLucideIcon('search', '18')}</span>
          <input class="sd-search__input" type="text" autocomplete="off" spellcheck="false"
                 role="searchbox" aria-controls="sd-search__results" aria-activedescendant=""
                 placeholder="${encodeHtmlAttribute(config.search.placeholder)}">
          <button class="sd-search__clear" type="button" aria-label="${encodeHtmlAttribute(i18n.searchClear)}" hidden>${getLucideIcon('x', '18')}</button>
        </div>
        <div class="sd-search__status" role="status" aria-live="polite"></div>
        <ul id="sd-search__results" class="sd-search__results" role="listbox" aria-label="${encodeHtmlAttribute(config.search.placeholder)}"></ul>
        <button class="sd-search__more" type="button" hidden>${encodeHtmlAttribute(i18n.searchMore)}</button>
      </div>
    </div>
  </dialog>
  <script>
    (function() {
      const modal = document.getElementById('search-modal');
      const trigger = document.getElementById('search-trigger');
      const frame = modal.querySelector('.search-container');
      const input = modal.querySelector('.sd-search__input');
      const clearBtn = modal.querySelector('.sd-search__clear');
      const statusEl = modal.querySelector('.sd-search__status');
      const resultsEl = modal.querySelector('#sd-search__results');
      const moreBtn = modal.querySelector('.sd-search__more');

      const BASE = '${encodeJsString(config.basePath)}';
      const PAGE_SIZE = ${config.search.pageSize};
      const PAGE_ICON = '${getLucideIcon('file-text', '16')}';
      const SUB_ICON = '${getLucideIcon('corner-down-right', '14')}';
      const NO_RESULTS = '${encodeJsString(i18n.searchNoResults)}';
      const ONE_RESULT = '${encodeJsString(i18n.searchOneResult)}';
      const MANY_RESULTS = '${encodeJsString(i18n.searchManyResults)}';
      const UNAVAILABLE = '${encodeJsString(i18n.searchUnavailable)}';

      let pagefind = null;
      let loadError = false;
      let results = [];
      let shown = 0;
      let token = 0;
      let uid = 0;
      let options = [];
      let activeIndex = -1;

      function esc(s) {
        return String(s == null ? '' : s)
          .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
      }

      function markOnly(html) {
        return String(html == null ? '' : html).replace(/<(?!\\/?mark>)/gi, '&lt;');
      }

      function countLabel(n) {
        return n === 1 ? ONE_RESULT : MANY_RESULTS.replace('%s', n);
      }

      async function ensurePagefind() {
        if (pagefind || loadError) return;
        try {
          pagefind = await import(BASE + '/pagefind/pagefind.js');
          await pagefind.options({ baseUrl: BASE || '/', excerptLength: 30 });
          await pagefind.init();
        } catch (e) {
          loadError = true;
        }
      }

      function setActive(i) {
        if (options[activeIndex]) options[activeIndex].classList.remove('is-active');
        activeIndex = i;
        const el = options[activeIndex];
        if (el) {
          el.classList.add('is-active');
          input.setAttribute('aria-activedescendant', el.id);
          el.scrollIntoView({ block: 'nearest' });
        } else {
          input.setAttribute('aria-activedescendant', '');
        }
      }

      async function move(dir) {
        if (!options.length) return;
        let i = activeIndex + dir;
        if (i >= options.length) {
          if (!moreBtn.hidden) await renderMore();
          i = activeIndex + dir;
          if (i >= options.length) i = 0;
        } else if (i < 0) {
          i = options.length - 1;
        }
        setActive(i);
      }

      function groupHtml(d) {
        const id = 'sd-r-' + (uid++);
        let html = '<li class="sd-search__group">'
          + '<a class="sd-search__page" role="option" id="' + id + '" href="' + esc(d.url) + '" tabindex="-1">'
          + PAGE_ICON + '<span class="sd-search__page-title">' + esc(d.meta && d.meta.title) + '</span></a>';
        const subs = d.sub_results || [];
        if (subs.length) {
          html += '<ul class="sd-search__subs">';
          for (const s of subs) {
            const sid = 'sd-r-' + (uid++);
            html += '<li><a class="sd-search__sub" role="option" id="' + sid + '" href="' + esc(s.url) + '" tabindex="-1">'
              + SUB_ICON + '<span class="sd-search__sub-title">' + esc(s.title) + '</span>'
              + '<span class="sd-search__excerpt">' + markOnly(s.excerpt) + '</span></a></li>';
          }
          html += '</ul>';
        }
        return html + '</li>';
      }

      function collectOptions() {
        options = Array.prototype.slice.call(resultsEl.querySelectorAll('[role="option"]'));
      }

      async function renderMore() {
        const slice = results.slice(shown, shown + PAGE_SIZE);
        const myToken = token;
        const data = await Promise.all(slice.map((r) => r.data()));
        if (myToken !== token) return;
        for (const d of data) resultsEl.insertAdjacentHTML('beforeend', groupHtml(d));
        shown += slice.length;
        moreBtn.hidden = shown >= results.length;
        collectOptions();
      }

      function clearResults() {
        results = [];
        shown = 0;
        setActive(-1);
        options = [];
        resultsEl.innerHTML = '';
        statusEl.textContent = '';
        moreBtn.hidden = true;
      }

      async function runSearch(term) {
        const myToken = ++token;
        if (!term) { clearResults(); return; }
        await ensurePagefind();
        if (myToken !== token) return;
        if (loadError) { statusEl.textContent = UNAVAILABLE; return; }
        pagefind.preload(term);
        const res = await pagefind.debouncedSearch(term, {}, 250);
        if (res === null || myToken !== token) return;
        results = res.results;
        resultsEl.innerHTML = '';
        shown = 0;
        setActive(-1);
        if (!results.length) {
          statusEl.textContent = NO_RESULTS.replace('%s', term);
          moreBtn.hidden = true;
          return;
        }
        statusEl.textContent = countLabel(results.length);
        await renderMore();
      }

      function open() {
        if (modal.open) return;
        modal.showModal();
        document.body.style.overflow = 'hidden';
        ensurePagefind();
        input.focus();
      }

      input.addEventListener('input', () => {
        clearBtn.hidden = !input.value;
        runSearch(input.value.trim());
      });

      input.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowDown') { e.preventDefault(); move(1); }
        else if (e.key === 'ArrowUp') { e.preventDefault(); move(-1); }
        else if (e.key === 'Home' && options.length) { e.preventDefault(); setActive(0); }
        else if (e.key === 'End' && options.length) { e.preventDefault(); setActive(options.length - 1); }
        else if (e.key === 'Enter' && options[activeIndex]) { e.preventDefault(); options[activeIndex].click(); }
      });

      resultsEl.addEventListener('mouseover', (e) => {
        const opt = e.target.closest && e.target.closest('[role="option"]');
        if (opt) setActive(options.indexOf(opt));
      });

      clearBtn.addEventListener('click', () => {
        input.value = '';
        clearBtn.hidden = true;
        clearResults();
        input.focus();
      });

      moreBtn.addEventListener('click', () => renderMore());

      modal.addEventListener('close', () => { document.body.style.overflow = ''; });
      trigger?.addEventListener('click', open);

      modal.addEventListener('click', (e) => {
        const link = e.target.closest && e.target.closest('a[role="option"]');
        if (link) { modal.close(); return; }
        if (document.body.contains(e.target) && !frame.contains(e.target)) modal.close();
      });

      document.addEventListener('keydown', (e) => {
        if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
          e.preventDefault();
          modal.open ? modal.close() : open();
        }
        if (e.key === '${encodeJsString(config.search.hotkey)}' && !modal.open) {
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
