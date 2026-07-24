import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../../config/config.dart';
import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../core/stardust_factory.dart';
import '../../generator/locale_materializer.dart';
import '../../generator/locale_planner.dart';
import '../../generator/redirect_generator.dart';
import '../../generator/robots_generator.dart';
import '../../generator/version_planner.dart';
import '../../generator/version_source_resolver.dart';
import '../../search/pagefind_runner.dart';
import '../../utils/logger.dart';
import '../output_guard.dart';

class BuildCommand extends Command<int> {
  static const buildMarker = outputGuardMarker;

  final FileSystem fileSystem;
  final Logger Function() loggerFactory;

  @override
  final name = 'build';

  @override
  final description = 'Build static documentation site';

  BuildCommand({
    FileSystem? fileSystem,
    Logger Function()? loggerFactory,
  })  : fileSystem = fileSystem ?? const LocalFileSystem(),
        loggerFactory = loggerFactory ?? (() => Logger(onLog: stdout.writeln, onError: stderr.writeln)) {
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to config file',
      defaultsTo: 'stardust.yaml',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory (defaults to build.outDir from stardust.yaml, or dist/)',
    );
    argParser.addFlag(
      'clean',
      help: 'Clean output directory before building',
      defaultsTo: true,
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      negatable: false,
    );
    argParser.addFlag(
      'skip-search',
      help: 'Skip search index generation',
      negatable: false,
    );
    argParser.addFlag(
      'all-versions',
      help: 'Build every entry in versions.list into its own path prefix',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final logger = loggerFactory();
    final stopwatch = Stopwatch()..start();
    final configPath = args['config'] as String;
    final clean = args['clean'] as bool;
    final verbose = args['verbose'] as bool;
    final skipSearch = args['skip-search'] as bool;
    final allVersions = args['all-versions'] as bool;

    logger.log('🔨 Building Stardust site...');
    logger.log('');

    if (!await fileSystem.fileExists(configPath)) {
      logger.error('❌ Config file not found: $configPath');
      logger.error('   Run `stardust init` to create a new project.');
      return 1;
    }

    if (verbose) logger.log('📄 Loading config from $configPath');
    final config = await ConfigLoader.load(configPath, logger: logger);
    final outputDir = p.normalize(switch (args['output']) {
      final String output when args.wasParsed('output') => output,
      _ => config.build.outDir,
    });

    final cleanRequested = clean && await fileSystem.directoryExists(outputDir);
    if (cleanRequested) {
      if (await unsafeCleanReason(fileSystem, outputDir) case final reason?) {
        logger.error('❌ Refusing to clean "$outputDir": $reason.');
        logger.error('   Use --no-clean, pick a different --output, or delete the directory manually.');
        return 1;
      }

      if (verbose) logger.log('🧹 Cleaning output directory');
      await fileSystem.deleteDirectory(outputDir, recursive: true);
    }
    await fileSystem.createDirectory(outputDir, recursive: true);
    await fileSystem.writeFile(p.join(outputDir, buildMarker), buildMarkerContent);

    final factory = StardustFactory(fileSystem: fileSystem, logger: logger);

    final i18n = config.i18n;
    final multiLocale = i18n != null && i18n.enabled && i18n.locales.length > 1;

    try {
      final pageCount = switch ((allVersions, multiLocale)) {
        (true, _) =>
          await _buildAllVersions(factory, config, outputDir, skipSearch: skipSearch, verbose: verbose, logger: logger),
        (false, true) =>
          await _buildAllLocales(factory, config, outputDir, skipSearch: skipSearch, verbose: verbose, logger: logger),
        (false, false) =>
          await _buildOne(factory, config, outputDir, skipSearch: skipSearch, verbose: verbose, logger: logger),
      };
      if (pageCount == null) return 1;

      stopwatch.stop();
      logger.log('');
      logger.log('✅ Built $pageCount pages in ${stopwatch.elapsedMilliseconds}ms');
      logger.log('   Output: ${p.absolute(outputDir)}');
      logger.log('');

      return 0;
    } catch (e, stackTrace) {
      logger.error('❌ Build failed: $e');
      if (verbose) logger.error('$stackTrace');
      return 1;
    }
  }

  Future<int?> _buildAllVersions(
    StardustFactory factory,
    StardustConfig config,
    String outputDir, {
    required bool skipSearch,
    required bool verbose,
    required Logger logger,
  }) async {
    final versions = config.versions;
    if (versions == null || !versions.enabled || versions.list.isEmpty) {
      logger.error('❌ --all-versions needs a versions.list in your config. See the versioning docs.');
      return null;
    }
    if (versions.current == null) {
      logger.error('❌ --all-versions needs versions.current set to the canonical (indexed) version.');
      return null;
    }

    final resolver = VersionSourceResolver();
    try {
      final resolved = <({VersionBuildTask task, String dir})>[];
      final versionPages = <String, Set<String>>{};
      for (final task in planVersionBuilds(config, outputDir)) {
        final dir = await resolver.resolve(task.source, config.content.dir);
        resolved.add((task: task, dir: dir));
        versionPages[task.entry.version] = await discoverPagePaths(fileSystem, dir, config.content);
      }

      var total = 0;
      for (final (:task, :dir) in resolved) {
        final label = task.entry.label ?? 'v${task.entry.version}';
        logger.log('📦 $label → ${p.relative(task.outputDir)}${task.noindex ? '  (noindex)' : ''}');
        final versioned = config.withVersion(
          task.entry,
          source: dir,
          versionBasePath: task.versionBasePath,
          versionPages: versionPages,
          sidebar: task.entry.sidebar ?? sidebarForVersion(config.sidebar, versionPages[task.entry.version]),
        );
        final count = await _buildOne(factory, versioned, task.outputDir,
            skipSearch: skipSearch, verbose: verbose, logger: logger);
        if (count == null) return null;
        total += count;
      }

      final tasks = [for (final r in resolved) r.task];
      if (rootRedirectTarget(tasks, outputDir, config.versions?.current) case final target?) {
        await RedirectGenerator(outputDir: outputDir, fileSystem: fileSystem, logger: logger)
            .writeRootIndexRedirect(target);
      }
      if (config.build.robots.enabled) {
        await RobotsGenerator(
          outputDir: outputDir,
          robots: config.build.robots,
          sitemapUrl: currentVersionSitemapUrl(config),
          logger: logger,
          fileSystem: fileSystem,
        ).generate();
      }
      return total;
    } finally {
      await resolver.cleanup();
    }
  }

  Future<int?> _buildAllLocales(
    StardustFactory factory,
    StardustConfig config,
    String outputDir, {
    required bool skipSearch,
    required bool verbose,
    required Logger logger,
  }) async {
    final defaultDir = config.content.dir;
    final tasks = planLocaleBuilds(config, outputDir);

    final localeCodes = {
      for (final task in tasks)
        if (!task.isDefault) task.locale.code
    };
    final localeSubdirs = <String>{
      for (final task in tasks)
        if (!task.isDefault && p.isWithin(defaultDir, task.translatedDir))
          p.relative(task.translatedDir, from: defaultDir).replaceAll('\\', '/'),
    };
    final translationExcludes = [
      for (final s in localeSubdirs) '$s/**',
      for (final c in localeCodes) ...['*.$c.md', '**/*.$c.md', '*.$c.mdx', '**/*.$c.mdx'],
    ];

    final materializer = LocaleContentMaterializer(fileSystem: fileSystem);
    try {
      var total = 0;
      LocaleBuildTask? defaultTask;
      for (final task in tasks) {
        if (task.isDefault) defaultTask = task;

        final (dir, untranslated) = task.isDefault
            ? (defaultDir, const <String>{})
            : await materializer
                .materialize(
                  defaultDir: defaultDir,
                  localeCode: task.locale.code,
                  subdir: task.translatedDir,
                  excludeSubdirs: localeSubdirs,
                  localeCodes: localeCodes,
                )
                .then((r) => (r.dir, r.untranslated));

        final suffix = untranslated.isEmpty ? '' : '  (${untranslated.length} untranslated)';
        logger.log('🌐 ${task.locale.label} (${task.locale.code}) → ${p.relative(task.outputDir)}$suffix');

        final localized = config.withLocale(task.locale,
            contentDir: dir,
            localeBasePath: task.localeBasePath,
            untranslatedPaths: untranslated,
            excludeSubdirs: translationExcludes);
        final count = await _buildOne(factory, localized, task.outputDir,
            skipSearch: skipSearch, verbose: verbose, logger: logger);
        if (count == null) return null;
        total += count;
      }

      if (defaultTask != null && defaultTask.outputDir != outputDir) {
        await RedirectGenerator(outputDir: outputDir, fileSystem: fileSystem, logger: logger)
            .writeRootIndexRedirect('${defaultTask.localeBasePath ?? ''}/');
      }
      return total;
    } finally {
      await materializer.cleanup();
    }
  }

  Future<int?> _buildOne(
    StardustFactory factory,
    StardustConfig config,
    String outputDir, {
    required bool skipSearch,
    required bool verbose,
    required Logger logger,
  }) async {
    await fileSystem.createDirectory(outputDir, recursive: true);
    final generator = factory.createSiteGenerator(config: config, outputDir: outputDir);
    final pageCount = await generator.generate();

    if (!skipSearch && config.search.enabled && config.search.provider == 'pagefind') {
      logger.log('');
      logger.log('🔍 Building search index...');
      if (!await PagefindRunner.run(outputDir, verbose: verbose, logger: logger)) {
        logger.error('❌ Search indexing failed. Use --skip-search to build without search.');
        return null;
      }
    }

    return pageCount;
  }
}
