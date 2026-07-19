import 'package:highlight/highlight.dart' show highlight;
import 'package:markdown/markdown.dart' as md;

import '../config/config.dart';
import '../core/interfaces.dart';
import '../utils/html_utils.dart';
import '../utils/patterns.dart';
import 'component_transformer.dart';
import 'frontmatter_parser.dart';
import 'utils/code_masker.dart';
import 'utils/component_scanner.dart';

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
class MarkdownParser implements ContentParser {
  final StardustConfig config;
  final ContentTransformer componentTransformer;

  MarkdownParser({
    required this.config,
    ContentTransformer? componentTransformer,
  }) : componentTransformer = componentTransformer ?? ComponentTransformer(config: config.components);

  @override
  ParsedPage parse(String content, {String? defaultTitle}) {
    final doc = FrontmatterParser.parse(content);

    // Only block components are lifted over markdown; inline ones (Badge,
    // Icon, ...) must stay in the text so they keep their <p> wrapping.
    final masked = maskCodeSpans(doc.content);
    const tags = _blockComponents;

    final components = <String, String>{};
    final protectedDoc = StringBuffer();
    var pos = 0;
    for (var match = findFirstComponent(masked.text, tags, pos);
        match != null;
        match = findFirstComponent(masked.text, tags, pos)) {
      protectedDoc.write(masked.restore(masked.text.substring(pos, match.start)));
      final placeholder = '<!--STARDUSTCOMPONENT${components.length}-->';
      components[placeholder] = masked.restore(masked.text.substring(match.start, match.end));
      protectedDoc.write(placeholder);
      pos = match.end;
    }
    protectedDoc.write(masked.restore(masked.text.substring(pos)));

    final markdownHtml = md.markdownToHtml(
      protectedDoc.toString(),
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

    var restored = markdownHtml;
    for (final entry in components.entries) {
      restored = restored.replaceAll(entry.key, entry.value);
    }

    final transformed = componentTransformer.transform(restored);
    final html = _processMarkdownInComponentOutput(transformed);
    final highlightedHtml = _applySyntaxHighlighting(html);
    final toc = _extractToc(
      highlightedHtml,
      minDepth: config.toc.minDepth,
      maxDepth: config.toc.maxDepth,
    );
    final title = doc.title ?? defaultTitle ?? 'Untitled';

    return ParsedPage(
      title: title,
      description: doc.description,
      html: highlightedHtml,
      toc: toc,
      frontmatter: doc.frontmatter,
    );
  }

  static const _blockComponents = {
    'Tabs',
    'Accordion',
    'AccordionGroup',
    'Steps',
    'Cards',
    'CodeGroup',
    'Columns',
    'Panel',
    'Info',
    'Warning',
    'Danger',
    'Tip',
    'Note',
    'Success',
  };

  String _processMarkdownInComponentOutput(String html) {
    var result = html;
    for (final className in [
      'accordion-content',
      'step-content',
      'card-content',
      'callout-content',
      'panel-content',
      'column',
    ]) {
      result = _processContainersOfType(result, className);
    }
    return result;
  }

  String _processContainersOfType(String html, String className) {
    final openPattern = RegExp('<div class="$className[^"]*"[^>]*>');
    final out = StringBuffer();
    var searchStart = 0;

    while (true) {
      final openMatch = openPattern.allMatches(html, searchStart).firstOrNull;
      if (openMatch == null) break;

      final contentStart = openMatch.end;

      var depth = 1;
      var pos = contentStart;
      while (pos < html.length && depth > 0) {
        if (html.startsWith('</div>', pos)) {
          depth--;
          if (depth == 0) break;
          pos += 6;
        } else if (html.startsWith('<div', pos)) {
          depth++;
          pos++;
        } else {
          pos++;
        }
      }

      if (depth == 0) {
        out.write(html.substring(searchStart, contentStart));
        out.write(_processContainerContent(html.substring(contentStart, pos)));
        searchStart = pos;
      } else {
        out.write(html.substring(searchStart, contentStart));
        searchStart = contentStart;
      }
    }

    out.write(html.substring(searchStart));
    return out.toString();
  }

  String _processContainerContent(String content) {
    final protectedBlocks = <String, String>{};
    var result = content.replaceAllMapped(codeBlockPattern, (match) {
      final placeholder = '___BLOCK_${protectedBlocks.length}___';
      protectedBlocks[placeholder] = match.group(0) ?? '';
      return placeholder;
    });

    result = _dedent(result);
    result = md.markdownToHtml(
      result,
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

    for (final entry in protectedBlocks.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  String _dedent(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return text;

    int? minIndent;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final indent = line.length - line.trimLeft().length;
      if (indent > 0 && (minIndent == null || indent < minIndent)) {
        minIndent = indent;
      }
    }

    if (minIndent case final min? when min > 0) {
      return lines.map((line) {
        if (line.trim().isEmpty) return '';
        final indent = line.length - line.trimLeft().length;
        return indent >= min ? line.substring(min) : line;
      }).join('\n');
    }
    return text;
  }

  String _applySyntaxHighlighting(String html) => html.replaceAllMapped(codeBlockPattern, (match) {
        final language = match.group(1) ?? '';
        final code = decodeHtmlEntities(match.group(2) ?? '');

        try {
          final highlighted = highlight.parse(code, language: language);
          final highlightedHtml = _renderHighlight(highlighted.nodes ?? []);

          final copyButton =
              config.code.copyButton ? '<button class="copy-button" aria-label="Copy code">Copy</button>' : '';

          final lineNumbers =
              config.code.lineNumbers ? '<div class="line-numbers">${_generateLineNumbers(code)}</div>' : '';

          return '''
<div class="code-block" data-language="$language">
<div class="code-header">
<span class="code-language">$language</span>
$copyButton
</div>
<pre class="code-pre">$lineNumbers<code class="language-$language hljs">$highlightedHtml</code></pre>
</div>''';
        } catch (e) {
          return match.group(0) ?? match.input;
        }
      });

  String _renderHighlight(List<dynamic> nodes) {
    final buffer = StringBuffer();

    for (final node in nodes) {
      if (node is String) {
        buffer.write(encodeHtml(node));
      } else if (node.className != null) {
        buffer.write('<span class="hljs-${node.className}">');
        if (node.children != null) {
          buffer.write(_renderHighlight(node.children));
        } else if (node.value != null) {
          buffer.write(encodeHtml(node.value));
        }
        buffer.write('</span>');
      } else if (node.value != null) {
        buffer.write(encodeHtml(node.value));
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

  List<TocEntry> _extractToc(String html, {int minDepth = 2, int maxDepth = 4}) {
    final toc = <TocEntry>[];

    for (final match in headingPattern.allMatches(html)) {
      final (levelStr, id, rawText) = (match.group(1), match.group(2), match.group(3));
      if (levelStr == null || id == null || rawText == null) continue;

      final level = int.parse(levelStr);
      if (level >= minDepth && level <= maxDepth) {
        final text = stripHtml(rawText);
        toc.add(TocEntry(level: level, text: text, id: id));
      }
    }

    return toc;
  }
}
