import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/builders/page_styles_builder.dart';
import 'package:stardust/src/generator/builders/stardust_css.dart';
import 'package:test/test.dart';

void main() {
  group('PageStylesBuilder', () {
    group('custom CSS', () {
      test('includes custom CSS when configured', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(
            custom: CustomThemeConfig(
              css: '.my-class { color: red; }',
            ),
          ),
        );
        final builder = PageStylesBuilder(config: config);

        final result = builder.buildStyles();

        expect(result, contains('.my-class { color: red; }'));
        expect(result, contains('/* Custom styles */'));
      });

      test('does not include custom styles section when not configured', () {
        const config = StardustConfig(name: 'Test');
        final builder = PageStylesBuilder(config: config);

        final result = builder.buildStyles();

        expect(result, isNot(contains('/* Custom styles */')));
      });

      test('does not include custom styles section when css is empty', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(
            custom: CustomThemeConfig(css: ''),
          ),
        );
        final builder = PageStylesBuilder(config: config);

        final result = builder.buildStyles();

        expect(result, isNot(contains('/* Custom styles */')));
      });

      test('custom CSS appears after responsive styles', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(
            custom: CustomThemeConfig(
              css: '.custom { display: flex; }',
            ),
          ),
        );
        final builder = PageStylesBuilder(config: config);

        final result = builder.buildStyles();

        final responsiveIndex = result.indexOf('@media (max-width: 768px)');
        final customIndex = result.indexOf('.custom { display: flex; }');
        expect(customIndex, greaterThan(responsiveIndex));
      });

      test('includes CSS from resolved file content', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(
            custom: CustomThemeConfig(cssFile: 'custom.css'),
          ),
        );
        final builder = PageStylesBuilder(config: config);
        builder.resolvedCssFileContent = '.from-file { color: blue; }';

        final result = builder.buildStyles();

        expect(result, contains('.from-file { color: blue; }'));
        expect(result, contains('/* Custom styles */'));
      });

      test('combines resolved file content and inline css', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(
            custom: CustomThemeConfig(
              cssFile: 'custom.css',
              css: '.inline { color: red; }',
            ),
          ),
        );
        final builder = PageStylesBuilder(config: config);
        builder.resolvedCssFileContent = '.from-file { color: blue; }';

        final result = builder.buildStyles();

        expect(result, contains('.from-file { color: blue; }'));
        expect(result, contains('.inline { color: red; }'));
      });

      test('no custom styles when cssFile set but content not resolved', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(
            custom: CustomThemeConfig(cssFile: '/nonexistent/style.css'),
          ),
        );
        final builder = PageStylesBuilder(config: config);

        final result = builder.buildStyles();

        expect(result, isNot(contains('/* Custom styles */')));
      });

      test('supports CSS variable overrides', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(
            custom: CustomThemeConfig(
              css: ':root { --color-primary: #ff0000; }',
            ),
          ),
        );
        final builder = PageStylesBuilder(config: config);

        final result = builder.buildStyles();

        expect(result, contains('--color-primary: #ff0000'));
      });
    });
  });

  group('vendored assets', () {
    test('local font source emits no font links', () {
      const config = StardustConfig(name: 'T', theme: ThemeConfig(fonts: FontsConfig(source: 'local')));

      expect(PageStylesBuilder(config: config).buildFonts(), isEmpty);
    });

    test('google font source keeps the font links', () {
      const config = StardustConfig(name: 'T');

      expect(PageStylesBuilder(config: config).buildFonts(), contains('fonts.googleapis.com'));
    });

    group('design tokens', () {
      test('emits token overrides in :root and .dark', () {
        const config = StardustConfig(
          name: 'T',
          theme: ThemeConfig(
            tokens: {'color-primary': '#ff0000', 'color-border': '#abc'},
            tokensDark: {'color-border': '#111'},
          ),
        );

        final css = PageStylesBuilder(config: config).buildCss();

        expect(css, contains('--color-primary: #ff0000;'));
        expect(css, contains('--color-border: #abc;'));
        expect(css, contains('--color-border: #111;'));
      });

      test('drops unsafe token names so a value cannot break out of the block', () {
        final config = StardustConfig(
          name: 'T',
          theme: ThemeConfig(
              tokens: ThemeConfig.fromYaml({
            'tokens': {'color-x; } body{display:none': 'red'},
          }).tokens),
        );

        expect(PageStylesBuilder(config: config).buildCss(), isNot(contains('display:none')));
      });
    });

    group('section assembly', () {
      final css = PageStylesBuilder(config: const StardustConfig(name: 'T')).buildCss();

      test('assembles every embedded CSS section', () {
        for (final entry in stardustCssSections.entries) {
          expect(css, contains(entry.value.trim()),
              reason: 'CSS section "${entry.key}" is embedded but missing from buildCss()');
        }
      });

      test('includes the landing/splash styles', () {
        expect(css, contains('.hero-action'));
        expect(css, contains('.splash'));
      });
    });
  });
}
