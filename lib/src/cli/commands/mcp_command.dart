import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../mcp/docs_source.dart';
import '../../mcp/mcp_http_server.dart';
import '../../mcp/mcp_server.dart';
import '../../utils/exceptions.dart';
import '../../utils/logger.dart';
import '../../version.dart';

/// Serve a built Stardust site's docs to AI clients (Claude Desktop, Cursor)
/// over MCP — stdio by default, or Streamable HTTP with `--http`.
class McpCommand extends Command<int> {
  final FileSystem fileSystem;

  @override
  final name = 'mcp';

  @override
  final description = 'Serve a built site to AI clients over MCP (stdio, or --http)';

  @override
  String get invocation => 'stardust mcp [dir]';

  McpCommand({FileSystem? fileSystem}) : fileSystem = fileSystem ?? const LocalFileSystem() {
    argParser
      ..addOption('config',
          abbr: 'c', help: 'Path to stardust.yaml (used only to resolve the output dir)', defaultsTo: 'stardust.yaml')
      ..addFlag('http', help: 'Serve over Streamable HTTP (a live /mcp endpoint) instead of stdio', negatable: false)
      ..addOption('port', abbr: 'p', help: 'Port for --http', defaultsTo: '8080')
      ..addOption('host', help: 'Host to bind for --http', defaultsTo: 'localhost')
      ..addMultiOption('allow-origin',
          help: 'Allowed browser Origin for --http (repeatable; "*" for any). '
              'Loopback origins and non-browser clients are always allowed.')
      ..addFlag('verbose', abbr: 'v', help: 'Verbose logging (to stderr)', negatable: false);
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final http = args['http'] == true;
    // In stdio mode, stdout is the protocol channel, so logs go to stderr only.
    // In HTTP mode, stdout is free — log there like `stardust serve`.
    final logger = http
        ? Logger(onLog: stdout.writeln, onError: stderr.writeln)
        : Logger(onLog: stderr.writeln, onError: stderr.writeln);
    final configPath = args['config'] as String;

    final dir = switch (args.rest) {
      [final dir, ...] => dir,
      [] when await fileSystem.fileExists(configPath) =>
        p.normalize((await ConfigLoader.load(configPath, logger: logger)).build.outDir),
      [] => 'dist',
    };

    try {
      final source = await DocsSource.load(dir, fileSystem: fileSystem, logger: logger);
      final server = McpServer(source, name: source.siteName, version: version, logger: logger);

      if (http) {
        final port = int.tryParse(args['port'] as String);
        if (port == null || port < 0 || port > 65535) {
          stderr.writeln('❌ Invalid port: ${args['port']}');
          return 1;
        }
        return _serveHttp(source, server, logger,
            host: args['host'] as String, port: port, allowedOrigins: (args['allow-origin'] as List<String>).toSet());
      }

      logger.log('📡 stardust mcp — serving ${source.pages.length} pages from $dir/ over stdio');
      final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
      await server.serve(lines, stdout.writeln);
      return 0;
    } on ContentException catch (e) {
      stderr.writeln('❌ ${e.message}');
      return 1;
    }
  }

  Future<int> _serveHttp(
    DocsSource source,
    McpServer server,
    Logger logger, {
    required String host,
    required int port,
    required Set<String> allowedOrigins,
  }) async {
    final mcp = McpHttpServer(server, allowedOrigins: allowedOrigins, logger: logger);
    final handler = const shelf.Pipeline().addMiddleware(shelf.logRequests()).addHandler(mcp.handle);
    final httpServer = await shelf_io.serve(handler, host, port);

    logger.log('');
    logger.log('📡 stardust mcp — serving ${source.pages.length} pages over MCP (Streamable HTTP)');
    logger.log('  ➜ Endpoint: http://$host:$port/${McpHttpServer.endpoint}');
    logger.log('');

    ProcessSignal.sigint.watch().listen((_) async {
      logger.log('\n👋 Shutting down...');
      await httpServer.close();
      exit(0);
    });

    await Completer<void>().future;
    return 0;
  }
}
