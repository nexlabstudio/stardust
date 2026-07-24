import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stardust/src/generator/page_info.dart';
import 'package:test/test.dart';

void main() {
  group('readingMinutes', () {
    test('is 0 for empty content', () {
      expect(readingMinutes(''), 0);
      expect(readingMinutes('<p></p>'), 0);
    });

    test('rounds up and ignores HTML tags', () {
      expect(readingMinutes('<p>one two three</p>'), 1);
      expect(readingMinutes(List.filled(201, 'word').join(' ')), 2);
    });
  });

  group('parseGitLog', () {
    test('takes the newest date per file and accumulates unique authors', () {
      const output = ':2026-07-24T10:00:00Z\tAlice\n'
          '\n'
          'docs/index.md\n'
          'docs/guide.md\n'
          ':2026-07-20T09:00:00Z\tBob\n'
          '\n'
          'docs/guide.md\n'
          ':2026-07-19T08:00:00Z\tAlice\n'
          '\n'
          'docs/guide.md\n';

      final meta = parseGitLog(output);

      expect(meta['docs/index.md']!.lastModified, DateTime.parse('2026-07-24T10:00:00Z'));
      expect(meta['docs/index.md']!.authors, ['Alice']);

      // guide's newest touch is Alice's 07-24 commit; Bob added later, Alice deduped.
      expect(meta['docs/guide.md']!.lastModified, DateTime.parse('2026-07-24T10:00:00Z'));
      expect(meta['docs/guide.md']!.authors, ['Alice', 'Bob']);
    });

    test('returns empty for empty output', () {
      expect(parseGitLog(''), isEmpty);
    });
  });

  group('GitMetadataCollector', () {
    test('collects history and the repo root from a real repository', () async {
      final repo = await Directory.systemTemp.createTemp('stardust-gitmeta-');
      Future<void> git(List<String> args) async {
        final r = await Process.run('git', args, workingDirectory: repo.path);
        if (r.exitCode != 0) throw StateError('git ${args.join(' ')}: ${r.stderr}');
      }

      try {
        await git(['init', '-q']);
        await git(['config', 'user.email', 't@t.com']);
        await git(['config', 'user.name', 'Tester']);
        await File(p.join(repo.path, 'doc.md')).writeAsString('# Doc');
        await git(['add', '-A']);
        await git(['commit', '-qm', 'add doc']);

        final result = await GitMetadataCollector(workingDirectory: repo.path).collect();

        expect(result?.root, isNotEmpty);
        expect(result?.files['doc.md']?.authors, ['Tester']);
      } finally {
        await repo.delete(recursive: true);
      }
    });

    test('returns null outside a git repository', () async {
      final dir = await Directory.systemTemp.createTemp('stardust-nogit-');
      try {
        expect(await GitMetadataCollector(workingDirectory: dir.path).collect(), isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
