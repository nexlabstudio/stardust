import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/version_planner.dart';
import 'package:test/test.dart';

void main() {
  group('planVersionBuilds', () {
    const config = StardustConfig(
      name: 'T',
      content: ContentConfig(dir: 'docs'),
      versions: VersionsConfig(
        enabled: true,
        current: '2.0',
        list: [
          VersionEntry(version: '2.0', path: '/', label: 'v2'),
          VersionEntry(version: '1.0', path: '/v1/', source: DirSource('versions/1.0')),
        ],
      ),
    );

    test('returns empty when no versions are configured', () {
      expect(planVersionBuilds(const StardustConfig(name: 'T'), 'dist'), isEmpty);
    });

    test('routes the root version to the base output with no prefix', () {
      final root = planVersionBuilds(config, 'dist').first;

      expect(root.entry.version, '2.0');
      expect(root.source, const DirSource('docs'), reason: 'defaults to the live content dir');
      expect(root.outputDir, 'dist');
      expect(root.versionBasePath, isNull);
      expect(root.noindex, isFalse, reason: 'the current version stays indexable');
    });

    test('routes an older version into its path segment with noindex', () {
      final old = planVersionBuilds(config, 'dist')[1];

      expect(old.source, const DirSource('versions/1.0'));
      expect(old.outputDir, p.join('dist', 'v1'));
      expect(old.versionBasePath, '/v1');
      expect(old.noindex, isTrue);
    });

    test('carries a git source through to the build task', () {
      const gitConfig = StardustConfig(
        name: 'T',
        versions: VersionsConfig(
          enabled: true,
          current: '2.0',
          list: [
            VersionEntry(version: '2.0', path: '/'),
            VersionEntry(version: '1.0', path: '/v1/', source: GitSource('v1.0.0')),
          ],
        ),
      );

      expect(planVersionBuilds(gitConfig, 'dist')[1].source, const GitSource('v1.0.0'));
    });

    test('nests version prefixes under an existing site basePath', () {
      const nested = StardustConfig(
        name: 'T',
        build: BuildConfig(basePath: '/stardust'),
        versions: VersionsConfig(
          enabled: true,
          current: '2.0',
          list: [
            VersionEntry(version: '2.0', path: '/'),
            VersionEntry(version: '1.0', path: '/v1/'),
          ],
        ),
      );

      final tasks = planVersionBuilds(nested, 'dist');

      expect(tasks[0].versionBasePath, '/stardust');
      expect(tasks[1].versionBasePath, '/stardust/v1');
    });
  });

  group('rootRedirectTarget', () {
    List<VersionBuildTask> tasksFor(String currentPath) => planVersionBuilds(
          StardustConfig(
            name: 'T',
            versions: VersionsConfig(
              enabled: true,
              current: '2.0',
              list: [
                VersionEntry(version: '2.0', path: currentPath),
                const VersionEntry(version: '1.0', path: '/v1/'),
              ],
            ),
          ),
          'dist',
        );

    test('is null when the current version builds at the root', () {
      expect(rootRedirectTarget(tasksFor('/'), 'dist', '2.0'), isNull);
    });

    test('points at the current version when it lives under a prefix', () {
      expect(rootRedirectTarget(tasksFor('/v2/'), 'dist', '2.0'), '/v2/');
    });
  });

  group('currentVersionSitemapUrl', () {
    StardustConfig configFor({String? url, String path = '/', bool sitemap = true}) => StardustConfig(
          name: 'T',
          url: url,
          build: BuildConfig(sitemap: SitemapConfig(enabled: sitemap)),
          versions: VersionsConfig(
            enabled: true,
            current: '2.0',
            list: [VersionEntry(version: '2.0', path: path)],
          ),
        );

    test('is null without a site url or with sitemaps disabled', () {
      expect(currentVersionSitemapUrl(configFor(url: null)), isNull);
      expect(currentVersionSitemapUrl(configFor(url: 'https://example.com', sitemap: false)), isNull);
    });

    test('targets the root sitemap when the current version is at the root', () {
      expect(currentVersionSitemapUrl(configFor(url: 'https://example.com')), 'https://example.com/sitemap.xml');
    });

    test('targets the prefixed sitemap when the current version is under a prefix', () {
      expect(
        currentVersionSitemapUrl(configFor(url: 'https://example.com', path: '/v2/')),
        'https://example.com/v2/sitemap.xml',
      );
    });
  });
}
