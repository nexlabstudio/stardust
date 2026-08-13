import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/builders/page_scripts_builder.dart';
import 'package:test/test.dart';

void main() {
  group('mermaid script source', () {
    test('default CDN url keeps subresource integrity', () {
      final js = PageScriptsBuilder(config: const StardustConfig(name: 'T')).buildAppJs();

      expect(js, contains(ComponentsConfig.defaultMermaidScriptUrl));
      expect(js, contains('script.integrity'));
    });

    test('custom scriptUrl replaces the CDN and drops integrity', () {
      const config = StardustConfig(
        name: 'T',
        components: ComponentsConfig(mermaidScriptUrl: '/vendor/mermaid.min.js'),
      );
      final js = PageScriptsBuilder(config: config).buildAppJs();

      expect(js, contains('/vendor/mermaid.min.js'));
      expect(js, isNot(contains('cdn.jsdelivr.net/npm/mermaid')));
      expect(js, isNot(contains('script.integrity')));
    });

    test('no lucide loader remains in the shared script', () {
      final js = PageScriptsBuilder(config: const StardustConfig(name: 'T')).buildAppJs();

      expect(js, isNot(contains('lucide')));
    });
  });

  group('synced + persisted tabs script', () {
    final js = PageScriptsBuilder(config: const StardustConfig(name: 'T')).buildAppJs();

    test('drives tabs and code-groups through one handler', () {
      expect(js, contains(".querySelectorAll('.tabs, .code-group')"));
    });

    test('switches every other block in the same group, by label', () {
      expect(js, contains('dataset.tabGroup'));
      expect(js, contains('dataset.tabLabel'));
      expect(js, contains('if (c !== container) selectByLabel(c, label)'));
    });

    test('leaves ungrouped blocks independent', () {
      expect(js, contains('if (!group) return;'));
    });

    test('persists and restores the choice per group via localStorage', () {
      expect(js, contains('localStorage.setItem(storeKey + group, label)'));
      expect(js, contains('localStorage.getItem(storeKey + group)'));
      expect(js, contains("const storeKey = 'stardust:tabs:'"));
    });
  });

  group('localized runtime strings', () {
    const config = StardustConfig(
      name: 'T',
      i18n: I18nConfig(
        strings: I18nStrings(
          codeCopied: 'Copie terminée !',
          codeCopyFailed: 'Échec de la copie',
        ),
      ),
    );
    final js = PageScriptsBuilder(config: config).buildAppJs();

    test('uses localized copy success and failure feedback', () {
      expect(js, contains("const CODE_COPIED = 'Copie terminée !'"));
      expect(js, contains("const CODE_COPY_FAILED = 'Échec de la copie'"));
      expect(js, contains('button.textContent = CODE_COPIED'));
      expect(js, contains('button.textContent = CODE_COPY_FAILED'));
      expect(js, isNot(contains("const CODE_COPIED = 'Copied!'")));
      expect(js, isNot(contains("const CODE_COPY_FAILED = 'Copy failed'")));
    });

    test('image zoom inherits the clicked image alt text', () {
      expect(js, contains("const sourceImage = wrapper.querySelector('img');"));
      expect(js, contains("zoomed.alt = sourceImage ? sourceImage.alt : '';"));
      expect(js, isNot(contains('Zoomed image')));
    });
  });

  group('search modal (raw pagefind api)', () {
    const searchOn = SearchConfig(enabled: true, hotkey: 's');
    const config = StardustConfig(name: 'T', url: 'https://example.com/docs', search: searchOn);
    final modal = PageScriptsBuilder(config: config).buildSearchModal('.');

    test('drives the raw search API, not the PagefindUI widget', () {
      expect(modal, contains("import(BASE + '/pagefind/pagefind.js')"));
      expect(modal, contains('debouncedSearch'));
      expect(modal, isNot(contains('PagefindUI')));
      expect(modal, isNot(contains('pagefind-ui')));
      expect(modal, isNot(contains('processResult')));
    });

    test('prefixes result urls via the baseUrl option on a subpath', () {
      expect(modal, contains("const BASE = '/docs'"));
      expect(modal, contains("baseUrl: BASE || '/'"));
    });

    test('renders our own DOM with build-time inline icons', () {
      expect(modal, contains('<dialog id="search-modal"'));
      expect(modal, contains('class="sd-search__results"'));
      expect(modal, contains('<svg class="lucide"'));
      expect(modal, isNot(contains('data-lucide')));
    });

    test('implements the keyboard combobox pattern', () {
      expect(modal, contains("e.key === 'ArrowDown'"));
      expect(modal, contains("e.key === 'ArrowUp'"));
      expect(modal, contains('aria-activedescendant'));
      expect(modal, contains('role="listbox"'));
    });

    test('honors the configured hotkey and native dialog controls', () {
      expect(modal, contains("e.key === 's'"));
      expect(modal, contains('modal.showModal()'));
      expect(modal, contains('modal.close()'));
    });

    test('shows a message when the index cannot load', () {
      expect(modal, contains('loadError'));
      expect(modal, contains('UNAVAILABLE'));
    });

    test('shows the localized searching status while results load', () {
      const localizedConfig = StardustConfig(
        name: 'T',
        search: searchOn,
        i18n: I18nConfig(
          strings: I18nStrings(searchSearching: 'Recherche en cours...'),
        ),
      );
      final localizedModal = PageScriptsBuilder(config: localizedConfig).buildSearchModal('.');

      expect(localizedModal, contains("const SEARCHING = 'Recherche en cours...'"));
      expect(localizedModal, contains('statusEl.textContent = SEARCHING'));
      expect(localizedModal, isNot(contains("const SEARCHING = 'Searching...'")));
    });

    test('sanitizes result excerpts to only allow <mark> highlights', () {
      expect(modal, contains('markOnly(s.excerpt)'));
      expect(modal, isNot(contains('+ (s.excerpt || \'\') +')));
    });
  });
}
