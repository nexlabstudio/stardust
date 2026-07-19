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
}
