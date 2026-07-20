import 'package:path/path.dart' as p;

import '../config/config.dart';

/// One version to build during `stardust build --all-versions`: where its
/// content comes from, where it is written, and how its URLs are prefixed.
class VersionBuildTask {
  final VersionEntry entry;
  final String source;
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
      source: entry.source ?? config.content.dir,
      outputDir: segment.isEmpty ? baseOutputDir : p.join(baseOutputDir, segment),
      versionBasePath: segment.isEmpty ? (base.isEmpty ? null : base) : '$base/$segment',
      noindex: versions.current != null && entry.version != versions.current,
    ));
  }
  return tasks;
}
