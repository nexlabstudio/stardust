import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:watcher/watcher.dart';
import '../../config/config_loader.dart';
import '../../generator/site_generator.dart';
import '../../utils/logger.dart';

/// Development server with hot reload
class DevCommand extends Command<int> {
  @override
  final name = 'dev';

  @override
  final description = 'Start development server with hot reload';

  DevCommand() {
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
    argParser.addFlag(
      'open',
      abbr: 'o',
      help: 'Open browser automatically',
      defaultsTo: false,
    );
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final configPath = args['config'] as String;
    final port = int.parse(args['port'] as String);
    final host = args['host'] as String;
    final openBrowser = args['open'] as bool;

    // Load config
    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      stderr.writeln('❌ Config file not found: $configPath');
      stderr.writeln('   Run `stardust init` to create a new project.');
      return 1;
    }

    var config = await ConfigLoader.load(configPath);
    const outputDir = '.stardust';

    // Initial build
    stdout.writeln('🔨 Building site...');
    final logger = Logger(onLog: stdout.writeln, onError: stderr.writeln);
    var generator = SiteGenerator(config: config, outputDir: outputDir, logger: logger);
    await generator.generate();

    // Create static file handler with live reload injection
    shelf.Handler createHandler() {
      final staticHandler = createStaticHandler(
        outputDir,
        defaultDocument: 'index.html',
      );

      return (shelf.Request request) async {
        final response = await staticHandler(request);

        // Inject live reload script into HTML responses
        if (response.headers['content-type']?.contains('text/html') ?? false) {
          var body = await response.readAsString();
          body = body.replaceFirst(
            '</body>',
            '''
<script>
  const es = new EventSource('/__stardust_reload');
  es.onmessage = () => location.reload();
  es.onerror = () => setTimeout(() => location.reload(), 1000);
</script>
</body>''',
          );
          return response.change(body: body);
        }

        return response;
      };
    }

    // SSE endpoint for live reload
    StreamController<void>? reloadController;

    shelf.Response handleReload(shelf.Request request) {
      if (request.url.path == '__stardust_reload') {
        reloadController?.close();
        // ignore: close_sinks - closed on shutdown or next request
        final controller = StreamController<void>.broadcast();
        reloadController = controller;
        final stream = controller.stream.map((_) => 'data: reload\n\n');

        return shelf.Response.ok(
          stream,
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        );
      }
      return shelf.Response.notFound('Not found');
    }

    // Combined handler
    final handler = const shelf.Pipeline().addMiddleware(shelf.logRequests()).addHandler((request) {
      if (request.url.path == '__stardust_reload') {
        return handleReload(request);
      }
      return createHandler()(request);
    });

    // Start server
    final server = await shelf_io.serve(handler, host, port);
    stdout.writeln('');
    stdout.writeln('  ✨ Stardust dev server running');
    stdout.writeln('');
    stdout.writeln('  ➜ Local:   http://$host:$port/');
    stdout.writeln('');
    stdout.writeln('  Watching for changes...');
    stdout.writeln('');

    if (openBrowser) {
      await _openBrowser('http://$host:$port/');
    }

    // Watch for changes
    final contentDir = config.content.dir;
    final watcher = DirectoryWatcher(contentDir);
    final configWatcher = FileWatcher(configPath);

    final subscriptions = <StreamSubscription>[];

    // Debounce rebuilds
    Timer? debounceTimer;

    Future<void> rebuild({bool reloadConfig = false}) async {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 100), () async {
        stdout.writeln('🔄 Rebuilding...');

        try {
          if (reloadConfig) {
            config = await ConfigLoader.load(configPath);
            generator = SiteGenerator(config: config, outputDir: outputDir, logger: logger);
          }

          await generator.generate();
          reloadController?.add(null);
          stdout.writeln('✅ Done');
        } catch (e) {
          stderr.writeln('❌ Build error: $e');
        }
      });
    }

    subscriptions.add(watcher.events.listen((event) {
      if (event.path.endsWith('.md') || event.path.endsWith('.mdx')) {
        stdout.writeln('📝 ${p.basename(event.path)} changed');
        rebuild();
      }
    }));

    subscriptions.add(configWatcher.events.listen((event) {
      stdout.writeln('⚙️  Config changed');
      rebuild(reloadConfig: true);
    }));

    // Handle shutdown
    ProcessSignal.sigint.watch().listen((_) async {
      stdout.writeln('\n👋 Shutting down...');
      for (final sub in subscriptions) {
        await sub.cancel();
      }
      await reloadController?.close();
      await server.close();
      exit(0);
    });

    // Keep running
    await Completer<void>().future;

    return 0;
  }

  Future<void> _openBrowser(String url) async {
    final (cmd, args, shell) = switch (Platform.operatingSystem) {
      'macos' => ('open', [url], false),
      'linux' => ('xdg-open', [url], false),
      'windows' => ('start', [url], true),
      _ => (null, <String>[], false),
    };
    if (cmd == null) return;
    try {
      await Process.run(cmd, args, runInShell: shell);
    } catch (_) {}
  }
}
