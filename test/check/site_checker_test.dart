import 'package:stardust/src/check/site_checker.dart';
import 'package:stardust/src/config/config.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  late MockFileSystem fileSystem;

  setUp(() => fileSystem = MockFileSystem());

  Future<List<CheckIssue>> run(StardustConfig config) =>
      SiteChecker(config: config, fileSystem: fileSystem).check('docs');

  group('SiteChecker', () {
    test('passes a site with valid internal links and anchors', () async {
      fileSystem.addFile('docs/index.md', '# Home\n\n[guide](/guide)');
      fileSystem.addFile('docs/guide.md', '## Setup\n\ntext');

      expect(await run(const StardustConfig(name: 'T')), isEmpty);
    });

    test('flags a broken internal link with a suggestion', () async {
      fileSystem.addFile('docs/index.md', '# Home\n\n[go](/instalation)');
      fileSystem.addFile('docs/installation.md', '# Install');

      final issues = await run(const StardustConfig(name: 'T'));

      expect(issues, hasLength(1));
      expect(issues.single.isWarning, isFalse);
      expect(issues.single.message, contains('broken link -> /instalation'));
      expect(issues.single.message, contains('did you mean /installation?'));
    });

    test('flags a link to a missing anchor', () async {
      fileSystem.addFile('docs/index.md', '[jump](/guide#nope)');
      fileSystem.addFile('docs/guide.md', '## Setup');

      final issues = await run(const StardustConfig(name: 'T'));

      expect(issues.single.message, contains('missing anchor -> /guide#nope'));
    });

    test('accepts a link to an existing anchor', () async {
      fileSystem.addFile('docs/index.md', '[jump](/guide#setup)');
      fileSystem.addFile('docs/guide.md', '## Setup');

      expect(await run(const StardustConfig(name: 'T')), isEmpty);
    });

    test('flags a same-page anchor that does not exist', () async {
      fileSystem.addFile('docs/index.md', '## Real\n\n[x](#ghost)');

      final issues = await run(const StardustConfig(name: 'T'));

      expect(issues.single.message, contains('missing anchor "#ghost"'));
    });

    test('ignores external, mailto, and tel links', () async {
      fileSystem.addFile('docs/index.md', '[a](https://x.com) [b](mailto:a@b.com) [c](tel:+1)');

      expect(await run(const StardustConfig(name: 'T')), isEmpty);
    });

    test('flags a missing site-absolute image', () async {
      fileSystem.addFile('docs/index.md', '![x](/images/missing.png)');

      final issues = await run(const StardustConfig(name: 'T'));

      expect(issues.single.message, contains('missing image -> /images/missing.png'));
    });

    test('accepts an image that exists under the assets dir', () async {
      fileSystem.addFile('docs/index.md', '![x](/images/logo.png)');
      fileSystem.addFile('public/images/logo.png', 'binary');

      expect(await run(const StardustConfig(name: 'T')), isEmpty);
    });

    test('warns on an orphaned sidebar entry', () async {
      fileSystem.addFile('docs/index.md', '# Home');
      const config = StardustConfig(
        name: 'T',
        sidebar: [
          SidebarGroup(group: 'Guides', pages: [SidebarPage(slug: 'index'), SidebarPage(slug: 'ghost')]),
        ],
      );

      final issues = await run(config);

      expect(issues, hasLength(1));
      expect(issues.single.isWarning, isTrue);
      expect(issues.single.message, contains('"ghost"'));
    });

    test('check: false skips a page own links but still indexes it as a target', () async {
      fileSystem.addFile('docs/demo.md', '---\ncheck: false\n---\n\n[x](/nowhere)');
      fileSystem.addFile('docs/index.md', '[see the demo](/demo)');

      expect(await run(const StardustConfig(name: 'T')), isEmpty);
    });

    test('component syntax inside code fences is not treated as a live link', () async {
      fileSystem.addFile('docs/index.md', '```html\n<a href="/nowhere">x</a>\n```');

      expect(await run(const StardustConfig(name: 'T')), isEmpty);
    });
  });
}
