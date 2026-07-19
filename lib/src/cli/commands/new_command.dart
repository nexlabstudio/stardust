import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../utils/logger.dart';

/// Scaffold a new documentation page in the content directory
class NewCommand extends Command<int> {
  final FileSystem fileSystem;
  final Logger Function() loggerFactory;

  @override
  final name = 'new';

  @override
  final description = 'Create a new documentation page';

  @override
  String get invocation => 'stardust new <slug>';

  NewCommand({
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
      'title',
      abbr: 't',
      help: 'Page title (defaults to the slug in title case)',
    );
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final logger = loggerFactory();
    final slug = switch (args.rest) {
      [final slug] => slug.replaceAll(RegExp(r'^/+|\.mdx?$'), ''),
      _ => null,
    };
    if (slug == null || slug.isEmpty) {
      logger.error('❌ Usage: stardust new <slug>');
      logger.error('   Examples: stardust new getting-started, stardust new guides/install');
      return 64;
    }

    final configPath = args['config'] as String;
    final contentDir = switch (await fileSystem.fileExists(configPath)) {
      true => (await ConfigLoader.load(configPath, logger: logger)).content.dir,
      false => 'docs',
    };

    final filePath = p.join(contentDir, '$slug.md');
    if (await fileSystem.fileExists(filePath)) {
      logger.error('❌ $filePath already exists');
      return 1;
    }

    final title = args['title'] as String? ?? _titleCase(p.basename(slug));
    await fileSystem.writeFile(filePath, '''
---
title: $title
description: ""
---

# $title

Write your content here.
''');

    logger.log('✅ Created $filePath');
    logger.log('');
    logger.log('   Add it to your sidebar in $configPath:');
    logger.log('     - slug: $slug');
    logger.log('       label: $title');
    return 0;
  }

  String _titleCase(String slug) => slug
      .replaceAll(RegExp(r'[-_]'), ' ')
      .split(' ')
      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
