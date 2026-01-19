import 'dart:io';

class FileUtils {
  const FileUtils._();

  static Future<bool> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (dir.existsSync()) return false;
    await dir.create(recursive: true);
    return true;
  }

  static bool ensureDirectorySync(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) return false;
    dir.createSync(recursive: true);
    return true;
  }

  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  static Future<String?> readFileIfExists(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  static String? readFileIfExistsSync(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  static bool fileExists(String path) => File(path).existsSync();

  static bool directoryExists(String path) => Directory(path).existsSync();

  static Future<void> copyFile(String source, String destination) async {
    final destFile = File(destination);
    await destFile.parent.create(recursive: true);
    await File(source).copy(destination);
  }

  static Future<void> deleteDirectory(String path) async {
    final dir = Directory(path);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}
