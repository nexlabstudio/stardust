import 'package:highlight/highlight.dart' show highlight;
import 'package:markdown/markdown.dart' as md;

import '../config/config.dart';
import 'component_transformer.dart';
import 'frontmatter_parser.dart';

/// Parsed page result
class ParsedPage {
  final String title;
  final String? description;
  final String html;
  final List<TocEntry> toc;
  final Map<String, dynamic> frontmatter;

  const ParsedPage({
    required this.title,
    this.description,
    required this.html,
    required this.toc,
    required this.frontmatter,
  });
}

/// Table of contents entry
class TocEntry {
  final int level;
  final String text;
  final String id;

  const TocEntry({
    required this.level,
    required this.text,
    required this.id,
  });
}

/// Markdown parser with syntax highlighting and custom components
class MarkdownParser {
  final StardustConfig config;
  final ComponentTransformer _componentTransformer;

  MarkdownParser({required this.config})
      : _componentTransformer = ComponentTransformer(config: config.components);

  /// Parse markdown content into HTML
  ParsedPage parse(String content, {String? defaultTitle}) {
    // Extract frontmatter
    final doc = FrontmatterParser.parse(content);

    // Transform custom components
    final transformed = _componentTransformer.transform(doc.content);

    // Parse markdown to HTML
    final html = md.markdownToHtml(
      transformed,
      blockSyntaxes: [
        const md.FencedCodeBlockSyntax(),
        const md.HeaderWithIdSyntax(),
        const md.TableSyntax(),
      ],
      inlineSyntaxes: [
        md.StrikethroughSyntax(),
        md.AutolinkExtensionSyntax(),
      ],
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    // Apply syntax highlighting to code blocks
    final highlightedHtml = _applySyntaxHighlighting(html);

    // Extract table of contents
    final toc = _extractToc(
      highlightedHtml,
      minDepth: config.toc.minDepth,
      maxDepth: config.toc.maxDepth,
    );

    // Determine title
    final title = doc.title ?? defaultTitle ?? 'Untitled';

    return ParsedPage(
      title: title,
      description: doc.description,
      html: highlightedHtml,
      toc: toc,
      frontmatter: doc.frontmatter,
    );
  }

  String _applySyntaxHighlighting(String html) {
    final codeBlockPattern =
        RegExp(r'<pre><code class="language-(\w+)">([\s\S]*?)</code></pre>');

    return html.replaceAllMapped(codeBlockPattern, (match) {
      final language = match.group(1) ?? '';
      final code = _decodeHtmlEntities(match.group(2) ?? '');

      try {
        final highlighted = highlight.parse(code, language: language);
        final highlightedHtml = _renderHighlight(highlighted.nodes ?? []);

        final copyButton = config.code.copyButton
            ? '<button class="copy-button" aria-label="Copy code">Copy</button>'
            : '';

        final lineNumbers = config.code.lineNumbers
            ? '<div class="line-numbers">${_generateLineNumbers(code)}</div>'
            : '';

        return '''
<div class="code-block" data-language="$language">
<div class="code-header">
<span class="code-language">$language</span>
$copyButton
</div>
<pre class="code-pre">$lineNumbers<code class="language-$language hljs">$highlightedHtml</code></pre>
</div>''';
      } catch (e) {
        // Fallback if highlighting fails
        return match.group(0) ?? match.input;
      }
    });
  }

  String _renderHighlight(List<dynamic> nodes) {
    final buffer = StringBuffer();

    for (final node in nodes) {
      if (node is String) {
        buffer.write(_encodeHtml(node));
      } else if (node.className != null) {
        buffer.write('<span class="hljs-${node.className}">');
        if (node.children != null) {
          buffer.write(_renderHighlight(node.children));
        } else if (node.value != null) {
          buffer.write(_encodeHtml(node.value));
        }
        buffer.write('</span>');
      } else if (node.value != null) {
        buffer.write(_encodeHtml(node.value));
      } else if (node.children != null) {
        buffer.write(_renderHighlight(node.children));
      }
    }

    return buffer.toString();
  }

  String _generateLineNumbers(String code) {
    final lines = code.split('\n');
    final buffer = StringBuffer();
    for (var i = 1; i <= lines.length; i++) {
      buffer.writeln('<span class="line-number">$i</span>');
    }
    return buffer.toString();
  }

  List<TocEntry> _extractToc(String html,
      {int minDepth = 2, int maxDepth = 4}) {
    final toc = <TocEntry>[];
    final headingPattern =
        RegExp(r'<h([1-6])[^>]*id="([^"]+)"[^>]*>(.*?)</h\1>', dotAll: true);

    for (final match in headingPattern.allMatches(html)) {
      final (levelStr, id, rawText) = (match.group(1), match.group(2), match.group(3));
      if (levelStr == null || id == null || rawText == null) continue;

      final level = int.parse(levelStr);
      if (level >= minDepth && level <= maxDepth) {
        final text = _stripHtml(rawText);
        toc.add(TocEntry(level: level, text: text, id: id));
      }
    }

    return toc;
  }

  String _stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  String _decodeHtmlEntities(String text) => text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

  String _encodeHtml(String text) => text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
}
