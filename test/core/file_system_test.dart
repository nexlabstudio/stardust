import 'dart:io';
import 'dart:typed_data';

import 'package:stardust/src/core/file_system.dart';
import 'package:test/test.dart';

void main() {
  group('LocalFileSystem', () {
    late LocalFileSystem fileSystem;
    late Directory tempDir;

    setUp(() async {
      fileSystem = const LocalFileSystem();
      tempDir = await Directory.systemTemp.createTemp('stardust_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('directoryExists', () {
      test('returns true for existing directory', () async {
        final exists = await fileSystem.directoryExists(tempDir.path);
        expect(exists, isTrue);
      });

      test('returns false for non-existing directory', () async {
        final exists = await fileSystem.directoryExists('${tempDir.path}/nonexistent');
        expect(exists, isFalse);
      });
    });

    group('fileExists', () {
      test('returns true for existing file', () async {
        final file = File('${tempDir.path}/test.txt');
        await file.writeAsString('test');

        final exists = await fileSystem.fileExists(file.path);
        expect(exists, isTrue);
      });

      test('returns false for non-existing file', () async {
        final exists = await fileSystem.fileExists('${tempDir.path}/nonexistent.txt');
        expect(exists, isFalse);
      });
    });

    group('createDirectory', () {
      test('creates directory', () async {
        final dirPath = '${tempDir.path}/new_dir';
        await fileSystem.createDirectory(dirPath);

        expect(await fileSystem.directoryExists(dirPath), isTrue);
      });

      test('creates nested directories with recursive flag', () async {
        final dirPath = '${tempDir.path}/nested/deep/dir';
        await fileSystem.createDirectory(dirPath, recursive: true);

        expect(await fileSystem.directoryExists(dirPath), isTrue);
      });
    });

    group('deleteDirectory', () {
      test('deletes empty directory', () async {
        final dirPath = '${tempDir.path}/to_delete';
        await Directory(dirPath).create();

        await fileSystem.deleteDirectory(dirPath);
        expect(await fileSystem.directoryExists(dirPath), isFalse);
      });

      test('deletes directory with contents when recursive', () async {
        final dirPath = '${tempDir.path}/to_delete';
        await Directory(dirPath).create();
        await File('$dirPath/file.txt').writeAsString('content');

        await fileSystem.deleteDirectory(dirPath, recursive: true);
        expect(await fileSystem.directoryExists(dirPath), isFalse);
      });

      test('handles non-existent directory gracefully', () async {
        final dirPath = '${tempDir.path}/nonexistent';
        // Should not throw
        await fileSystem.deleteDirectory(dirPath);
      });
    });

    group('readFile', () {
      test('reads file content', () async {
        final file = File('${tempDir.path}/test.txt');
        await file.writeAsString('Hello, World!');

        final content = await fileSystem.readFile(file.path);
        expect(content, 'Hello, World!');
      });
    });

    group('readFileBytes', () {
      test('reads file as bytes', () async {
        final file = File('${tempDir.path}/binary.bin');
        final bytes = Uint8List.fromList([0, 1, 2, 3, 255]);
        await file.writeAsBytes(bytes);

        final readBytes = await fileSystem.readFileBytes(file.path);
        expect(readBytes, equals(bytes));
      });

      test('reads text file as bytes', () async {
        final file = File('${tempDir.path}/text.txt');
        await file.writeAsString('ABC');

        final readBytes = await fileSystem.readFileBytes(file.path);
        expect(readBytes, equals(Uint8List.fromList([65, 66, 67]))); // ASCII codes for ABC
      });
    });

    group('writeFile', () {
      test('writes content to file', () async {
        final filePath = '${tempDir.path}/output.txt';
        await fileSystem.writeFile(filePath, 'Test content');

        final content = await File(filePath).readAsString();
        expect(content, 'Test content');
      });

      test('creates parent directories if needed', () async {
        final filePath = '${tempDir.path}/nested/dir/output.txt';
        await fileSystem.writeFile(filePath, 'Nested content');

        final content = await File(filePath).readAsString();
        expect(content, 'Nested content');
      });

      test('overwrites existing file', () async {
        final filePath = '${tempDir.path}/output.txt';
        await fileSystem.writeFile(filePath, 'First');
        await fileSystem.writeFile(filePath, 'Second');

        final content = await File(filePath).readAsString();
        expect(content, 'Second');
      });
    });

    group('writeFileBytes', () {
      test('writes bytes to file', () async {
        final filePath = '${tempDir.path}/binary.bin';
        final bytes = Uint8List.fromList([0, 1, 2, 3, 255]);
        await fileSystem.writeFileBytes(filePath, bytes);

        final readBytes = await File(filePath).readAsBytes();
        expect(readBytes, equals(bytes));
      });

      test('creates parent directories if needed', () async {
        final filePath = '${tempDir.path}/nested/dir/binary.bin';
        final bytes = Uint8List.fromList([10, 20, 30]);
        await fileSystem.writeFileBytes(filePath, bytes);

        final readBytes = await File(filePath).readAsBytes();
        expect(readBytes, equals(bytes));
      });
    });

    group('copyFile', () {
      test('copies file to destination', () async {
        final sourcePath = '${tempDir.path}/source.txt';
        final destPath = '${tempDir.path}/dest.txt';
        await File(sourcePath).writeAsString('Copy me');

        await fileSystem.copyFile(sourcePath, destPath);

        final content = await File(destPath).readAsString();
        expect(content, 'Copy me');
      });

      test('creates parent directories for destination', () async {
        final sourcePath = '${tempDir.path}/source.txt';
        final destPath = '${tempDir.path}/nested/dest.txt';
        await File(sourcePath).writeAsString('Copy me');

        await fileSystem.copyFile(sourcePath, destPath);

        final content = await File(destPath).readAsString();
        expect(content, 'Copy me');
      });
    });

    group('lastModified', () {
      test('returns last modified time', () async {
        final file = File('${tempDir.path}/test.txt');
        await file.writeAsString('test');

        final modified = await fileSystem.lastModified(file.path);
        final now = DateTime.now();

        // Should be within a few seconds of now
        expect(modified.difference(now).inSeconds.abs(), lessThan(5));
      });
    });

    group('listDirectory', () {
      test('lists files in directory', () async {
        await File('${tempDir.path}/file1.txt').writeAsString('1');
        await File('${tempDir.path}/file2.txt').writeAsString('2');

        final entities = await fileSystem.listDirectory(tempDir.path).toList();
        final paths = entities.map((e) => e.path).toList();

        expect(paths.length, 2);
        expect(paths.any((p) => p.endsWith('file1.txt')), isTrue);
        expect(paths.any((p) => p.endsWith('file2.txt')), isTrue);
      });

      test('lists recursively when flag is set', () async {
        final subDir = Directory('${tempDir.path}/subdir');
        await subDir.create();
        await File('${tempDir.path}/root.txt').writeAsString('root');
        await File('${subDir.path}/nested.txt').writeAsString('nested');

        final entities = await fileSystem.listDirectory(tempDir.path, recursive: true).toList();
        final paths = entities.map((e) => e.path).toList();

        expect(paths.any((p) => p.endsWith('root.txt')), isTrue);
        expect(paths.any((p) => p.endsWith('nested.txt')), isTrue);
      });
    });
  });
}
