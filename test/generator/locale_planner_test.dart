import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/locale_planner.dart';
import 'package:test/test.dart';

void main() {
  group('planLocaleBuilds', () {
    StardustConfig configWith(List<LocaleConfig> locales, {String? basePath}) => StardustConfig(
          name: 'T',
          content: const ContentConfig(dir: 'docs'),
          build: BuildConfig(basePath: basePath),
          i18n: I18nConfig(enabled: true, defaultLocale: 'en', locales: locales),
        );

    test('returns empty when i18n is disabled or absent', () {
      expect(planLocaleBuilds(const StardustConfig(name: 'T'), 'dist'), isEmpty);
    });

    test('routes the default locale to the root and others under their prefix', () {
      final tasks = planLocaleBuilds(
        configWith(const [
          LocaleConfig(code: 'en', label: 'English', path: '/'),
          LocaleConfig(code: 'es', label: 'Español', path: '/es/'),
        ]),
        'dist',
      );

      expect(tasks[0].isDefault, isTrue);
      expect(tasks[0].outputDir, 'dist');
      expect(tasks[0].localeBasePath, isNull);

      expect(tasks[1].isDefault, isFalse);
      expect(tasks[1].outputDir, p.join('dist', 'es'));
      expect(tasks[1].localeBasePath, '/es');
      expect(tasks[1].translatedDir, p.join('docs', 'es'), reason: 'defaults to <content.dir>/<code>');
    });

    test('honors an explicit locale source and nests under a site base path', () {
      final tasks = planLocaleBuilds(
        configWith(
          const [
            LocaleConfig(code: 'en', label: 'English', path: '/'),
            LocaleConfig(code: 'fr', label: 'Français', path: '/fr/', source: 'translations/fr'),
          ],
          basePath: '/docs',
        ),
        'dist',
      );

      expect(tasks[1].translatedDir, 'translations/fr');
      expect(tasks[1].localeBasePath, '/docs/fr');
    });
  });
}
