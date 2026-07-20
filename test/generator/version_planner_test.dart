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
          VersionEntry(version: '1.0', path: '/v1/', source: 'versions/1.0'),
        ],
      ),
    );

    test('returns empty when no versions are configured', () {
      expect(planVersionBuilds(const StardustConfig(name: 'T'), 'dist'), isEmpty);
    });

    test('routes the root version to the base output with no prefix', () {
      final root = planVersionBuilds(config, 'dist').first;

      expect(root.entry.version, '2.0');
      expect(root.source, 'docs', reason: 'defaults to the live content dir');
      expect(root.outputDir, 'dist');
      expect(root.versionBasePath, isNull);
      expect(root.noindex, isFalse, reason: 'the current version stays indexable');
    });

    test('routes an older version into its path segment with noindex', () {
      final old = planVersionBuilds(config, 'dist')[1];

      expect(old.source, 'versions/1.0');
      expect(old.outputDir, p.join('dist', 'v1'));
      expect(old.versionBasePath, '/v1');
      expect(old.noindex, isTrue);
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
}
