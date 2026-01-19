import 'dart:io';

abstract class FileSystem {
  Future<bool> directoryExists(String path);
  Future<bool> fileExists(String path);
  Future<void> createDirectory(String path, {bool recursive = false});
  Future<void> deleteDirectory(String path, {bool recursive = false});
  Future<String> readFile(String path);
  Future<void> writeFile(String path, String content);
  Future<void> copyFile(String source, String destination);
  Future<DateTime> lastModified(String path);
  Stream<FileSystemEntity> listDirectory(String path, {bool recursive = false});
}

class LocalFileSystem implements FileSystem {
  const LocalFileSystem();

  @override
  Future<bool> directoryExists(String path) async => Directory(path).existsSync();

  @override
  Future<bool> fileExists(String path) async => File(path).existsSync();

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    await Directory(path).create(recursive: recursive);
  }

  @override
  Future<void> deleteDirectory(String path, {bool recursive = false}) async {
    final dir = Directory(path);
    if (dir.existsSync()) {
      await dir.delete(recursive: recursive);
    }
  }

  @override
  Future<String> readFile(String path) => File(path).readAsString();

  @override
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  Future<void> copyFile(String source, String destination) async {
    final destFile = File(destination);
    await destFile.parent.create(recursive: true);
    await File(source).copy(destination);
  }

  @override
  Future<DateTime> lastModified(String path) async => File(path).lastModifiedSync();

  @override
  Stream<FileSystemEntity> listDirectory(String path, {bool recursive = false}) =>
      Directory(path).list(recursive: recursive);
}
