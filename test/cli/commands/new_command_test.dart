import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:stardust/src/cli/commands/clean_command.dart';
import 'package:stardust/src/cli/commands/new_command.dart';
import 'package:stardust/src/cli/output_guard.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

import '../../mocks/mock_file_system.dart';

void main() {
  late MockFileSystem fileSystem;
  late List<String> logs;
  late List<String> errors;
  late CommandRunner<int> runner;

  setUp(() {
    fileSystem = MockFileSystem();
    logs = [];
    errors = [];
    runner = CommandRunner<int>('stardust', 'test')
      ..addCommand(NewCommand(
        fileSystem: fileSystem,
        loggerFactory: () => Logger(onLog: logs.add, onError: errors.add),
      ))
      ..addCommand(CleanCommand(
        fileSystem: fileSystem,
        loggerFactory: () => Logger(onLog: logs.add, onError: errors.add),
      ));
  });

  group('new', () {
    test('creates a page with title-cased frontmatter', () async {
      final code = await runner.run(['new', 'getting-started']);

      expect(code, 0);
      final path = p.join('docs', 'getting-started.md');
      expect(fileSystem.files[path], contains('title: Getting Started'));
      expect(fileSystem.files[path], contains('# Getting Started'));
      expect(logs.join('\n'), contains('- slug: getting-started'));
    });

    test('supports nested slugs and custom titles', () async {
      final code = await runner.run(['new', 'guides/install', '--title', 'Install Guide']);

      expect(code, 0);
      expect(fileSystem.files[p.join('docs', 'guides/install.md')], contains('title: Install Guide'));
    });

    test('refuses to overwrite an existing page', () async {
      fileSystem.addFile(p.join('docs', 'existing.md'), 'original');

      final code = await runner.run(['new', 'existing']);

      expect(code, 1);
      expect(errors.join('\n'), contains('already exists'));
      expect(fileSystem.files[p.join('docs', 'existing.md')], equals('original'));
    });

    test('requires a slug argument', () async {
      final code = await runner.run(['new']);

      expect(code, 64);
      expect(errors.join('\n'), contains('Usage'));
    });
  });

  group('clean', () {
    test('removes marked output, dev output, and caches', () async {
      fileSystem.addFile(p.join('dist', outputGuardMarker), 'marker');
      fileSystem.addFile(p.join('dist', 'index.html'), 'x');
      fileSystem.addDirectory('.stardust');
      fileSystem.addDirectory(p.join('.dart_tool', 'stardust'));

      final code = await runner.run(['clean']);

      expect(code, 0);
      expect(fileSystem.operations, contains('deleteDirectory:dist:recursive=true'));
      expect(fileSystem.operations, contains('deleteDirectory:.stardust:recursive=true'));
      expect(fileSystem.operations, contains('deleteDirectory:${p.join('.dart_tool', 'stardust')}:recursive=true'));
    });

    test('skips an unmarked non-empty output directory', () async {
      fileSystem.addDirectory('dist');
      fileSystem.addFile('dist/index.html', 'x');

      final code = await runner.run(['clean']);

      expect(code, 0);
      expect(errors.join('\n'), contains('Skipping "dist"'));
      expect(fileSystem.operations.where((op) => op.startsWith('deleteDirectory:dist')), isEmpty);
    });

    test('reports nothing to clean when no outputs exist', () async {
      final code = await runner.run(['clean']);

      expect(code, 0);
      expect(logs.join('\n'), contains('Nothing to clean'));
    });
  });
}
