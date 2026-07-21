import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../utils/exceptions.dart';

/// Resolves a [VersionSource] to a directory to build from: directory sources
/// pass through, git refs are checked out into a throwaway worktree that
/// [cleanup] removes, so building an old tag never disturbs the current checkout.
class VersionSourceResolver {
  /// Repository the `git` commands run in; defaults to the process directory.
  final String? workingDirectory;

  final _worktrees = <({String target, Directory parent})>[];

  VersionSourceResolver({this.workingDirectory});

  Future<String> resolve(VersionSource source, String contentDir) async => switch (source) {
        DirSource(:final dir) => dir,
        GitSource(:final ref) => p.join(await _checkout(ref), contentDir),
      };

  Future<String> _checkout(String ref) async {
    final parent = await Directory.systemTemp.createTemp('stardust-version-');
    final target = p.join(parent.path, 'tree');
    final result = await Process.run(
      'git',
      ['worktree', 'add', '--detach', target, ref],
      workingDirectory: workingDirectory,
    );
    if (result.exitCode != 0) {
      await parent.delete(recursive: true);
      throw GeneratorException('Could not check out version ref "$ref": ${'${result.stderr}'.trim()}');
    }
    _worktrees.add((target: target, parent: parent));
    return target;
  }

  Future<void> cleanup() async {
    for (final (:target, :parent) in _worktrees) {
      await Process.run('git', ['worktree', 'remove', '--force', target], workingDirectory: workingDirectory);
      if (parent.existsSync()) await parent.delete(recursive: true);
    }
    _worktrees.clear();
  }
}
