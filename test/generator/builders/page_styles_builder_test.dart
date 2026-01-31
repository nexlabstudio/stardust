import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/builders/page_styles_builder.dart';
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
}
