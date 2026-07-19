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

  group('search modal', () {
    const searchOn = SearchConfig(enabled: true, hotkey: 's');
    const config = StardustConfig(name: 'T', url: 'https://example.com/docs', search: searchOn);

    test('prefixes result urls with the base path via processResult', () {
      final modal = PageScriptsBuilder(config: config).buildSearchModal('.');

      expect(modal, contains("const base = '/docs'"));
      expect(modal, contains('processResult'));
      expect(modal, contains('sub_results'));
      expect(modal, isNot(contains('baseUrl:')));
    });

    test('uses a native dialog with default excerpt length', () {
      final modal = PageScriptsBuilder(config: config).buildSearchModal('.');

      expect(modal, contains('<dialog id="search-modal"'));
      expect(modal, contains('modal.showModal()'));
      expect(modal, contains('modal.close()'));
      expect(modal, isNot(contains('excerptLength')));
      expect(modal, isNot(contains('search-backdrop')));
    });

    test('honors the configured hotkey', () {
      final modal = PageScriptsBuilder(config: config).buildSearchModal('.');

      expect(modal, contains("e.key === 's'"));
    });

    test('falls back with a message when the index is missing', () {
      final modal = PageScriptsBuilder(config: config).buildSearchModal('.');

      expect(modal, contains('Search index not found'));
    });
  });
}
