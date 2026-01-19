import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../../config/config_loader.dart';
import '../../generator/site_generator.dart';
import '../../search/pagefind_runner.dart';
import '../../utils/file_utils.dart';
import '../../utils/logger.dart';

/// Build static documentation site
class BuildCommand extends Command<int> {
  @override
  final name = 'build';

  @override
  final description = 'Build static documentation site';

  BuildCommand() {
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to config file',
      defaultsTo: 'stardust.yaml',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory',
      defaultsTo: 'dist',
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

    final stopwatch = Stopwatch()..start();
    final configPath = args['config'] as String;
    final outputDir = args['output'] as String;
    final clean = args['clean'] as bool;
    final verbose = args['verbose'] as bool;
    final skipSearch = args['skip-search'] as bool;

    stdout.writeln('🔨 Building Stardust site...');
    stdout.writeln('');

    // Load config
    if (!FileUtils.fileExists(configPath)) {
      stderr.writeln('❌ Config file not found: $configPath');
      stderr.writeln('   Run `stardust init` to create a new project.');
      return 1;
    }

    if (verbose) stdout.writeln('📄 Loading config from $configPath');
    final config = await ConfigLoader.load(configPath);

    // Clean output directory if requested
    if (clean && FileUtils.directoryExists(outputDir)) {
      if (verbose) stdout.writeln('🧹 Cleaning output directory');
      await FileUtils.deleteDirectory(outputDir);
    }
    await FileUtils.ensureDirectory(outputDir);

    // Generate site
    final logger = Logger(onLog: stdout.writeln, onError: stderr.writeln);
    final generator = SiteGenerator(config: config, outputDir: outputDir, logger: logger);

    try {
      final pageCount = await generator.generate();

      // Run Pagefind if search is enabled
      if (!skipSearch && config.search.enabled && config.search.provider == 'pagefind') {
        stdout.writeln('');
        stdout.writeln('🔍 Building search index...');
        await PagefindRunner.run(outputDir, verbose: verbose, logger: logger);
      }

      stopwatch.stop();
      stdout.writeln('');
      stdout.writeln('✅ Built $pageCount pages in ${stopwatch.elapsedMilliseconds}ms');
      stdout.writeln('   Output: ${p.absolute(outputDir)}');
      stdout.writeln('');

      return 0;
    } catch (e, stackTrace) {
      stderr.writeln('❌ Build failed: $e');
      if (verbose) stderr.writeln(stackTrace);
      return 1;
    }
  }
}
