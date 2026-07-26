import 'dart:convert';

import 'package:path/path.dart' as p;

import '../core/file_system.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';

/// One documentation page discovered from a built site's `llms.json` manifest.
class DocPage {
  final String path;
  final String title;
  final String? description;
  final String? url;

  /// Site-root-relative path to the verbatim markdown, e.g. `/introduction.md`.
  final String mdFile;

  const DocPage({
    required this.path,
    required this.title,
    this.description,
    this.url,
    required this.mdFile,
  });
}

/// A search hit: the matched page plus a short snippet of surrounding text.
class DocHit {
  final DocPage page;
  final String snippet;

  const DocHit(this.page, this.snippet);
}

/// Reads a **built** Stardust site (its `llms.json` manifest + per-page `.md`
/// files) and answers docs queries — the read-only source `stardust mcp` serves.
/// It never re-parses markdown or needs `stardust.yaml`: everything comes from
/// the build output, so it serves any built site, air-gapped.
class DocsSource {
  final String dir;
  final FileSystem fileSystem;
  final Logger logger;
  final String siteName;
  final String? siteDescription;
  final String? siteUrl;
  final List<DocPage> pages;

  final Map<String, DocPage> _byPath;
  final Map<String, String?> _bodies = {};

  DocsSource._({
    required this.dir,
    required this.fileSystem,
    required this.logger,
    required this.siteName,
    this.siteDescription,
    this.siteUrl,
    required this.pages,
  }) : _byPath = {for (final page in pages) page.path: page};

  /// Loads the manifest at `<dir>/llms.json`. Throws [ContentException] with an
  /// actionable message when the directory hasn't been built.
  static Future<DocsSource> load(String dir, {FileSystem? fileSystem, Logger logger = const Logger()}) async {
    final fs = fileSystem ?? const LocalFileSystem();
    final manifestPath = p.join(dir, 'llms.json');
    if (!await fs.fileExists(manifestPath)) {
      throw ContentException(
        'No llms.json in "$dir" — run `stardust build` (with build.llms enabled) first, or pass the built site directory.',
      );
    }

    final decoded = switch (jsonDecode(await fs.readFile(manifestPath))) {
      final Map decoded => decoded,
      _ => throw ContentException('Malformed llms.json in "$dir".'),
    };

    final pages = <DocPage>[];
    if (decoded['pages'] case final List rawPages) {
      for (final raw in rawPages) {
        if (raw case {'path': final String path, 'title': final String title, 'md': final String md}) {
          pages.add(DocPage(
            path: path,
            title: title,
            description: _asString(raw['description']),
            url: _asString(raw['url']),
            mdFile: md,
          ));
        }
      }
    }

    return DocsSource._(
      dir: dir,
      fileSystem: fs,
      logger: logger,
      siteName: _asString(decoded['name']) ?? 'Documentation',
      siteDescription: _asString(decoded['description']),
      siteUrl: _asString(decoded['url']),
      pages: pages,
    );
  }

  /// The verbatim markdown for [path], or null when no such page exists (or its
  /// `.md` file is missing from the build).
  Future<String?> readPage(String path) async {
    if (_byPath[path] case final page?) return _body(page);
    return null;
  }

  /// Full-text search over titles, descriptions, and page bodies. Deterministic:
  /// ranked by weighted term frequency, ties broken by manifest order.
  Future<List<DocHit>> search(String query, {int limit = 10}) async {
    final terms = _terms(query);
    if (terms.isEmpty) return const [];

    final scored = <({DocPage page, int score, int index, String snippet})>[];
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final body = await _body(page) ?? '';
      final title = page.title.toLowerCase();
      final lowerBody = body.toLowerCase();
      final desc = page.description?.toLowerCase() ?? '';

      var score = 0;
      for (final term in terms) {
        score += _count(title, term) * 5;
        score += _count(desc, term) * 2;
        score += _count(lowerBody, term);
      }
      if (score > 0) {
        scored.add((page: page, score: score, index: i, snippet: _snippet(body, terms, page.description)));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.index.compareTo(b.index);
    });
    return [for (final s in scored.take(limit)) DocHit(s.page, s.snippet)];
  }

  Future<String?> _body(DocPage page) async {
    if (_bodies.containsKey(page.path)) return _bodies[page.path];
    final file = p.join(dir, page.mdFile.startsWith('/') ? page.mdFile.substring(1) : page.mdFile);
    final content = await fileSystem.fileExists(file) ? await fileSystem.readFile(file) : null;
    _bodies[page.path] = content;
    return content;
  }

  static List<String> _terms(String query) =>
      query.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toSet().toList();

  static int _count(String haystack, String term) => term.isEmpty ? 0 : term.allMatches(haystack).length;

  String _snippet(String body, List<String> terms, String? description) {
    final lower = body.toLowerCase();
    var idx = -1;
    for (final term in terms) {
      final at = lower.indexOf(term);
      if (at >= 0 && (idx < 0 || at < idx)) idx = at;
    }

    final raw = switch (idx) {
      >= 0 => _window(body, idx),
      _ => description ?? (body.length > 180 ? '${body.substring(0, 180)}…' : body),
    };
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _window(String body, int idx) {
    final start = idx - 40 < 0 ? 0 : idx - 40;
    final end = start + 180 > body.length ? body.length : start + 180;
    return '${start > 0 ? '…' : ''}${body.substring(start, end)}${end < body.length ? '…' : ''}';
  }

  static String? _asString(Object? value) => value is String ? value : null;
}
