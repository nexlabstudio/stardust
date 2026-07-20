import '../utils/exceptions.dart';

/// Where a version's content comes from during a `--all-versions` build.
sealed class VersionSource {
  const VersionSource();

  /// A bare string is a content directory; a `{tag: ...}` or `{ref: ...}` map
  /// is a git ref checked out into a throwaway worktree at build time.
  factory VersionSource.fromYaml(Object? yaml) => switch (yaml) {
        final String dir => DirSource(dir),
        {'tag': final String tag} => GitSource(tag),
        {'ref': final String ref} => GitSource(ref),
        _ => throw ConfigException('version source must be a directory or {tag: ...} / {ref: ...} (got $yaml)'),
      };
}

/// A version built from a content directory on disk.
class DirSource extends VersionSource {
  final String dir;

  const DirSource(this.dir);

  @override
  bool operator ==(Object other) => other is DirSource && other.dir == dir;

  @override
  int get hashCode => dir.hashCode;
}

/// A version built from a git tag or ref, checked out at build time.
class GitSource extends VersionSource {
  final String ref;

  const GitSource(this.ref);

  @override
  bool operator ==(Object other) => other is GitSource && other.ref == ref;

  @override
  int get hashCode => ref.hashCode;
}
