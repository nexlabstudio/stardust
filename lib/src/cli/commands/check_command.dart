import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../check/site_checker.dart';
import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../utils/logger.dart';

/// Validate internal links, anchors, images, and sidebar entries
class CheckCommand extends Command<int> {
  final FileSystem fileSystem;
  final Logger Function() loggerFactory;

  @override
  final name = 'check';

  @override
  final description = 'Check for broken links, missing images, and orphaned sidebar entries';

  CheckCommand({
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

    if (!await fileSystem.fileExists(configPath)) {
      logger.error('❌ Config file not found: $configPath');
      return 1;
    }

    final config = await ConfigLoader.load(configPath, logger: logger);
    final checker = SiteChecker(config: config, fileSystem: fileSystem);
    final issues = await checker.check(config.content.dir);

    final errors = issues.where((issue) => !issue.isWarning).toList();
    final warnings = issues.where((issue) => issue.isWarning).toList();

    for (final issue in issues) {
      final label = issue.isWarning ? '⚠️ ' : '❌';
      logger.error('$label ${p.relative(issue.source)}: ${issue.message}');
    }

    if (issues.isEmpty) {
      logger.log('✅ No issues found');
      return 0;
    }

    logger.log('');
    logger.log('${errors.length} error(s), ${warnings.length} warning(s)');
    return errors.isEmpty ? 0 : 1;
  }
}
