import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/file_system.dart';

/// Builds a locale's content by resolving every default-locale page to its
/// translation — a locale-suffixed sibling (`guide.es.md`), then a file under
/// the locale [subdir] (`es/guide.md`), then the default page as a fallback —
/// and reports which pages fell back so they can show a "not translated" notice.
class LocaleContentMaterializer {
  final FileSystem fileSystem;
  final _scratch = <Directory>[];

  LocaleContentMaterializer({FileSystem? fileSystem}) : fileSystem = fileSystem ?? const LocalFileSystem();

  /// Materializes [localeCode]'s content from [defaultDir] into a fresh
  /// directory. [subdir] holds subdirectory-style translations; [excludeSubdirs]
  /// and [localeCodes] identify the translation files (locale subdirs and
  /// `*.<code>.md` siblings) so they are not mistaken for default pages.
  Future<({String dir, Set<String> untranslated})> materialize({
    required String defaultDir,
    required String localeCode,
    required String subdir,
    Set<String> excludeSubdirs = const {},
    Set<String> localeCodes = const {},
  }) async {
    final scratch = await Directory.systemTemp.createTemp('stardust-locale-');
    _scratch.add(scratch);

    final untranslated = <String>{};
    for (final relative in await _baseFiles(defaultDir, excludeSubdirs, localeCodes)) {
      final to = p.join(scratch.path, relative);
      await fileSystem.createDirectory(p.dirname(to), recursive: true);

      final translation =
          _isPage(relative) ? await _resolveTranslation(defaultDir, subdir, relative, localeCode) : null;
      await fileSystem.copyFile(translation ?? p.join(defaultDir, relative), to);
      if (_isPage(relative) && translation == null) untranslated.add(_pagePath(relative));
    }

    return (dir: scratch.path, untranslated: untranslated);
  }

  Future<void> cleanup() async {
    for (final dir in _scratch) {
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
    _scratch.clear();
  }

  Future<String?> _resolveTranslation(String defaultDir, String subdir, String relative, String code) async {
    final suffixed = p.join(defaultDir, _withLocaleSuffix(relative, code));
    if (await fileSystem.fileExists(suffixed)) return suffixed;
    final inSubdir = p.join(subdir, relative);
    if (await fileSystem.fileExists(inSubdir)) return inSubdir;
    return null;
  }

  Future<Set<String>> _baseFiles(String dir, Set<String> excludeSubdirs, Set<String> localeCodes) async {
    if (!await fileSystem.directoryExists(dir)) return const {};
    final relatives = <String>{};
    await for (final entity in fileSystem.listDirectory(dir, recursive: true)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: dir).replaceAll('\\', '/');
      if (excludeSubdirs.any((s) => relative == s || relative.startsWith('$s/'))) continue;
      if (_isLocaleSuffixFile(relative, localeCodes)) continue;
      relatives.add(relative);
    }
    return relatives;
  }

  String _withLocaleSuffix(String relative, String code) {
    final ext = p.extension(relative);
    return '${relative.substring(0, relative.length - ext.length)}.$code$ext';
  }

  bool _isLocaleSuffixFile(String relative, Set<String> localeCodes) {
    if (!_isPage(relative)) return false;
    final beforeExt = relative.substring(0, relative.length - p.extension(relative).length);
    final suffix = p.extension(beforeExt);
    return suffix.isNotEmpty && localeCodes.contains(suffix.substring(1));
  }

  bool _isPage(String relative) => relative.endsWith('.md') || relative.endsWith('.mdx');

  String _pagePath(String relative) {
    final slug = p.withoutExtension(relative);
    return slug == 'index' ? '/' : '/$slug';
  }
}
