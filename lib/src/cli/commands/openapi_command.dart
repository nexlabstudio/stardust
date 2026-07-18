import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../../openapi/openapi_importer.dart';
import '../../utils/logger.dart';

/// Import OpenAPI/Swagger spec and generate documentation
class OpenApiCommand extends Command<int> {
  @override
  final name = 'openapi';

  @override
  final description = 'Generate documentation from OpenAPI/Swagger spec';

  OpenApiCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory for generated docs',
      defaultsTo: 'docs/api',
    );
    argParser.addOption(
      'group-by',
      abbr: 'g',
      help: 'How to group endpoints into pages',
      allowed: ['tag', 'path', 'none'],
      defaultsTo: 'tag',
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
    final args = argResults;
    if (args == null) return 1;

    final rest = args.rest;
    if (rest.isEmpty) {
      stderr.writeln('❌ Error: Please specify an OpenAPI spec file');
      stderr.writeln('');
      stderr.writeln('Usage: stardust openapi <spec-file> [options]');
      stderr.writeln('');
      stderr.writeln('Example:');
      stderr.writeln('  stardust openapi openapi.yaml -o docs/api');
      stderr.writeln('  stardust openapi swagger.json --group-by path');
      return 1;
    }

    final source = rest.first;
    final outputDir = args['output'] as String;
    final groupByStr = args['group-by'] as String;

    File? downloadedSpec;
    final String specPath;
    if (source.startsWith('http://') || source.startsWith('https://')) {
      stdout.writeln('🌐 Downloading spec from $source...');
      try {
        downloadedSpec = await _downloadSpec(source);
      } catch (e) {
        stderr.writeln('❌ Error: Failed to download spec: $e');
        return 1;
      }
      specPath = downloadedSpec.path;
    } else {
      specPath = source;
      if (!File(specPath).existsSync()) {
        stderr.writeln('❌ Error: OpenAPI spec not found: $specPath');
        return 1;
      }
    }

    stdout.writeln('🔄 Importing OpenAPI spec...');
    stdout.writeln('');

    final groupBy = switch (groupByStr) {
      'tag' => OpenApiGroupBy.tag,
      'path' => OpenApiGroupBy.path,
      'none' => OpenApiGroupBy.none,
      _ => OpenApiGroupBy.tag,
    };

    final logger = Logger(onLog: stdout.writeln, onError: stderr.writeln);
    final importer = OpenApiImporter(
        specPath: specPath, outputDir: outputDir, options: OpenApiOptions(groupBy: groupBy), logger: logger);

    try {
      final fileCount = await importer.import();

      if (fileCount == 0) {
        stderr.writeln('❌ No files generated');
        return 1;
      }

      stdout.writeln('');
      stdout.writeln('📁 Output: ${p.absolute(outputDir)}');
      stdout.writeln('');
      stdout.writeln('Next steps:');
      stdout.writeln('  1. Add the generated pages to your stardust.yaml sidebar');
      stdout.writeln('  2. Run `stardust build` to generate your site');
      stdout.writeln('');

      return 0;
    } catch (e) {
      stderr.writeln('❌ Import failed: $e');
      return 1;
    } finally {
      if (downloadedSpec case final spec? when spec.existsSync()) {
        await spec.delete();
      }
    }
  }

  Future<File> _downloadSpec(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      final ext = switch (p.extension(Uri.parse(url).path)) {
        '' => '.yaml',
        final ext => ext,
      };
      final file = File(p.join(Directory.systemTemp.path, 'stardust-openapi-spec$ext'));
      await response.pipe(file.openWrite());
      return file;
    } finally {
      client.close();
    }
  }
}
