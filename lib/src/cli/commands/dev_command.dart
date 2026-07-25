import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:watcher/watcher.dart';
import '../../config/config_loader.dart';
import '../../core/file_system.dart';
import '../../core/stardust_factory.dart';
import '../../search/pagefind_runner.dart';
import '../../utils/logger.dart';

class DevCommand extends Command<int> {
  final FileSystem fileSystem;
  final Logger Function() loggerFactory;

  @override
  final name = 'dev';

  @override
  final description = 'Start development server with hot reload';

  DevCommand({
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
    argParser.addFlag(
      'open',
      help: 'Open browser automatically',
      defaultsTo: false,
    );
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final logger = loggerFactory();
    final configPath = args['config'] as String;
    final port = int.tryParse(args['port'] as String);
    if (port == null || port < 0 || port > 65535) {
      logger.error('❌ Invalid port: ${args['port']}');
      return 1;
    }
    final host = args['host'] as String;
    final openBrowser = args['open'] as bool;

    if (!await fileSystem.fileExists(configPath)) {
      logger.error('❌ Config file not found: $configPath');
      logger.error('   Run `stardust init` to create a new project.');
      return 1;
    }

    var config = (await ConfigLoader.load(configPath, logger: logger)).withDevMode();
    const outputDir = '.stardust';

    logger.log('🔨 Building site...');
    final factory = StardustFactory(fileSystem: fileSystem, logger: logger);
    var generator = factory.createSiteGenerator(config: config, outputDir: outputDir);
    await generator.generate();

    if (config.search.enabled) {
      logger.log('🔍 Building search index...');
      if (!await PagefindRunner.run(outputDir, logger: logger)) {
        logger.error('⚠️  Search indexing failed — continuing without search');
      }
    }

    final staticHandler = createStaticHandler(
      outputDir,
      defaultDocument: 'index.html',
    );

    Future<shelf.Response> serveWithReloadScript(shelf.Request request) async {
      final response = await staticHandler(request);

      if (response.headers['content-type']?.contains('text/html') ?? false) {
        final body = (await response.readAsString()).replaceFirst(
          '</body>',
          '''
<script>
  const es = new EventSource('/__stardust_reload');
  let lostConnection = false;
  es.onmessage = () => location.reload();
  es.onerror = () => { lostConnection = true; };
  es.onopen = () => { if (lostConnection) location.reload(); };
</script>
</body>''',
        );
        // content-length must be dropped: the body just grew past the original header
        return response.change(body: body, headers: {'content-length': null});
      }

      return response;
    }

    final reloadClients = <StreamController<List<int>>>{};

    shelf.Response handleReload() {
      final controller = StreamController<List<int>>();
      reloadClients.add(controller);
      controller.onCancel = () => reloadClients.remove(controller);
      controller.add(utf8.encode(': connected\n\n'));

      return shelf.Response.ok(
        controller.stream,
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
        // shelf_io buffers streamed bodies by default; SSE needs every event flushed
        context: {'shelf.io.buffer_output': false},
      );
    }

    void notifyReload() {
      for (final client in reloadClients.toList()) {
        client.add(utf8.encode('data: reload\n\n'));
      }
    }

    final handler = const shelf.Pipeline().addMiddleware(shelf.logRequests()).addHandler((request) {
      if (request.url.path == '__stardust_reload') {
        return handleReload();
      }
      return serveWithReloadScript(request);
    });

    final server = await shelf_io.serve(handler, host, port);
    logger.log('');
    logger.log('  ✨ Stardust dev server running');
    logger.log('');
    logger.log('  ➜ Local:   http://$host:$port/');
    logger.log('');
    logger.log('  Watching for changes...');
    logger.log('');

    if (openBrowser) {
      await _openBrowser('http://$host:$port/');
    }

    final contentDir = config.content.dir;
    final assetsDir = config.build.assets.dir;
    final contentWatcher = DirectoryWatcher(contentDir);
    final configWatcher = FileWatcher(configPath);

    final subscriptions = <StreamSubscription>[];

    // Debounced, non-overlapping rebuilds: events during a build queue exactly
    // one trailing rebuild instead of running concurrently.
    Timer? debounceTimer;
    var building = false;
    var rebuildQueued = false;
    var configDirty = false;

    Future<void> runRebuild() async {
      if (building) {
        rebuildQueued = true;
        return;
      }
      building = true;
      logger.log('🔄 Rebuilding...');

      try {
        if (configDirty) {
          configDirty = false;
          config = (await ConfigLoader.load(configPath, logger: logger)).withDevMode();
          generator = factory.createSiteGenerator(config: config, outputDir: outputDir);
        }

        await generator.generate();

        if (config.search.enabled) {
          if (!await PagefindRunner.run(outputDir, logger: logger)) {
            logger.error('⚠️  Search re-index failed — search results may be stale');
          }
        }

        notifyReload();
        logger.log('✅ Done');
      } catch (e) {
        logger.error('❌ Build error: $e');
      } finally {
        building = false;
      }

      if (rebuildQueued) {
        rebuildQueued = false;
        await runRebuild();
      }
    }

    void rebuild({bool reloadConfig = false}) {
      configDirty = configDirty || reloadConfig;
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 100), runRebuild);
    }

    subscriptions.add(contentWatcher.events.listen((event) {
      if (event.path.endsWith('.md') || event.path.endsWith('.mdx')) {
        logger.log('📝 ${p.basename(event.path)} changed');
        rebuild();
      }
    }));

    if (await fileSystem.directoryExists(assetsDir)) {
      final assetsWatcher = DirectoryWatcher(assetsDir);
      subscriptions.add(assetsWatcher.events.listen((event) {
        logger.log('📦 ${p.basename(event.path)} changed');
        rebuild();
      }));
    }

    subscriptions.add(configWatcher.events.listen((event) {
      logger.log('⚙️  Config changed');
      rebuild(reloadConfig: true);
    }));

    ProcessSignal.sigint.watch().listen((_) async {
      logger.log('\n👋 Shutting down...');
      for (final sub in subscriptions) {
        await sub.cancel();
      }
      for (final client in reloadClients.toList()) {
        await client.close();
      }
      await server.close();
      exit(0);
    });

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
