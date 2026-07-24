import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/file_system.dart';

/// Merges a locale's translations over the default-locale content so every
/// locale builds the full page set, and reports which pages had no translation.
class LocaleContentMaterializer {
  final FileSystem fileSystem;
  final _scratch = <Directory>[];

  LocaleContentMaterializer({FileSystem? fileSystem}) : fileSystem = fileSystem ?? const LocalFileSystem();

  /// Copies [defaultDir] into a fresh directory, overlaying any file found under
  /// [translatedDir], and returns that directory plus the page paths (e.g.
  /// `/guide`) that fell back to the default because no translation existed.
  Future<({String dir, Set<String> untranslated})> materialize({
    required String defaultDir,
    required String translatedDir,
    Set<String> excludeSubdirs = const {},
  }) async {
    final scratch = await Directory.systemTemp.createTemp('stardust-locale-');
    _scratch.add(scratch);

    final defaults = await _relativeFiles(defaultDir, excludeSubdirs: excludeSubdirs);
    final translated = await _relativeFiles(translatedDir);

    final untranslated = <String>{};
    for (final relative in {...defaults, ...translated}) {
      final translatedHere = translated.contains(relative);
      final from = p.join(translatedHere ? translatedDir : defaultDir, relative);
      final to = p.join(scratch.path, relative);
      await fileSystem.createDirectory(p.dirname(to), recursive: true);
      await fileSystem.copyFile(from, to);

      if (!translatedHere && _isPage(relative)) untranslated.add(_pagePath(relative));
    }

    return (dir: scratch.path, untranslated: untranslated);
  }

  Future<void> cleanup() async {
    for (final dir in _scratch) {
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
    _scratch.clear();
  }

  Future<Set<String>> _relativeFiles(String dir, {Set<String> excludeSubdirs = const {}}) async {
    if (!await fileSystem.directoryExists(dir)) return const {};
    final relatives = <String>{};
    await for (final entity in fileSystem.listDirectory(dir, recursive: true)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: dir).replaceAll('\\', '/');
      if (excludeSubdirs.any((s) => relative == s || relative.startsWith('$s/'))) continue;
      relatives.add(relative);
    }
    return relatives;
  }

  bool _isPage(String relative) => relative.endsWith('.md') || relative.endsWith('.mdx');

  String _pagePath(String relative) {
    final slug = p.withoutExtension(relative);
    return slug == 'index' ? '/' : '/$slug';
  }
}
