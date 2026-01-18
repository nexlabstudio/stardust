import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../../config/config_loader.dart';
import '../../generator/site_generator.dart';

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
      defaultsTo: 'docs.yaml',
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
  }

  @override
  Future<int> run() async {
    final stopwatch = Stopwatch()..start();
    final configPath = argResults!['config'] as String;
    final outputDir = argResults!['output'] as String;
    final clean = argResults!['clean'] as bool;
    final verbose = argResults!['verbose'] as bool;

    print('🔨 Building Stardust site...');
    print('');

    // Load config
    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      print('❌ Config file not found: $configPath');
      print('   Run `stardust init` to create a new project.');
      return 1;
    }

    if (verbose) print('📄 Loading config from $configPath');
    final config = await ConfigLoader.load(configPath);

    // Clean output directory if requested
    final outDir = Directory(outputDir);
    if (clean && outDir.existsSync()) {
      if (verbose) print('🧹 Cleaning output directory');
      await outDir.delete(recursive: true);
    }
    await outDir.create(recursive: true);

    // Generate site
    final generator = SiteGenerator(
      config: config,
      outputDir: outputDir,
      onError: (message) => stderr.writeln(message),
      onLog: (message) => stdout.writeln(message),
    );

    try {
      final pageCount = await generator.generate();

      stopwatch.stop();
      print('');
      print('✅ Built $pageCount pages in ${stopwatch.elapsedMilliseconds}ms');
      print('   Output: ${p.absolute(outputDir)}');
      print('');

      return 0;
    } catch (e, stackTrace) {
      print('❌ Build failed: $e');
      if (verbose) print(stackTrace);
      return 1;
    }
  }
}
