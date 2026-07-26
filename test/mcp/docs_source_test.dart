import 'package:stardust/src/mcp/docs_source.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

const _manifest = '''
{
  "name": "Acme Docs",
  "description": "The Acme SDK.",
  "url": "https://acme.dev",
  "generator": "stardust",
  "pages": [
    { "path": "/", "title": "Home", "description": "Landing.", "url": "https://acme.dev/", "md": "/index.md" },
    { "path": "/guide", "title": "User Guide", "url": "https://acme.dev/guide", "md": "/guide.md" }
  ]
}
''';

MockFileSystem _seed() {
  final fs = MockFileSystem();
  fs.addFile('site/llms.json', _manifest);
  fs.addFile('site/index.md', 'Welcome to the home page.');
  fs.addFile('site/guide.md', 'This guide explains widgets and gadgets. widgets widgets are everywhere.');
  return fs;
}

void main() {
  group('DocsSource.load', () {
    test('parses the manifest into site metadata and pages', () async {
      final source = await DocsSource.load('site', fileSystem: _seed(), logger: const Logger());

      expect(source.siteName, 'Acme Docs');
      expect(source.siteDescription, 'The Acme SDK.');
      expect(source.siteUrl, 'https://acme.dev');
      expect(source.pages.map((p) => p.path), ['/', '/guide']);
      expect(source.pages.last.title, 'User Guide');
      expect(source.pages.last.mdFile, '/guide.md');
    });

    test('throws an actionable ContentException when llms.json is absent', () async {
      final fs = MockFileSystem()..addFile('site/index.md', 'x');
      expect(
        () => DocsSource.load('site', fileSystem: fs),
        throwsA(isA<ContentException>().having((e) => e.message, 'message', contains('stardust build'))),
      );
    });

    test('throws on malformed manifest json', () async {
      final fs = MockFileSystem()..addFile('site/llms.json', '"not an object"');
      expect(() => DocsSource.load('site', fileSystem: fs), throwsA(isA<ContentException>()));
    });
  });

  group('DocsSource.readPage', () {
    test('returns the verbatim markdown for a known path', () async {
      final source = await DocsSource.load('site', fileSystem: _seed());
      expect(await source.readPage('/guide'), contains('widgets and gadgets'));
    });

    test('returns null for an unknown path', () async {
      final source = await DocsSource.load('site', fileSystem: _seed());
      expect(await source.readPage('/missing'), isNull);
    });

    test('returns null when the manifest lists a page whose md file is missing', () async {
      final fs = MockFileSystem()
        ..addFile('site/llms.json', '{"name":"X","pages":[{"path":"/gone","title":"Gone","md":"/gone.md"}]}');
      final source = await DocsSource.load('site', fileSystem: fs);
      expect(await source.readPage('/gone'), isNull);
    });
  });

  group('DocsSource.search', () {
    test('finds pages by body text and returns a snippet', () async {
      final source = await DocsSource.load('site', fileSystem: _seed());
      final hits = await source.search('widgets');

      expect(hits, hasLength(1));
      expect(hits.single.page.path, '/guide');
      expect(hits.single.snippet.toLowerCase(), contains('widgets'));
    });

    test('empty/whitespace query returns no hits', () async {
      final source = await DocsSource.load('site', fileSystem: _seed());
      expect(await source.search('   '), isEmpty);
    });

    test('ranks a title match above a body-only match', () async {
      final fs = MockFileSystem()
        ..addFile(
            'site/llms.json',
            '{"name":"X","pages":['
                '{"path":"/a","title":"Widgets","md":"/a.md"},'
                '{"path":"/b","title":"Other","md":"/b.md"}]}')
        ..addFile('site/a.md', 'nothing relevant here')
        ..addFile('site/b.md', 'widgets widgets widgets');
      final source = await DocsSource.load('site', fileSystem: fs);

      final hits = await source.search('widgets');
      expect(hits.map((h) => h.page.path), ['/a', '/b']);
    });

    test('respects the result limit', () async {
      final fs = MockFileSystem()
        ..addFile(
            'site/llms.json',
            '{"name":"X","pages":['
                '{"path":"/a","title":"Alpha","md":"/a.md"},'
                '{"path":"/b","title":"Beta","md":"/b.md"}]}')
        ..addFile('site/a.md', 'topic topic')
        ..addFile('site/b.md', 'topic');
      final source = await DocsSource.load('site', fileSystem: fs);

      expect(await source.search('topic', limit: 1), hasLength(1));
    });
  });
}
