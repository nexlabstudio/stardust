import 'dart:io';
import 'dart:typed_data';

import 'package:stardust/src/core/file_system.dart';

class MockFileSystem implements FileSystem {
  /// All paths are normalized to forward slashes, so tests behave identically
  /// whether they seed with literals or p.join (backslashes on Windows).
  static String _n(String path) => path.replaceAll('\\', '/');

  final Map<String, String> _files = {};
  final Map<String, Uint8List> _binaryFiles = {};
  final Set<String> _directories = {};
  final Map<String, DateTime> _modifiedTimes = {};

  /// Log entries are pre-normalized; safe to assert on directly
  /// (build entries with [op] when a path is involved).
  final List<String> operations = [];

  /// All file paths currently in the mock, normalized to forward slashes.
  Iterable<String> get filePaths => _files.keys.followedBy(_binaryFiles.keys);

  void addFile(String path, String content, {DateTime? modified}) {
    path = _n(path);
    _files[path] = content;
    _modifiedTimes[path] = modified ?? DateTime.now();
    _addParentDirectory(path);
  }

  void addBinaryFile(String path, Uint8List bytes, {DateTime? modified}) {
    path = _n(path);
    _binaryFiles[path] = bytes;
    _modifiedTimes[path] = modified ?? DateTime.now();
    _addParentDirectory(path);
  }

  void _addParentDirectory(String path) {
    if (path.lastIndexOf('/') case final slash when slash > 0) {
      _directories.add(path.substring(0, slash));
    }
  }

  void addDirectory(String path) {
    _directories.add(_n(path));
  }

  /// Normalized lookups so assertions can use p.join freely.
  String? fileAt(String path) => _files[_n(path)];
  Uint8List? binaryFileAt(String path) => _binaryFiles[_n(path)];
  bool hasFile(String path) => _files.containsKey(_n(path)) || _binaryFiles.containsKey(_n(path));
  bool hasDirectory(String path) => _directories.contains(_n(path));

  /// The operation-log entry for [action] on [path], normalized like the log itself.
  static String op(String action, String path, {bool? recursive}) =>
      '$action:${_n(path)}${switch (recursive) { final r? => ':recursive=$r', null => '' }}';

  @override
  Future<bool> directoryExists(String path) async {
    path = _n(path);
    operations.add('directoryExists:$path');
    return _directories.contains(path) ||
        _directories.any((d) => d.startsWith('$path/')) ||
        _files.keys.any((f) => f.startsWith('$path/'));
  }

  @override
  Future<bool> fileExists(String path) async {
    path = _n(path);
    operations.add('fileExists:$path');
    return _files.containsKey(path) || _binaryFiles.containsKey(path);
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    path = _n(path);
    operations.add('createDirectory:$path:recursive=$recursive');
    _directories.add(path);
  }

  @override
  Future<void> deleteDirectory(String path, {bool recursive = false}) async {
    path = _n(path);
    operations.add('deleteDirectory:$path:recursive=$recursive');
    _directories.remove(path);
    if (recursive) {
      _files.removeWhere((key, _) => key.startsWith('$path/'));
      _directories.removeWhere((d) => d.startsWith('$path/'));
    }
  }

  @override
  Future<String> readFile(String path) async {
    path = _n(path);
    operations.add('readFile:$path');
    if (!_files.containsKey(path)) {
      throw FileSystemException('File not found', path);
    }
    return _files[path]!;
  }

  @override
  Future<Uint8List> readFileBytes(String path) async {
    path = _n(path);
    operations.add('readFileBytes:$path');
    if (_binaryFiles.containsKey(path)) {
      return _binaryFiles[path]!;
    }
    if (_files.containsKey(path)) {
      return Uint8List.fromList(_files[path]!.codeUnits);
    }
    throw FileSystemException('File not found', path);
  }

  @override
  Future<void> writeFile(String path, String content) async {
    path = _n(path);
    operations.add('writeFile:$path');
    _files[path] = content;
    _modifiedTimes[path] = DateTime.now();
  }

  @override
  Future<void> writeFileBytes(String path, Uint8List bytes) async {
    path = _n(path);
    operations.add('writeFileBytes:$path');
    _binaryFiles[path] = bytes;
    _modifiedTimes[path] = DateTime.now();
  }

  @override
  Future<void> copyFile(String source, String destination) async {
    source = _n(source);
    destination = _n(destination);
    operations.add('copyFile:$source->$destination');
    if (!_files.containsKey(source)) {
      throw FileSystemException('Source file not found', source);
    }
    _files[destination] = _files[source]!;
  }

  @override
  Future<DateTime> lastModified(String path) async {
    path = _n(path);
    operations.add('lastModified:$path');
    return _modifiedTimes[path] ?? DateTime.now();
  }

  @override
  Stream<FileSystemEntity> listDirectory(String path, {bool recursive = false}) async* {
    path = _n(path);
    operations.add('listDirectory:$path:recursive=$recursive');
    for (final filePath in _files.keys) {
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
    _files.clear();
    _binaryFiles.clear();
    _directories.clear();
    _modifiedTimes.clear();
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
