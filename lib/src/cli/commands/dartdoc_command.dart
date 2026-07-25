import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/config_loader.dart';
import '../../dartdoc/dartdoc_generator.dart';
import '../../utils/logger.dart';

/// Import a Dart package's API reference (via `dart doc`) into the Stardust site.
class DartdocCommand extends Command<int> {
  @override
  final name = 'dartdoc';

  @override
  final description = "Import a Dart package's API docs (via `dart doc`) into your Stardust site";

  DartdocCommand() {
    argParser
      ..addOption('output', abbr: 'o', help: 'Output directory for the API docs', defaultsTo: 'public/api')
      ..addOption('config', abbr: 'c', help: 'Path to stardust.yaml', defaultsTo: 'stardust.yaml')
      ..addFlag('verbose', abbr: 'v', help: 'Verbose output', negatable: false);
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final packagePath = args.rest.isNotEmpty ? args.rest.first : '.';
    final outputDir = args['output'] as String;
    final configPath = args['config'] as String;

    if (!File(configPath).existsSync()) {
      stderr.writeln('❌ Config file not found: $configPath');
      return 1;
    }
    if (!File(p.join(packagePath, 'pubspec.yaml')).existsSync()) {
      stderr.writeln('❌ Not a Dart package (no pubspec.yaml found in "$packagePath")');
      return 1;
    }

    final logger = Logger(onLog: stdout.writeln, onError: stderr.writeln);

    try {
      final config = await ConfigLoader.load(configPath, logger: logger);
      final pages = await DartdocGenerator(
        packagePath: packagePath,
        outputDir: outputDir,
        config: config,
        logger: logger,
      ).generate();

      if (pages == 0) {
        stderr.writeln('❌ No API pages generated');
        return 1;
      }

      stdout.writeln('');
      stdout.writeln('📁 Output: ${p.absolute(outputDir)}');
      stdout.writeln('');
      stdout.writeln('Next steps:');
      stdout.writeln('  1. Add a nav/sidebar link to your API docs (mounted at /api/ when output is public/api)');
      stdout.writeln('  2. Run `stardust build` — the pages are copied into the site and indexed for search');
      stdout.writeln('');
      return 0;
    } catch (e) {
      stderr.writeln('❌ dartdoc import failed: $e');
      return 1;
    }
  }
}
