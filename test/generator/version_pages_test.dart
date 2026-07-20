import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/version_planner.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('discoverPagePaths', () {
    test('maps markdown files to site-root page paths', () async {
      final fs = MockFileSystem();
      fs.addFile('versions/1.0/index.md', '# Home');
      fs.addFile('versions/1.0/guide.md', '# Guide');
      fs.addFile('versions/1.0/api/auth.md', '# Auth');

      expect(await discoverPagePaths(fs, 'versions/1.0', const ContentConfig()), {'/', '/guide', '/api/auth'});
    });

    test('honors exclude globs', () async {
      final fs = MockFileSystem();
      fs.addFile('docs/index.md', '# Home');
      fs.addFile('docs/internal.md', '# Internal');

      expect(await discoverPagePaths(fs, 'docs', const ContentConfig(exclude: ['internal.md'])), {'/'});
    });

    test('ignores non-markdown files', () async {
      final fs = MockFileSystem();
      fs.addFile('docs/index.md', '# Home');
      fs.addFile('docs/logo.png', 'binary');

      expect(await discoverPagePaths(fs, 'docs', const ContentConfig()), {'/'});
    });

    test('returns empty for a missing directory', () async {
      expect(await discoverPagePaths(MockFileSystem(), 'nope', const ContentConfig()), isEmpty);
    });
  });
}
