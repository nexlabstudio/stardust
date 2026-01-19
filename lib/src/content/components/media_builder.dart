import '../utils/attribute_parser.dart';
import '../utils/icon_utils.dart';
import 'base_component.dart';

/// Builds media components: Image, Video, Mermaid, Tree
class MediaBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Image', 'Video', 'Mermaid', 'Tree'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'Image' => _buildImage(attributes, content),
        'Video' => _buildVideo(attributes, content),
        'Mermaid' => _buildMermaid(attributes, content),
        'Tree' => _buildTree(attributes, content),
        _ => content
      };

  String _buildImage(Map<String, String> attributes, String content) {
    final src = attributes['src'] ?? '';
    final alt = attributes['alt'] ?? '';
    final caption = attributes['caption'];
    final width = attributes['width'];
    final height = attributes['height'];
    final zoom = attributes['zoom'] == 'true' || attributes.containsKey('zoom');
    final rounded = attributes['rounded'] == 'true' || attributes.containsKey('rounded');
    final border = attributes['border'] == 'true' || attributes.containsKey('border');

    final styleList = <String>[];
    if (width case final width?) styleList.add('width: $width');
    if (height case final height?) styleList.add('height: $height');
    final styleAttr = styleList.isNotEmpty ? ' style="${styleList.join('; ')}"' : '';

    final classList = <String>['image-component'];
    if (zoom) classList.add('image-zoomable');
    if (rounded) classList.add('image-rounded');
    if (border) classList.add('image-bordered');
    final classAttr = ' class="${classList.join(' ')}"';

    final imgHtml = '<img src="$src" alt="$alt"$styleAttr loading="lazy" />';

    final zoomWrapper = zoom
        ? '''
<div class="image-zoom-wrapper" data-zoom-src="$src">
  $imgHtml
  <div class="image-zoom-hint">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/><path d="M11 8v6M8 11h6"/>
    </svg>
  </div>
</div>'''
        : imgHtml;

    if (caption case final caption?) {
      return '''
<figure$classAttr>
  $zoomWrapper
  <figcaption class="image-caption">$caption</figcaption>
</figure>
''';
    }

    return '<div$classAttr>$zoomWrapper</div>';
  }

  String _buildVideo(Map<String, String> attributes, String content) {
    final src = attributes['src'] ?? content.trim();
    final poster = attributes['poster'];
    final autoplay = attributes['autoplay'] == 'true';
    final loop = attributes['loop'] == 'true';
    final muted = attributes['muted'] == 'true' || autoplay;
    final controls = attributes['controls'] != 'false';
    final title = attributes['title'] ?? 'Video';

    if (src.isEmpty) {
      return '<div class="embed-error">Video: Missing source URL</div>';
    }

    final attrs = <String>[];
    if (controls) attrs.add('controls');
    if (autoplay) attrs.add('autoplay');
    if (loop) attrs.add('loop');
    if (muted) attrs.add('muted');
    if (poster case final poster?) attrs.add('poster="$poster"');

    return '''
<div class="embed embed-video">
  <video ${attrs.join(' ')} title="$title" preload="metadata">
    <source src="$src" />
    Your browser does not support the video tag.
  </video>
</div>
''';
  }

  String _buildMermaid(Map<String, String> attributes, String content) {
    final caption = attributes['caption'];
    final theme = attributes['theme'] ?? 'default';

    final escapedContent = content.trim().replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

    final diagramHtml = '''
<div class="mermaid-diagram" data-theme="$theme">
  <pre class="mermaid">$escapedContent</pre>
</div>''';

    if (caption case final caption?) {
      return '''
<figure class="mermaid-figure">
  $diagramHtml
  <figcaption class="mermaid-caption">$caption</figcaption>
</figure>
''';
    }

    return diagramHtml;
  }

  String _buildTree(Map<String, String> attributes, String content) {
    final treeContent = _processTreeContent(content, 0);

    return '''
<div class="tree">
  <ul class="tree-root">
$treeContent  </ul>
</div>
''';
  }

  String _processTreeContent(String content, int depth) {
    final buffer = StringBuffer();
    final indent = '    ' * (depth + 2);

    final folderPattern = RegExp(
      r'<Folder([^>]*)>([\s\S]*?)</Folder>',
      caseSensitive: false,
      dotAll: true,
    );

    final filePattern = RegExp(
      r'<File([^>]*?)(?:/>|>([\s\S]*?)</File>)',
      caseSensitive: false,
      dotAll: true,
    );

    final elements = <_TreeElement>[];

    for (final match in folderPattern.allMatches(content)) {
      final attrs = parseAttributes(match.group(1) ?? '');
      elements.add(_TreeElement(
        type: 'folder',
        start: match.start,
        name: attrs['name'] ?? 'folder',
        open: attrs['open'] == 'true' || attrs.containsKey('open'),
        content: match.group(2) ?? '',
      ));
    }

    for (final match in filePattern.allMatches(content)) {
      final attrs = parseAttributes(match.group(1) ?? '');
      elements.add(_TreeElement(
        type: 'file',
        start: match.start,
        name: attrs['name'] ?? 'file',
        icon: attrs['icon'],
      ));
    }

    elements.sort((a, b) => a.start.compareTo(b.start));

    for (final element in elements) {
      if (element.type == 'folder') {
        final openAttr = element.open ? ' open' : '';
        final nestedContent = _processTreeContent(element.content, depth + 1);
        buffer.writeln('$indent<li class="tree-folder">');
        buffer.writeln('$indent  <details$openAttr>');
        buffer.writeln('$indent    <summary class="tree-folder-name">');
        buffer.writeln('$indent      <span class="tree-icon tree-icon-folder">📁</span>');
        buffer.writeln('$indent      <span>${element.name}</span>');
        buffer.writeln('$indent    </summary>');
        buffer.writeln('$indent    <ul class="tree-children">');
        buffer.write(nestedContent);
        buffer.writeln('$indent    </ul>');
        buffer.writeln('$indent  </details>');
        buffer.writeln('$indent</li>');
      } else {
        final icon = element.icon ?? getFileIcon(element.name);
        buffer.writeln('$indent<li class="tree-file">');
        buffer.writeln('$indent  <span class="tree-icon tree-icon-file">$icon</span>');
        buffer.writeln('$indent  <span class="tree-file-name">${element.name}</span>');
        buffer.writeln('$indent</li>');
      }
    }

    return buffer.toString();
  }
}

class _TreeElement {
  final String type;
  final int start;
  final String name;
  final bool open;
  final String content;
  final String? icon;

  _TreeElement({
    required this.type,
    required this.start,
    required this.name,
    this.open = false,
    this.content = '',
    this.icon,
  });
}
