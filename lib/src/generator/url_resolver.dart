import '../config/config.dart';

/// Single source of truth for every URL shape the generator emits.
class UrlResolver {
  final StardustConfig config;

  const UrlResolver(this.config);

  /// Href with the site base path applied: `/guide` -> `/docs/guide`.
  String href(String path) => '${config.basePath}$path';

  /// Absolute URL for canonical/OG/sitemap use, or null when no site url is
  /// configured. `config.url` already carries any subpath, so the base path
  /// is never re-applied here.
  String? absolute(String path) => switch (config.url) {
        final url? => '${_withoutTrailingSlash(url)}$path',
        null => null,
      };

  /// Relative prefix from a page back to the site root: `/a/b` -> `..`, `/` -> `.`.
  String relativeRoot(String pagePath) {
    final depth = pagePath.split('/').where((segment) => segment.isNotEmpty).length;
    return depth == 0 ? '.' : List.filled(depth, '..').join('/');
  }

  String _withoutTrailingSlash(String url) => url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
