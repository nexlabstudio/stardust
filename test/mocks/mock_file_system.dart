import 'dart:io';
import 'dart:typed_data';

import 'package:stardust/src/core/file_system.dart';

class MockFileSystem implements FileSystem {
  /// All paths are normalized to forward slashes, so tests behave identically
  /// whether they seed with literals or p.join (backslashes on Windows).
  static String _n(String path) => path.replaceAll('\\', '/');

  final Map<String, String> files = {};
  final Map<String, Uint8List> binaryFiles = {};
  final Set<String> directories = {};
  final Map<String, DateTime> modifiedTimes = {};
  final List<String> operations = [];

  void addFile(String path, String content, {DateTime? modified}) {
    path = _n(path);
    files[path] = content;
    modifiedTimes[path] = modified ?? DateTime.now();
    _addParentDirectory(path);
  }

  void addBinaryFile(String path, Uint8List bytes, {DateTime? modified}) {
    path = _n(path);
    binaryFiles[path] = bytes;
    modifiedTimes[path] = modified ?? DateTime.now();
    _addParentDirectory(path);
  }

  void _addParentDirectory(String path) {
    if (path.lastIndexOf('/') case final slash when slash > 0) {
      directories.add(path.substring(0, slash));
    }
  }

  void addDirectory(String path) {
    directories.add(_n(path));
  }

  /// Normalized lookups so assertions can use p.join freely.
  String? fileAt(String path) => files[_n(path)];
  bool hasFile(String path) => files.containsKey(_n(path)) || binaryFiles.containsKey(_n(path));
  bool hasDirectory(String path) => directories.contains(_n(path));

  /// The operation-log entry for [action] on [path], normalized like the log itself.
  static String op(String action, String path, {bool? recursive}) =>
      '$action:${_n(path)}${switch (recursive) { final r? => ':recursive=$r', null => '' }}';

  @override
  Future<bool> directoryExists(String path) async {
    path = _n(path);
    operations.add('directoryExists:$path');
    return directories.contains(path) ||
        directories.any((d) => d.startsWith('$path/')) ||
        files.keys.any((f) => f.startsWith('$path/'));
  }

  @override
  Future<bool> fileExists(String path) async {
    path = _n(path);
    operations.add('fileExists:$path');
    return files.containsKey(path) || binaryFiles.containsKey(path);
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    path = _n(path);
    operations.add('createDirectory:$path:recursive=$recursive');
    directories.add(path);
  }

  @override
  Future<void> deleteDirectory(String path, {bool recursive = false}) async {
    path = _n(path);
    operations.add('deleteDirectory:$path:recursive=$recursive');
    directories.remove(path);
    if (recursive) {
      files.removeWhere((key, _) => key.startsWith('$path/'));
      directories.removeWhere((d) => d.startsWith('$path/'));
    }
  }

  @override
  Future<String> readFile(String path) async {
    path = _n(path);
    operations.add('readFile:$path');
    if (!files.containsKey(path)) {
      throw FileSystemException('File not found', path);
    }
    return files[path]!;
  }

  @override
  Future<Uint8List> readFileBytes(String path) async {
    path = _n(path);
    operations.add('readFileBytes:$path');
    if (binaryFiles.containsKey(path)) {
      return binaryFiles[path]!;
    }
    if (files.containsKey(path)) {
      return Uint8List.fromList(files[path]!.codeUnits);
    }
    throw FileSystemException('File not found', path);
  }

  @override
  Future<void> writeFile(String path, String content) async {
    path = _n(path);
    operations.add('writeFile:$path');
    files[path] = content;
    modifiedTimes[path] = DateTime.now();
  }

  @override
  Future<void> writeFileBytes(String path, Uint8List bytes) async {
    path = _n(path);
    operations.add('writeFileBytes:$path');
    binaryFiles[path] = bytes;
    modifiedTimes[path] = DateTime.now();
  }

  @override
  Future<void> copyFile(String source, String destination) async {
    source = _n(source);
    destination = _n(destination);
    operations.add('copyFile:$source->$destination');
    if (!files.containsKey(source)) {
      throw FileSystemException('Source file not found', source);
    }
    files[destination] = files[source]!;
  }

  @override
  Future<DateTime> lastModified(String path) async {
    path = _n(path);
    operations.add('lastModified:$path');
    return modifiedTimes[path] ?? DateTime.now();
  }

  @override
  Stream<FileSystemEntity> listDirectory(String path, {bool recursive = false}) async* {
    path = _n(path);
    operations.add('listDirectory:$path:recursive=$recursive');
    for (final filePath in files.keys) {
      if (recursive) {
        if (filePath.startsWith('$path/')) {
          yield _MockFile(filePath);
        }
      } else {
        if (filePath.startsWith('$path/') && !filePath.substring(path.length + 1).contains('/')) {
          yield _MockFile(filePath);
        }
      }
    }
  }

  void reset() {
    files.clear();
    binaryFiles.clear();
    directories.clear();
    modifiedTimes.clear();
    operations.clear();
  }
}

class _MockFile implements File {
  @override
  final String path;

  _MockFile(this.path);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
