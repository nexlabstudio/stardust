import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../utils/logger.dart';

/// Serve an already-built site without watching or rebuilding
class ServeCommand extends Command<int> {
  final FileSystem fileSystem;
  final Logger Function() loggerFactory;

  @override
  final name = 'serve';

  @override
  final description = 'Preview a built site from the output directory';

  @override
  String get invocation => 'stardust serve [dir]';

  ServeCommand({
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
      'port',
      abbr: 'p',
      help: 'Port to serve on',
      defaultsTo: '4000',
    );
    argParser.addOption(
      'host',
      help: 'Host to bind to',
      defaultsTo: 'localhost',
    );
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final logger = loggerFactory();
    final port = int.tryParse(args['port'] as String);
    if (port == null || port < 0 || port > 65535) {
      logger.error('❌ Invalid port: ${args['port']}');
      return 1;
    }
    final host = args['host'] as String;
    final configPath = args['config'] as String;

    final dir = switch (args.rest) {
      [final dir, ...] => dir,
      [] when await fileSystem.fileExists(configPath) =>
        p.normalize((await ConfigLoader.load(configPath, logger: logger)).build.outDir),
      [] => 'dist',
    };

    if (!await fileSystem.directoryExists(dir)) {
      logger.error('❌ Directory not found: $dir');
      logger.error('   Run `stardust build` first, or pass a directory: stardust serve <dir>');
      return 1;
    }

    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(createStaticHandler(dir, defaultDocument: 'index.html'));

    final server = await shelf_io.serve(handler, host, port);
    logger.log('');
    logger.log('  📦 Serving $dir/');
    logger.log('');
    logger.log('  ➜ Local:   http://$host:$port/');
    logger.log('');

    ProcessSignal.sigint.watch().listen((_) async {
      logger.log('\n👋 Shutting down...');
      await server.close();
      exit(0);
    });

    await Completer<void>().future;
    return 0;
  }
}
