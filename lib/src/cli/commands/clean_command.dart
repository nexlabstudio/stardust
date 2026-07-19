import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../utils/logger.dart';
import '../output_guard.dart';

/// Delete Stardust build outputs and caches
class CleanCommand extends Command<int> {
  final FileSystem fileSystem;
  final Logger Function() loggerFactory;

  @override
  final name = 'clean';

  @override
  final description = 'Delete build output, dev output, and caches';

  CleanCommand({
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
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final logger = loggerFactory();
    final configPath = args['config'] as String;

    final outDir = switch (await fileSystem.fileExists(configPath)) {
      true => p.normalize((await ConfigLoader.load(configPath, logger: logger)).build.outDir),
      false => 'dist',
    };

    var removed = 0;
    if (await fileSystem.directoryExists(outDir)) {
      if (await unsafeCleanReason(fileSystem, outDir) case final reason?) {
        logger.error('⏭️  Skipping "$outDir": $reason');
      } else {
        await fileSystem.deleteDirectory(outDir, recursive: true);
        logger.log('🧹 Removed $outDir/');
        removed++;
      }
    }

    for (final dir in ['.stardust', p.join('.dart_tool', 'stardust')]) {
      if (await fileSystem.directoryExists(dir)) {
        await fileSystem.deleteDirectory(dir, recursive: true);
        logger.log('🧹 Removed $dir/');
        removed++;
      }
    }

    logger.log(removed == 0 ? '✨ Nothing to clean' : '✨ Clean');
    return 0;
  }
}
