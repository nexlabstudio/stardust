import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../core/stardust_factory.dart';
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
    final generator = factory.createSiteGenerator(config: config, outputDir: outputDir);

    try {
      final pageCount = await generator.generate();

      if (!skipSearch && config.search.enabled && config.search.provider == 'pagefind') {
        logger.log('');
        logger.log('🔍 Building search index...');
        if (!await PagefindRunner.run(outputDir, verbose: verbose, logger: logger)) {
          logger.error('❌ Search indexing failed. Use --skip-search to build without search.');
          return 1;
        }
      }

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
}
