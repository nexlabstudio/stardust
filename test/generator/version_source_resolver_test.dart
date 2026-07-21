import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/version_source_resolver.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('VersionSourceResolver', () {
    test('passes a directory source through unchanged', () async {
      final resolver = VersionSourceResolver();

      expect(await resolver.resolve(const DirSource('versions/1.0'), 'docs'), 'versions/1.0');

      await resolver.cleanup();
    });

    test('with no working directory, checks a ref out of the process repository', () async {
      // The exact production construction: null workingDirectory → git runs in
      // the process cwd, which under `dart test` is this repository.
      final resolver = VersionSourceResolver();
      try {
        final dir = await resolver.resolve(const GitSource('HEAD'), 'docs');

        expect(Directory(dir).existsSync(), isTrue, reason: 'HEAD:docs checked out');
        expect(Directory(dir).listSync(), isNotEmpty);
      } finally {
        await resolver.cleanup();
      }
    });

    group('git sources', () {
      late Directory repo;

      Future<void> git(List<String> args) async {
        final r = await Process.run('git', args, workingDirectory: repo.path);
        if (r.exitCode != 0) throw StateError('git ${args.join(' ')} failed: ${r.stderr}');
      }

      setUp(() async {
        repo = await Directory.systemTemp.createTemp('stardust-resolver-');
        await git(['init', '-q']);
        await git(['config', 'user.email', 't@t.com']);
        await git(['config', 'user.name', 't']);
        await Directory(p.join(repo.path, 'docs')).create();
        await File(p.join(repo.path, 'docs', 'index.md')).writeAsString('# v1 tagged');
        await git(['add', '-A']);
        await git(['commit', '-qm', 'v1']);
        await git(['tag', 'v1.0.0']);
      });

      tearDown(() async {
        if (repo.existsSync()) await repo.delete(recursive: true);
      });

      test('checks a tag out into a worktree, then cleanup removes it', () async {
        final resolver = VersionSourceResolver(workingDirectory: repo.path);

        final dir = await resolver.resolve(const GitSource('v1.0.0'), 'docs');

        expect(File(p.join(dir, 'index.md')).readAsStringSync(), contains('v1 tagged'));

        await resolver.cleanup();
        expect(Directory(dir).existsSync(), isFalse, reason: 'worktree removed');
      });

      test('throws an actionable error for an unknown ref', () async {
        final resolver = VersionSourceResolver(workingDirectory: repo.path);

        expect(
          () => resolver.resolve(const GitSource('v9.9.9-nope'), 'docs'),
          throwsA(isA<GeneratorException>().having((e) => e.message, 'message', contains('v9.9.9-nope'))),
        );
      });
    });
  });
}
