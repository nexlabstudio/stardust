import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:stardust/src/cli/commands/build_command.dart';
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
      ..addCommand(BuildCommand(
        fileSystem: fileSystem,
        loggerFactory: () => Logger(onLog: logs.add, onError: errors.add),
      ));
  });

  bool deleted() => fileSystem.operations.any((op) => op.startsWith('deleteDirectory:'));

  group('clean guard refuses when', () {
    setUp(() {
      fileSystem.addFile('stardust.yaml', 'name: Test');
    });

    test('output is the current directory', () async {
      fileSystem.addDirectory('.');

      final code = await runner.run(['build', '-o', '.']);

      expect(code, 1);
      expect(errors.join('\n'), contains('Refusing to clean'));
      expect(deleted(), isFalse);
    });

    test('output is an ancestor of the current directory', () async {
      fileSystem.addDirectory('..');

      final code = await runner.run(['build', '-o', '..']);

      expect(code, 1);
      expect(errors.join('\n'), contains('Refusing to clean'));
      expect(deleted(), isFalse);
    });

    test('output is non-empty and carries no build marker', () async {
      fileSystem.addDirectory('out');
      fileSystem.addFile('out/index.html', '<html></html>');

      final code = await runner.run(['build', '-o', 'out']);

      expect(code, 1);
      expect(errors.join('\n'), contains(BuildCommand.buildMarker));
      expect(deleted(), isFalse);
    });
  });

  group('clean proceeds when safe', () {
    late Directory tempDir;
    late String configPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stardust_build_test');
      final contentDir = Directory(p.join(tempDir.path, 'content'));
      await contentDir.create();
      configPath = p.join(tempDir.path, 'stardust.yaml');
      await File(configPath).writeAsString('name: Test\ncontent:\n  dir: ${contentDir.path}\n');
      fileSystem.addFile(configPath, 'name: Test');
      fileSystem.addDirectory(contentDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('deletes a directory carrying the build marker', () async {
      fileSystem.addDirectory('out');
      fileSystem.addFile('out/index.html', '<html></html>');
      fileSystem.addFile(p.join('out', BuildCommand.buildMarker), 'marker');

      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--skip-search']);

      expect(code, 0);
      expect(fileSystem.operations, contains('deleteDirectory:out:recursive=true'));
    });

    test('deletes an existing empty directory', () async {
      fileSystem.addDirectory('out');

      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--skip-search']);

      expect(code, 0);
      expect(fileSystem.operations, contains('deleteDirectory:out:recursive=true'));
    });

    test('writes the build marker into the fresh output', () async {
      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--skip-search']);

      expect(code, 0);
      expect(fileSystem.files.keys, contains(p.join('out', BuildCommand.buildMarker)));
    });

    test('--no-clean skips deletion entirely', () async {
      fileSystem.addDirectory('out');
      fileSystem.addFile('out/index.html', '<html></html>');

      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--no-clean', '--skip-search']);

      expect(code, 0);
      expect(deleted(), isFalse);
    });
  });
}
