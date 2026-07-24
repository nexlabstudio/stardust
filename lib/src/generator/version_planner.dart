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

/// Where a build routed under [path] (e.g. `/v1/`, `/es/`) writes and how its
/// URLs are prefixed, beneath [base] (the site base path) and [baseOutputDir]. A
/// `/` path stays at the root; a null base path means "no prefix".
({String outputDir, String? basePath}) routeUnderPath(String path, String base, String baseOutputDir) {
  final segment = path.replaceAll(RegExp(r'^/+|/+$'), '');
  return (
    outputDir: segment.isEmpty ? baseOutputDir : p.join(baseOutputDir, segment),
    basePath: segment.isEmpty ? (base.isEmpty ? null : base) : '$base/$segment',
  );
}

/// Plans the per-version builds for [config] writing under [baseOutputDir]: a
/// version whose path is `/` builds at the site root, others under their path
/// segment, and every version but [VersionsConfig.current] is marked `noindex`.
List<VersionBuildTask> planVersionBuilds(StardustConfig config, String baseOutputDir) {
  final versions = config.versions;
  if (versions == null) return const [];

  final base = config.basePath;
  final tasks = <VersionBuildTask>[];
  for (final entry in versions.list) {
    final route = routeUnderPath(entry.path, base, baseOutputDir);
    tasks.add(VersionBuildTask(
      entry: entry,
      source: entry.source ?? DirSource(config.content.dir),
      outputDir: route.outputDir,
      versionBasePath: route.basePath,
      noindex: versions.current != null && entry.version != versions.current,
    ));
  }
  return tasks;
}

/// [sidebar] narrowed to the pages a version actually has, so an older version
/// never links to a page added after it. Groups that autogenerate their pages
/// are left alone; groups left with nothing are dropped.
List<SidebarGroup> sidebarForVersion(List<SidebarGroup> sidebar, Set<String>? pagePaths) {
  if (pagePaths == null) return sidebar;

  final groups = <SidebarGroup>[];
  for (final group in sidebar) {
    if (group.autogenerate != null) {
      groups.add(group);
      continue;
    }
    final kept = [
      for (final page in group.pages)
        if (pagePaths.contains(page.slug == 'index' ? '/' : '/${page.slug}')) page,
    ];
    if (kept.isEmpty) continue;
    groups.add(SidebarGroup(
      group: group.group,
      icon: group.icon,
      collapsed: group.collapsed,
      pages: kept,
      autogenerate: group.autogenerate,
    ));
  }
  return groups;
}

/// The root-relative URL the site root should redirect to when the current
/// version builds under a path prefix, or null when it already builds at the
/// root (so the root has real content and needs no redirect).
String? rootRedirectTarget(List<VersionBuildTask> tasks, String baseOutputDir, String? currentVersion) {
  final current = tasks.where((t) => t.entry.version == currentVersion && t.outputDir != baseOutputDir).firstOrNull;
  return current == null ? null : '${current.versionBasePath ?? ''}/';
}

/// The absolute sitemap URL for the site-root `robots.txt`, pointing at the
/// current version's sitemap wherever it lives, or null when there is no site
/// URL or sitemaps are disabled.
String? currentVersionSitemapUrl(StardustConfig config) {
  final url = config.url;
  if (url == null || !config.build.sitemap.enabled) return null;
  final segment = config.versions?.list
          .where((e) => e.version == config.versions?.current)
          .map((e) => e.path.replaceAll(RegExp(r'^/+|/+$'), ''))
          .firstOrNull ??
      '';
  return segment.isEmpty ? '$url/sitemap.xml' : '$url/$segment/sitemap.xml';
}

/// The site-root page paths (e.g. `/`, `/guide`) a version would emit from
/// [contentDir]. Drafts are indexed here even though the build skips them, so a
/// switcher link to one falls back to that version's root rather than resolving.
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
