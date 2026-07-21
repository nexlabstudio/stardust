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
      expect(fileSystem.operations, contains(MockFileSystem.op('deleteDirectory', 'out', recursive: true)));
    });

    test('deletes an existing empty directory', () async {
      fileSystem.addDirectory('out');

      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--skip-search']);

      expect(code, 0);
      expect(fileSystem.operations, contains(MockFileSystem.op('deleteDirectory', 'out', recursive: true)));
    });

    test('writes the build marker into the fresh output', () async {
      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--skip-search']);

      expect(code, 0);
      expect(fileSystem.hasFile(p.join('out', BuildCommand.buildMarker)), isTrue);
    });

    test('uses build.outDir when --output is not passed', () async {
      await File(configPath).writeAsString(
          'name: Test\ncontent:\n  dir: ${p.join(p.dirname(configPath), 'content')}\nbuild:\n  outDir: from-config\n');

      final code = await runner.run(['build', '-c', configPath, '--skip-search']);

      expect(code, 0);
      expect(fileSystem.hasFile(p.join('from-config', BuildCommand.buildMarker)), isTrue);
    });

    test('--output overrides build.outDir', () async {
      await File(configPath).writeAsString(
          'name: Test\ncontent:\n  dir: ${p.join(p.dirname(configPath), 'content')}\nbuild:\n  outDir: from-config\n');

      final code = await runner.run(['build', '-c', configPath, '-o', 'from-flag', '--skip-search']);

      expect(code, 0);
      expect(fileSystem.hasFile(p.join('from-flag', BuildCommand.buildMarker)), isTrue);
      expect(fileSystem.hasFile(p.join('from-config', BuildCommand.buildMarker)), isFalse);
    });

    test('--no-clean skips deletion entirely', () async {
      fileSystem.addDirectory('out');
      fileSystem.addFile('out/index.html', '<html></html>');

      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--no-clean', '--skip-search']);

      expect(code, 0);
      expect(deleted(), isFalse);
    });

    test('--verbose narrates config loading and cleaning', () async {
      fileSystem.addDirectory('out');
      fileSystem.addFile(p.join('out', BuildCommand.buildMarker), 'marker');

      final code = await runner.run(['build', '-c', configPath, '-o', 'out', '--skip-search', '--verbose']);

      expect(code, 0);
      expect(logs.join('\n'), contains('Loading config from'));
      expect(logs.join('\n'), contains('Cleaning output directory'));
    });

    test('honours search.enabled: false without needing --skip-search', () async {
      await File(configPath).writeAsString(
          'name: Test\ncontent:\n  dir: ${p.join(tempDir.path, 'content')}\nsearch:\n  enabled: false\n');

      final code = await runner.run(['build', '-c', configPath, '-o', 'out']);

      expect(code, 0);
      expect(logs.join('\n'), isNot(contains('Building search index')));
    });

    test('reports a failed build, with the stack trace under --verbose', () async {
      final badConfig = p.join(tempDir.path, 'bad.yaml');
      await File(badConfig).writeAsString('name: Test\ncontent:\n  dir: ${p.join(tempDir.path, 'missing')}\n');
      fileSystem.addFile(badConfig, 'seeded');

      final code = await runner.run(['build', '-c', badConfig, '-o', 'out', '--skip-search', '--verbose']);

      expect(code, 1);
      expect(errors.join('\n'), contains('Build failed'));
      expect(errors.join('\n'), contains('Content directory not found'));
    });
  });

  test('constructs and runs with default dependencies', () async {
    final command = BuildCommand();
    expect(command.name, 'build');
    expect(command.description, isNotEmpty);

    final defaults = CommandRunner<int>('stardust', 'test')..addCommand(command);

    expect(await defaults.run(['build', '-c', 'definitely-missing-config.yaml']), 1);
  });

  test('fails when the config file does not exist', () async {
    final code = await runner.run(['build', '-c', 'nope.yaml']);

    expect(code, 1);
    expect(errors.join('\n'), contains('Config file not found'));
  });

  group('--all-versions', () {
    late Directory tempDir;
    late String configPath;
    late String docsDir;
    late String v1Dir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stardust_versions_test');
      docsDir = p.join(tempDir.path, 'docs');
      v1Dir = p.join(tempDir.path, 'v1src');
      await Directory(docsDir).create(recursive: true);
      await Directory(v1Dir).create(recursive: true);
      await File(p.join(docsDir, 'index.md')).writeAsString('# v2 home');
      await File(p.join(v1Dir, 'index.md')).writeAsString('# v1 home');
      configPath = p.join(tempDir.path, 'stardust.yaml');

      fileSystem.addFile(p.join(docsDir, 'index.md'), '# v2 home');
      fileSystem.addFile(p.join(v1Dir, 'index.md'), '# v1 home');
    });

    tearDown(() async => tempDir.delete(recursive: true));

    Future<void> writeConfig(String versions) async {
      await File(configPath).writeAsString('name: Test\ncontent:\n  dir: $docsDir\n$versions');
      fileSystem.addFile(configPath, 'seeded');
    }

    Future<int?> build() => runner.run(['build', '-c', configPath, '-o', 'out', '--all-versions', '--skip-search']);

    test('narrows each version sidebar to the pages that version has', () async {
      await File(p.join(docsDir, 'newfeature.md')).writeAsString('# New');
      fileSystem.addFile(p.join(docsDir, 'newfeature.md'), '# New');
      await writeConfig('sidebar:\n'
          '  - group: Guides\n'
          '    pages: [index, newfeature]\n'
          'versions:\n'
          '  enabled: true\n'
          '  current: "2.0"\n'
          '  list:\n'
          '    - version: "2.0"\n'
          '      path: /\n'
          '    - version: "1.0"\n'
          '      path: /v1/\n'
          '      source: $v1Dir\n');

      expect(await build(), 0);
      expect(fileSystem.fileAt(p.join('out', 'index.html')), contains('href="/newfeature"'));
      expect(fileSystem.fileAt(p.join('out', 'v1', 'index.html')), isNot(contains('/v1/newfeature')),
          reason: 'v1 predates the page, so it must not be linked');
    });

    test('fails when no versions are configured', () async {
      await writeConfig('');

      expect(await build(), 1);
      expect(errors.join('\n'), contains('needs a versions.list'));
    });

    test('fails when versions.current is missing', () async {
      await writeConfig('versions:\n  enabled: true\n  list:\n    - version: "1.0"\n      path: /v1/\n');

      expect(await build(), 1);
      expect(errors.join('\n'), contains('needs versions.current'));
    });

    test('builds each version into its prefix with a single root robots.txt', () async {
      await writeConfig('versions:\n'
          '  enabled: true\n'
          '  current: "2.0"\n'
          '  list:\n'
          '    - version: "2.0"\n'
          '      path: /\n'
          '    - version: "1.0"\n'
          '      path: /v1/\n'
          '      source: $v1Dir\n');

      expect(await build(), 0);
      expect(fileSystem.hasFile(p.join('out', 'index.html')), isTrue);
      expect(fileSystem.hasFile(p.join('out', 'v1', 'index.html')), isTrue);
      expect(fileSystem.hasFile(p.join('out', 'robots.txt')), isTrue);
      expect(fileSystem.hasFile(p.join('out', 'v1', 'robots.txt')), isFalse,
          reason: 'robots.txt is site-wide, never per version');
      expect(fileSystem.fileAt(p.join('out', 'v1', 'index.html')), contains('noindex'));
      expect(logs.join('\n'), contains('(noindex)'));
    });

    test('redirects the site root when the current version lives under a prefix', () async {
      await writeConfig('versions:\n'
          '  enabled: true\n'
          '  current: "2.0"\n'
          '  list:\n'
          '    - version: "2.0"\n'
          '      path: /v2/\n'
          '    - version: "1.0"\n'
          '      path: /v1/\n'
          '      source: $v1Dir\n');

      expect(await build(), 0);
      expect(fileSystem.hasFile(p.join('out', 'v2', 'index.html')), isTrue);
      expect(fileSystem.fileAt(p.join('out', 'index.html')), contains('http-equiv="refresh"'));
      expect(fileSystem.fileAt(p.join('out', 'index.html')), contains('/v2/'));
    });
  });
}
