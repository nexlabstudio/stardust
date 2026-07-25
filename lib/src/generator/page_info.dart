import 'dart:io';

/// A file's git history summary: when it last changed and who has touched it.
class GitFileMeta {
  final DateTime lastModified;
  final List<String> authors;

  const GitFileMeta({required this.lastModified, required this.authors});
}

/// Estimated reading time in minutes for rendered [html], at ~200 words/min.
/// Returns 0 for empty content so the caller can omit the label.
int readingMinutes(String html) {
  final words = html.replaceAll(RegExp(r'<[^>]+>'), ' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return words == 0 ? 0 : (words / 200).ceil();
}

/// Parses `git log --format=':%aI\t%an' --name-only` output into per-file
/// history. Git logs newest-first, so a file's first appearance is its last
/// modification; authors accumulate across appearances, most-recent first.
Map<String, GitFileMeta> parseGitLog(String output) {
  final dates = <String, DateTime>{};
  final authors = <String, List<String>>{};
  DateTime? date;
  String? author;

  for (final line in output.split('\n')) {
    if (line.startsWith(':')) {
      final parts = line.substring(1).split('\t');
      date = DateTime.tryParse(parts.first);
      author = parts.length > 1 ? parts[1] : null;
      continue;
    }
    final file = line.trim();
    if (file.isEmpty || date == null) continue;

    final commitDate = date;
    dates.putIfAbsent(file, () => commitDate);
    final contributors = authors.putIfAbsent(file, () => []);
    if (author case final name? when !contributors.contains(name)) contributors.add(name);
  }

  return {
    for (final MapEntry(:key, :value) in dates.entries)
      key: GitFileMeta(lastModified: value, authors: authors[key] ?? const []),
  };
}

/// Collects per-file git history in a single `git log` pass.
class GitMetadataCollector {
  final String? workingDirectory;

  const GitMetadataCollector({this.workingDirectory});

  /// The repository root and its per-file history (keyed by root-relative path),
  /// or null when git is unavailable or the tree isn't a repository. The root is
  /// resolved with `rev-parse` so callers can match files regardless of `cwd`.
  ///
  /// [scope] limits the history walk to a pathspec (e.g. the content directory)
  /// so the log stays proportional to the docs rather than the whole repository;
  /// emitted paths remain root-relative regardless.
  Future<({String root, Map<String, GitFileMeta> files})?> collect({String? scope}) async {
    try {
      final top = await Process.run('git', ['rev-parse', '--show-toplevel'], workingDirectory: workingDirectory);
      if (top.exitCode != 0) return null;

      final log = await Process.run(
        'git',
        [
          'log',
          '--no-merges',
          '--format=:%aI%x09%an',
          '--name-only',
          if (scope case final scope?) ...['--', scope]
        ],
        workingDirectory: workingDirectory,
      );
      if (log.exitCode != 0) return null;

      return (root: '${top.stdout}'.trim(), files: parseGitLog('${log.stdout}'));
    } on ProcessException {
      return null;
    }
  }
}
