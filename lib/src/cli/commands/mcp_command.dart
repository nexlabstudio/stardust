import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../mcp/docs_source.dart';
import '../../mcp/mcp_server.dart';
import '../../utils/exceptions.dart';
import '../../utils/logger.dart';
import '../../version.dart';

/// Serve a built Stardust site's docs to AI clients (Claude Desktop, Cursor)
/// over MCP on the stdio transport.
class McpCommand extends Command<int> {
  final FileSystem fileSystem;

  @override
  final name = 'mcp';

  @override
  final description = 'Serve a built site to AI clients over MCP (stdio)';

  @override
  String get invocation => 'stardust mcp [dir]';

  McpCommand({FileSystem? fileSystem}) : fileSystem = fileSystem ?? const LocalFileSystem() {
    argParser
      ..addOption('config',
          abbr: 'c', help: 'Path to stardust.yaml (used only to resolve the output dir)', defaultsTo: 'stardust.yaml')
      ..addFlag('verbose', abbr: 'v', help: 'Verbose logging (to stderr)', negatable: false);
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    // stdout is reserved for MCP protocol frames — every log line goes to stderr.
    final logger = Logger(onLog: stderr.writeln, onError: stderr.writeln);
    final configPath = args['config'] as String;

    final dir = switch (args.rest) {
      [final dir, ...] => dir,
      [] when await fileSystem.fileExists(configPath) =>
        p.normalize((await ConfigLoader.load(configPath, logger: logger)).build.outDir),
      [] => 'dist',
    };

    try {
      final source = await DocsSource.load(dir, fileSystem: fileSystem, logger: logger);
      logger.log('📡 stardust mcp — serving ${source.pages.length} pages from $dir/ over stdio');
      final server = McpServer(source, name: source.siteName, version: version, logger: logger);
      final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
      await server.serve(lines, stdout.writeln);
      return 0;
    } on ContentException catch (e) {
      stderr.writeln('❌ ${e.message}');
      return 1;
    }
  }
}
