import '../content/markdown_parser.dart';

/// Represents a documentation page
class Page {
  /// URL path for this page (e.g., '/getting-started')
  final String path;

  /// Source file path
  final String sourcePath;

  /// Page title
  final String title;

  /// Page description
  final String? description;

  /// Rendered HTML content
  final String content;

  /// Table of contents
  final List<TocEntry> toc;

  /// Raw frontmatter
  final Map<String, dynamic> frontmatter;

  /// Previous page in navigation
  final PageLink? prev;

  /// Next page in navigation
  final PageLink? next;

  /// Breadcrumb trail
  final List<PageLink> breadcrumbs;

  /// Paths that should redirect to this page
  final List<String> redirectFrom;

  const Page({
    required this.path,
    required this.sourcePath,
    required this.title,
    this.description,
    required this.content,
    this.toc = const [],
    this.frontmatter = const {},
    this.prev,
    this.next,
    this.breadcrumbs = const [],
    this.redirectFrom = const [],
  });

  /// Output file path (e.g., 'getting-started/index.html')
  String get outputPath {
    if (path == '/') {
      return 'index.html';
    }
    return '${path.substring(1)}/index.html';
  }
}

/// A link to a page
class PageLink {
  final String path;
  final String title;

  const PageLink({
    required this.path,
    required this.title,
  });
}
