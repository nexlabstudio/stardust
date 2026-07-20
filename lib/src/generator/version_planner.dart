import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../config/config.dart';
import '../core/file_system.dart';

/// One version to build during `stardust build --all-versions`: where its
/// content comes from, where it is written, and how its URLs are prefixed.
class VersionBuildTask {
  final VersionEntry entry;
  final VersionSource source;
  final String outputDir;
  final String? versionBasePath;
  final bool noindex;

  const VersionBuildTask({
    required this.entry,
    required this.source,
    required this.outputDir,
    required this.versionBasePath,
    required this.noindex,
  });
}

/// Plans the per-version builds for [config] writing under [baseOutputDir].
///
/// Pure (no IO) so the routing math stays unit-testable. A version whose
/// [VersionEntry.source] is unset builds from the live content dir; a version
/// whose path is `/` builds at the site root, others under their path segment.
/// Every version except [VersionsConfig.current] is marked `noindex`.
List<VersionBuildTask> planVersionBuilds(StardustConfig config, String baseOutputDir) {
  final versions = config.versions;
  if (versions == null) return const [];

  final base = config.basePath;
  final tasks = <VersionBuildTask>[];
  for (final entry in versions.list) {
    final segment = entry.path.replaceAll(RegExp(r'^/+|/+$'), '');
    tasks.add(VersionBuildTask(
      entry: entry,
      source: entry.source ?? DirSource(config.content.dir),
      outputDir: segment.isEmpty ? baseOutputDir : p.join(baseOutputDir, segment),
      versionBasePath: segment.isEmpty ? (base.isEmpty ? null : base) : '$base/$segment',
      noindex: versions.current != null && entry.version != versions.current,
    ));
  }
  return tasks;
}

/// The site-root page paths (e.g. `/`, `/guide`) a version would emit from
/// [contentDir], for a page-preserving version switcher. Mirrors the build's
/// slug rule but reads only the filesystem — drafts are indexed here even
/// though the build skips them, so a switcher link to a draft falls through
/// to that version's root on click rather than resolving.
Future<Set<String>> discoverPagePaths(FileSystem fileSystem, String contentDir, ContentConfig content) async {
  if (!await fileSystem.directoryExists(contentDir)) return const {};

  final includes = content.include.map(Glob.new).toList();
  final excludes = content.exclude.map(Glob.new).toList();
  final paths = <String>{};
  await for (final entity in fileSystem.listDirectory(contentDir, recursive: true)) {
    final path = entity.path;
    if (!path.endsWith('.md') && !path.endsWith('.mdx')) continue;
    final relative = p.relative(path, from: contentDir).replaceAll('\\', '/');
    if (includes.isNotEmpty && !includes.any((g) => g.matches(relative))) continue;
    if (excludes.any((g) => g.matches(relative))) continue;
    final slug = p.withoutExtension(relative);
    paths.add(slug == 'index' ? '/' : '/$slug');
  }
  return paths;
}
