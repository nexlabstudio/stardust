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

  group('search modal (raw pagefind api)', () {
    const searchOn = SearchConfig(enabled: true, hotkey: 's');
    const config = StardustConfig(name: 'T', url: 'https://example.com/docs', search: searchOn);
    final modal = PageScriptsBuilder(config: config).buildSearchModal('.');

    test('drives the raw search API, not the PagefindUI widget', () {
      expect(modal, contains("import(BASE + '/_pagefind/pagefind.js')"));
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
  });
}
