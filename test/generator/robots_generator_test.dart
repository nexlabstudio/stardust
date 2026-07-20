import 'package:path/path.dart' as p;
import 'package:stardust/src/config/build_config.dart';
import 'package:stardust/src/generator/robots_generator.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('RobotsGenerator', () {
    late MockFileSystem fileSystem;

    setUp(() => fileSystem = MockFileSystem());

    test('writes allow, disallow, and sitemap directives', () async {
      await RobotsGenerator(
        outputDir: 'dist',
        robots: const RobotsConfig(allow: ['/'], disallow: ['/private']),
        sitemapUrl: 'https://example.com/v2/sitemap.xml',
        fileSystem: fileSystem,
      ).generate();

      final robots = fileSystem.fileAt(p.join('dist', 'robots.txt'));
      expect(robots, contains('User-agent: *'));
      expect(robots, contains('Allow: /'));
      expect(robots, contains('Disallow: /private'));
      expect(robots, contains('Sitemap: https://example.com/v2/sitemap.xml'));
    });

    test('omits the sitemap line when no url is given', () async {
      await RobotsGenerator(outputDir: 'dist', robots: const RobotsConfig(), fileSystem: fileSystem).generate();

      expect(fileSystem.fileAt(p.join('dist', 'robots.txt')), isNot(contains('Sitemap:')));
    });
  });
}
