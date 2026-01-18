import '../config/config.dart';

/// Transforms JSX-style components into HTML
///
/// Supports components like:
/// - `<Info>`, `<Warning>`, `<Danger>`, `<Tip>`, `<Note>`, `<Success>`
/// - `<Tabs>`, `<Tab>`
/// - `<CodeGroup>`, `<Code>`
/// - `<Accordion>`, `<AccordionGroup>`
/// - `<Steps>`, `<Step>`
/// - `<Cards>`, `<Card>`
class ComponentTransformer {
  final ComponentsConfig config;

  ComponentTransformer({this.config = const ComponentsConfig()});

  /// Transform JSX-style components in markdown content
  String transform(String content) {
    var result = content;

    result = _transformCallouts(result);
    result = _transformTabs(result);
    result = _transformCodeGroup(result);
    result = _transformAccordions(result);
    result = _transformSteps(result);
    result = _transformCards(result);

    result = _transformColumns(result);
    result = _transformTiles(result);
    result = _transformPanel(result);
    result = _transformBadge(result);
    result = _transformIcon(result);

    result = _transformImage(result);
    result = _transformTree(result);
    result = _transformMermaid(result);
    result = _transformTooltip(result);

    result = _transformYouTube(result);
    result = _transformVimeo(result);
    result = _transformVideo(result);
    result = _transformZapp(result);
    result = _transformCodePen(result);
    result = _transformStackBlitz(result);

    result = _transformField(result);
    result = _transformResponseField(result);
    result = _transformParamField(result);
    result = _transformApiEndpoint(result);

    result = _transformFrame(result);
    result = _transformUpdate(result);

    return result;
  }

  String _transformCallouts(String content) {
    final calloutTypes = ['Info', 'Warning', 'Danger', 'Tip', 'Note', 'Success'];
    var result = content;

    for (final type in calloutTypes) {
      result = _transformComponent(
        result,
        type,
        (attributes, innerContent) => _buildCallout(type.toLowerCase(), attributes, innerContent),
      );
    }

    return result;
  }

  String _buildCallout(String type, Map<String, String> attributes, String content) {
    final title = attributes['title'];
    final icon = attributes['icon'];

    final calloutConfig =
        config.callouts[type] ?? _defaultCallouts[type] ?? const CalloutConfig(icon: '📌', color: '#6b7280');

    final rawIcon = icon ?? calloutConfig.icon;
    String displayIcon;
    if (_isEmoji(rawIcon)) {
      displayIcon = rawIcon;
    } else {
      final svg = _getBuiltInIcon(rawIcon, '18');
      displayIcon = svg ?? rawIcon;
    }
    final displayTitle = title ?? _capitalize(type);

    return '''
<div class="callout callout-$type" style="--callout-color: ${calloutConfig.color}">
  <p class="callout-title">$displayIcon $displayTitle</p>
  <div class="callout-content">

$content

  </div>
</div>
''';
  }

  static const _defaultCallouts = {
    'info': CalloutConfig(icon: 'ℹ️', color: '#3b82f6'),
    'warning': CalloutConfig(icon: '⚠️', color: '#f59e0b'),
    'danger': CalloutConfig(icon: '🚨', color: '#ef4444'),
    'tip': CalloutConfig(icon: '💡', color: '#22c55e'),
    'note': CalloutConfig(icon: '📝', color: '#8b5cf6'),
    'success': CalloutConfig(icon: '✅', color: '#10b981'),
  };

  String _transformTabs(String content) => _transformComponent(
        content,
        'Tabs',
        _buildTabs,
      );

  String _buildTabs(Map<String, String> attributes, String content) {
    // Extract individual <Tab> components
    final tabs = _extractChildComponents(content, 'Tab');

    if (tabs.isEmpty) {
      return '<div class="tabs-empty">No tabs defined</div>';
    }

    final tabsId = 'tabs-${_generateId()}';
    final tabButtons = StringBuffer();
    final tabPanels = StringBuffer();

    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final name = tab.attributes['name'] ?? 'Tab ${i + 1}';
      final isActive = i == 0;
      final tabId = '$tabsId-$i';

      tabButtons.writeln('''
    <button class="tab-button${isActive ? ' active' : ''}" 
            data-tab="$tabId" 
            role="tab" 
            aria-selected="${isActive ? 'true' : 'false'}">
      $name
    </button>''');

      tabPanels.writeln('''
    <div class="tab-panel${isActive ? ' active' : ''}" 
         id="$tabId" 
         role="tabpanel"${isActive ? '' : ' hidden'}>

${tab.content}

    </div>''');
    }

    return '''
<div class="tabs" data-tabs-id="$tabsId">
  <div class="tab-buttons" role="tablist">
$tabButtons  </div>
  <div class="tab-panels">
$tabPanels  </div>
</div>
''';
  }

  String _transformCodeGroup(String content) => _transformComponent(
        content,
        'CodeGroup',
        _buildCodeGroup,
      );

  String _buildCodeGroup(Map<String, String> attributes, String content) {
    // Extract individual <Code> components
    final codeBlocks = _extractChildComponents(content, 'Code');

    if (codeBlocks.isEmpty) {
      return '<div class="code-group-empty">No code blocks defined</div>';
    }

    final groupId = 'code-group-${_generateId()}';
    final tabButtons = StringBuffer();
    final tabPanels = StringBuffer();

    for (var i = 0; i < codeBlocks.length; i++) {
      final block = codeBlocks[i];
      final title = block.attributes['title'] ?? 'Code ${i + 1}';
      final language = block.attributes['language'] ?? block.attributes['lang'] ?? '';
      final isActive = i == 0;
      final tabId = '$groupId-$i';

      tabButtons.writeln('''
    <button class="tab-button${isActive ? ' active' : ''}" 
            data-tab="$tabId" 
            role="tab" 
            aria-selected="${isActive ? 'true' : 'false'}">
      $title
    </button>''');

      // Wrap content in code fence if not already
      var codeContent = block.content.trim();
      if (!codeContent.startsWith('```')) {
        codeContent = '```$language\n$codeContent\n```';
      }

      tabPanels.writeln('''
    <div class="tab-panel${isActive ? ' active' : ''}" 
         id="$tabId" 
         role="tabpanel"${isActive ? '' : ' hidden'}>

$codeContent

    </div>''');
    }

    return '''
<div class="code-group" data-code-group-id="$groupId">
  <div class="tab-buttons" role="tablist">
$tabButtons  </div>
  <div class="tab-panels">
$tabPanels  </div>
</div>
''';
  }

  String _transformAccordions(String content) {
    // First transform AccordionGroup
    var result = _transformComponent(
      content,
      'AccordionGroup',
      _buildAccordionGroup,
    );

    // Then transform standalone Accordions
    result = _transformComponent(
      result,
      'Accordion',
      _buildAccordion,
    );

    return result;
  }

  String _buildAccordionGroup(Map<String, String> attributes, String content) {
    // Extract individual <Accordion> components and build them
    final accordions = _extractChildComponents(content, 'Accordion');

    final accordionHtml = StringBuffer();
    for (final accordion in accordions) {
      accordionHtml.writeln(_buildAccordion(accordion.attributes, accordion.content));
    }

    return '''
<div class="accordion-group">
$accordionHtml</div>
''';
  }

  String _buildAccordion(Map<String, String> attributes, String content) {
    final title = attributes['title'] ?? 'Details';
    final icon = attributes['icon'] ?? '';
    final defaultOpen = attributes['defaultOpen'] == 'true' || attributes['open'] == 'true';

    String iconHtml = '';
    if (icon.isNotEmpty) {
      if (_isEmoji(icon)) {
        iconHtml = '<span class="accordion-icon">$icon</span> ';
      } else {
        final svg = _getBuiltInIcon(icon, '18');
        iconHtml =
            svg != null ? '<span class="accordion-icon">$svg</span> ' : '<span class="accordion-icon">$icon</span> ';
      }
    }

    return '''
<details class="accordion"${defaultOpen ? ' open' : ''}>
  <summary class="accordion-summary">$iconHtml$title</summary>
  <div class="accordion-content">

$content

  </div>
</details>
''';
  }

  String _transformSteps(String content) => _transformComponent(
        content,
        'Steps',
        _buildSteps,
      );

  String _buildSteps(Map<String, String> attributes, String content) {
    final steps = _extractChildComponents(content, 'Step');

    if (steps.isEmpty) {
      return '<div class="steps-empty">No steps defined</div>';
    }

    final stepsHtml = StringBuffer();
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final title = step.attributes['title'] ?? '';
      final icon = step.attributes['icon'];
      final stepNumber = step.attributes['stepNumber'] ?? '${i + 1}';

      String numberDisplay;
      if (icon == null) {
        numberDisplay = stepNumber;
      } else if (_isEmoji(icon)) {
        numberDisplay = icon;
      } else {
        final svg = _getBuiltInIcon(icon, '18');
        numberDisplay = svg ?? icon;
      }

      stepsHtml.writeln('''
  <div class="step">
    <div class="step-indicator">
      <div class="step-number">$numberDisplay</div>
      <div class="step-line"></div>
    </div>
    <div class="step-body">
      ${title.isNotEmpty ? '<h4 class="step-title">$title</h4>' : ''}
      <div class="step-content">

${step.content}

      </div>
    </div>
  </div>''');
    }

    return '''
<div class="steps">
$stepsHtml</div>
''';
  }

  String _transformCards(String content) {
    // First transform Cards container
    var result = _transformComponent(
      content,
      'Cards',
      _buildCards,
    );

    // Then transform standalone Card
    result = _transformComponent(
      result,
      'Card',
      _buildCard,
    );

    return result;
  }

  String _buildCards(Map<String, String> attributes, String content) {
    final columns = attributes['columns'] ?? '2';
    final cards = _extractChildComponents(content, 'Card');

    final cardsHtml = StringBuffer();
    for (final card in cards) {
      cardsHtml.writeln(_buildCard(card.attributes, card.content));
    }

    return '''
<div class="cards" style="--cards-columns: $columns">
$cardsHtml</div>
''';
  }

  String _buildCard(Map<String, String> attributes, String content) {
    final title = attributes['title'] ?? '';
    final icon = attributes['icon'];
    final href = attributes['href'];

    String iconHtml = '';
    if (icon != null) {
      if (_isEmoji(icon)) {
        iconHtml = '<span class="card-icon">$icon</span>';
      } else {
        final svg = _getBuiltInIcon(icon, '20');
        iconHtml = svg != null ? '<span class="card-icon">$svg</span>' : '<span class="card-icon">$icon</span>';
      }
    }

    final titleHtml = title.isNotEmpty ? '<h3 class="card-title">$iconHtml$title</h3>' : '';

    final cardContent = '''
$titleHtml
<div class="card-content">

$content

</div>
''';

    if (href != null) {
      return '''
<a href="$href" class="card card-link">
$cardContent</a>
''';
    }

    return '''
<div class="card">
$cardContent</div>
''';
  }

  String _transformColumns(String content) => _transformComponent(
        content,
        'Columns',
        _buildColumns,
      );

  String _buildColumns(Map<String, String> attributes, String content) {
    final columns = _extractChildComponents(content, 'Column');
    final gap = attributes['gap'] ?? '1rem';

    if (columns.isEmpty) {
      // If no explicit Column children, split content by Column tags
      return '''
<div class="columns" style="--columns-gap: $gap">
  <div class="column">

$content

  </div>
</div>
''';
    }

    final columnsHtml = StringBuffer();
    for (final column in columns) {
      final width = column.attributes['width'];
      final styleAttr = width != null ? ' style="flex: 0 0 $width; max-width: $width;"' : '';

      columnsHtml.writeln('''
  <div class="column"$styleAttr>

${column.content}

  </div>''');
    }

    return '''
<div class="columns" style="--columns-gap: $gap">
$columnsHtml</div>
''';
  }

  String _transformTiles(String content) => _transformComponent(
        content,
        'Tiles',
        _buildTiles,
      );

  String _buildTiles(Map<String, String> attributes, String content) {
    final columns = attributes['columns'] ?? '3';
    final tiles = _extractChildComponents(content, 'Tile');

    if (tiles.isEmpty) {
      return '<div class="tiles-empty">No tiles defined</div>';
    }

    final tilesHtml = StringBuffer();
    for (final tile in tiles) {
      tilesHtml.writeln(_buildTile(tile.attributes, tile.content));
    }

    return '''
<div class="tiles" style="--tiles-columns: $columns">
$tilesHtml</div>
''';
  }

  String _buildTile(Map<String, String> attributes, String content) {
    final title = attributes['title'] ?? '';
    final icon = attributes['icon'];
    final href = attributes['href'];

    String iconHtml = '';
    if (icon != null) {
      if (_isEmoji(icon)) {
        iconHtml = '<div class="tile-icon">$icon</div>';
      } else {
        final svg = _getBuiltInIcon(icon, '24');
        iconHtml = svg != null ? '<div class="tile-icon">$svg</div>' : '<div class="tile-icon">$icon</div>';
      }
    }

    final titleHtml = title.isNotEmpty ? '<h4 class="tile-title">$title</h4>' : '';

    final tileContent = '''
$iconHtml
$titleHtml
<div class="tile-content">

$content

</div>
''';

    if (href != null) {
      return '''
<a href="$href" class="tile tile-link">
$tileContent</a>
''';
    }

    return '''
<div class="tile">
$tileContent</div>
''';
  }

  String _transformPanel(String content) => _transformComponent(
        content,
        'Panel',
        _buildPanel,
      );

  String _buildPanel(Map<String, String> attributes, String content) {
    final title = attributes['title'];
    final icon = attributes['icon'];
    final variant = attributes['variant'] ?? 'default';

    String iconHtml = '';
    if (icon != null) {
      if (_isEmoji(icon)) {
        iconHtml = '<span class="panel-icon">$icon</span>';
      } else {
        final svg = _getBuiltInIcon(icon, '20');
        iconHtml = svg != null ? '<span class="panel-icon">$svg</span>' : '<span class="panel-icon">$icon</span>';
      }
    }

    final headerHtml = title != null
        ? '''
  <div class="panel-header">
    $iconHtml
    <span class="panel-title">$title</span>
  </div>
'''
        : '';

    return '''
<div class="panel panel-$variant">
$headerHtml  <div class="panel-content">

$content

  </div>
</div>
''';
  }

  String _transformBadge(String content) => _transformComponent(
        content,
        'Badge',
        _buildBadge,
      );

  String _buildBadge(Map<String, String> attributes, String content) {
    final variant = attributes['variant'] ?? 'default';
    final size = attributes['size'] ?? 'md';
    final icon = attributes['icon'];

    String iconHtml = '';
    if (icon != null) {
      if (_isEmoji(icon)) {
        iconHtml = '<span class="badge-icon">$icon</span>';
      } else {
        final svg = _getBuiltInIcon(icon, '14');
        iconHtml = svg != null ? '<span class="badge-icon">$svg</span>' : '<span class="badge-icon">$icon</span>';
      }
    }

    return '<span class="badge badge-$variant badge-$size">$iconHtml$content</span>';
  }

  String _transformIcon(String content) => _transformComponent(
        content,
        'Icon',
        _buildIcon,
      );

  String _buildIcon(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? content.trim();
    final size = attributes['size'] ?? '20';
    final color = attributes['color'];

    final styleAttr = color != null ? ' style="color: $color;"' : '';

    // Check if it's an emoji or icon name
    if (_isEmoji(name)) {
      return '<span class="icon icon-emoji" style="font-size: ${size}px;"$styleAttr>$name</span>';
    }

    // For named icons, we'll use a simple SVG icon system
    // Users can extend this with their own icon set
    final svg = _getBuiltInIcon(name, size);
    if (svg != null) {
      return '<span class="icon icon-svg"$styleAttr>$svg</span>';
    }

    // Fallback: render as text
    return '<span class="icon icon-text"$styleAttr>$name</span>';
  }

  bool _isEmoji(String text) {
    // Simple emoji detection
    final emojiPattern = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]',
      unicode: true,
    );
    return emojiPattern.hasMatch(text);
  }

  String? _getBuiltInIcon(String name, String size) {
    final iconName = name.toLowerCase().replaceAll('_', '-');
    return '<i data-lucide="$iconName" style="width: ${size}px; height: ${size}px;"></i>';
  }

  String _transformImage(String content) => _transformComponent(
        content,
        'Image',
        _buildImage,
      );

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
    if (width != null) styleList.add('width: $width');
    if (height != null) styleList.add('height: $height');
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

    if (caption != null) {
      return '''
<figure$classAttr>
  $zoomWrapper
  <figcaption class="image-caption">$caption</figcaption>
</figure>
''';
    }

    return '<div$classAttr>$zoomWrapper</div>';
  }

  String _transformTree(String content) {
    // First process the Tree container
    final result = _transformComponent(
      content,
      'Tree',
      _buildTree,
    );

    return result;
  }

  String _buildTree(Map<String, String> attributes, String content) {
    // Process nested Folder and File components
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

    // Extract Folder components
    final folderPattern = RegExp(
      r'<Folder([^>]*)>([\s\S]*?)</Folder>',
      caseSensitive: false,
      dotAll: true,
    );

    // Extract File components (self-closing or with content)
    final filePattern = RegExp(
      r'<File([^>]*?)(?:/>|>([\s\S]*?)</File>)',
      caseSensitive: false,
      dotAll: true,
    );

    // Track positions to maintain order
    final elements = <_TreeElement>[];

    for (final match in folderPattern.allMatches(content)) {
      final attrs = _parseAttributes(match.group(1) ?? '');
      elements.add(_TreeElement(
        type: 'folder',
        start: match.start,
        name: attrs['name'] ?? 'folder',
        open: attrs['open'] == 'true' || attrs.containsKey('open'),
        content: match.group(2) ?? '',
      ));
    }

    for (final match in filePattern.allMatches(content)) {
      final attrs = _parseAttributes(match.group(1) ?? '');
      elements.add(_TreeElement(
        type: 'file',
        start: match.start,
        name: attrs['name'] ?? 'file',
        icon: attrs['icon'],
      ));
    }

    // Sort by position in original content
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
        final icon = element.icon ?? _getFileIcon(element.name);
        buffer.writeln('$indent<li class="tree-file">');
        buffer.writeln('$indent  <span class="tree-icon tree-icon-file">$icon</span>');
        buffer.writeln('$indent  <span class="tree-file-name">${element.name}</span>');
        buffer.writeln('$indent</li>');
      }
    }

    return buffer.toString();
  }

  String _getFileIcon(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';

    final iconMap = {
      'dart': '🎯',
      'js': '📜',
      'ts': '📘',
      'jsx': '⚛️',
      'tsx': '⚛️',
      'py': '🐍',
      'rb': '💎',
      'go': '🐹',
      'rs': '🦀',
      'java': '☕',
      'kt': '🇰',
      'swift': '🍎',
      'c': '🔷',
      'cpp': '🔷',
      'h': '🔷',
      'cs': '🟣',
      'php': '🐘',
      'html': '🌐',
      'css': '🎨',
      'scss': '🎨',
      'sass': '🎨',
      'less': '🎨',
      'json': '📋',
      'yaml': '📋',
      'yml': '📋',
      'toml': '📋',
      'xml': '📋',
      'md': '📝',
      'mdx': '📝',
      'txt': '📄',
      'pdf': '📕',
      'doc': '📘',
      'docx': '📘',
      'xls': '📗',
      'xlsx': '📗',
      'ppt': '📙',
      'pptx': '📙',
      'png': '🖼️',
      'jpg': '🖼️',
      'jpeg': '🖼️',
      'gif': '🖼️',
      'svg': '🖼️',
      'webp': '🖼️',
      'ico': '🖼️',
      'mp3': '🎵',
      'wav': '🎵',
      'mp4': '🎬',
      'mov': '🎬',
      'avi': '🎬',
      'zip': '📦',
      'tar': '📦',
      'gz': '📦',
      'rar': '📦',
      '7z': '📦',
      'env': '🔐',
      'lock': '🔒',
      'gitignore': '🙈',
      'dockerignore': '🐳',
      'dockerfile': '🐳',
      'makefile': '🔧',
      'sh': '🐚',
      'bash': '🐚',
      'zsh': '🐚',
      'fish': '🐚',
    };

    return iconMap[ext] ?? '📄';
  }

  String _transformMermaid(String content) => _transformComponent(
        content,
        'Mermaid',
        _buildMermaid,
      );

  String _buildMermaid(Map<String, String> attributes, String content) {
    final caption = attributes['caption'];
    final theme = attributes['theme'] ?? 'default';

    // Escape content for safe embedding
    final escapedContent = content.trim().replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

    final diagramHtml = '''
<div class="mermaid-diagram" data-theme="$theme">
  <pre class="mermaid">$escapedContent</pre>
</div>''';

    if (caption != null) {
      return '''
<figure class="mermaid-figure">
  $diagramHtml
  <figcaption class="mermaid-caption">$caption</figcaption>
</figure>
''';
    }

    return diagramHtml;
  }

  String _transformTooltip(String content) => _transformComponent(
        content,
        'Tooltip',
        _buildTooltip,
      );

  String _buildTooltip(Map<String, String> attributes, String content) {
    final tip = attributes['content'] ?? attributes['tip'] ?? '';
    final position = attributes['position'] ?? 'top';

    // Escape the tooltip content
    final escapedTip = tip.replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

    return '''<span class="tooltip tooltip-$position" data-tooltip="$escapedTip">$content</span>''';
  }

  String _transformYouTube(String content) => _transformComponent(
        content,
        'YouTube',
        _buildYouTube,
      );

  String _buildYouTube(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final title = attributes['title'] ?? 'YouTube video';
    final start = attributes['start'];
    final aspectRatio = attributes['aspectRatio'] ?? '16/9';

    if (id.isEmpty) {
      return '<div class="embed-error">YouTube: Missing video ID</div>';
    }

    // Extract video ID from various URL formats
    final videoId = _extractYouTubeId(id);

    var embedUrl = 'https://www.youtube.com/embed/$videoId';
    if (start != null) {
      embedUrl += '?start=$start';
    }

    return '''
<div class="embed embed-youtube" style="aspect-ratio: $aspectRatio">
  <iframe 
    src="$embedUrl" 
    title="$title"
    frameborder="0" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _extractYouTubeId(String input) {
    // Handle direct ID
    if (!input.contains('/') && !input.contains('.')) {
      return input;
    }

    // Handle various YouTube URL formats
    final patterns = [
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]+)'),
    ];

    for (final pattern in patterns) {
      if (pattern.firstMatch(input)?.group(1) case final id?) {
        return id;
      }
    }

    return input;
  }

  String _transformVimeo(String content) => _transformComponent(
        content,
        'Vimeo',
        _buildVimeo,
      );

  String _buildVimeo(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final title = attributes['title'] ?? 'Vimeo video';
    final aspectRatio = attributes['aspectRatio'] ?? '16/9';

    if (id.isEmpty) {
      return '<div class="embed-error">Vimeo: Missing video ID</div>';
    }

    // Extract video ID from URL if needed
    final videoId = _extractVimeoId(id);

    return '''
<div class="embed embed-vimeo" style="aspect-ratio: $aspectRatio">
  <iframe 
    src="https://player.vimeo.com/video/$videoId" 
    title="$title"
    frameborder="0" 
    allow="autoplay; fullscreen; picture-in-picture" 
    allowfullscreen
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _extractVimeoId(String input) {
    if (!input.contains('/') && !input.contains('.')) {
      return input;
    }

    final pattern = RegExp(r'vimeo\.com/(?:video/)?(\d+)');
    if (pattern.firstMatch(input)?.group(1) case final id?) {
      return id;
    }

    return input;
  }

  String _transformVideo(String content) => _transformComponent(
        content,
        'Video',
        _buildVideo,
      );

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
    if (poster != null) attrs.add('poster="$poster"');

    return '''
<div class="embed embed-video">
  <video ${attrs.join(' ')} title="$title" preload="metadata">
    <source src="$src" />
    Your browser does not support the video tag.
  </video>
</div>
''';
  }

  String _transformZapp(String content) => _transformComponent(
        content,
        'Zapp',
        _buildZapp,
      );

  String _buildZapp(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final theme = attributes['theme'] ?? 'dark';
    final lazy = attributes['lazy'] != 'false';
    final height = attributes['height'] ?? '500px';

    if (id.isEmpty) {
      return '<div class="embed-error">Zapp: Missing project ID</div>';
    }

    // Zapp.run embed URL
    final embedUrl = 'https://zapp.run/edit/$id?theme=$theme&lazy=$lazy';

    return '''
<div class="embed embed-zapp" style="height: $height">
  <iframe 
    src="$embedUrl" 
    title="Zapp Dart/Flutter Playground"
    frameborder="0" 
    allow="clipboard-write"
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _transformCodePen(String content) => _transformComponent(
        content,
        'CodePen',
        _buildCodePen,
      );

  String _buildCodePen(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? '';
    final user = attributes['user'] ?? '';
    final title = attributes['title'] ?? 'CodePen';
    final height = attributes['height'] ?? '400';
    final defaultTab = attributes['defaultTab'] ?? 'result';
    final theme = attributes['theme'] ?? 'dark';
    final editable = attributes['editable'] == 'true';

    if (id.isEmpty || user.isEmpty) {
      return '<div class="embed-error">CodePen: Missing user or pen ID</div>';
    }

    final editableParam = editable ? '&editable=true' : '';
    final embedUrl = 'https://codepen.io/$user/embed/$id?default-tab=$defaultTab&theme-id=$theme$editableParam';

    return '''
<div class="embed embed-codepen" style="height: ${height}px">
  <iframe 
    src="$embedUrl" 
    title="$title"
    frameborder="0" 
    allowtransparency="true"
    allowfullscreen="true"
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _transformStackBlitz(String content) => _transformComponent(
        content,
        'StackBlitz',
        _buildStackBlitz,
      );

  String _buildStackBlitz(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final title = attributes['title'] ?? 'StackBlitz';
    final height = attributes['height'] ?? '500px';
    final file = attributes['file'];
    final embed = attributes['embed'] ?? '1';
    final hideNavigation = attributes['hideNavigation'] == 'true' ? '1' : '0';
    final hideDevTools = attributes['hideDevTools'] == 'true' ? '1' : '0';
    final view = attributes['view'] ?? 'preview';

    if (id.isEmpty) {
      return '<div class="embed-error">StackBlitz: Missing project ID</div>';
    }

    var embedUrl =
        'https://stackblitz.com/edit/$id?embed=$embed&hideNavigation=$hideNavigation&hideDevtools=$hideDevTools&view=$view';
    if (file != null) {
      embedUrl += '&file=$file';
    }

    return '''
<div class="embed embed-stackblitz" style="height: $height">
  <iframe 
    src="$embedUrl" 
    title="$title"
    frameborder="0" 
    allow="accelerometer; ambient-light-sensor; camera; encrypted-media; geolocation; gyroscope; hid; microphone; midi; payment; usb; vr; xr-spatial-tracking"
    sandbox="allow-forms allow-modals allow-popups allow-presentation allow-same-origin allow-scripts"
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _transformField(String content) => _transformComponent(
        content,
        'Field',
        _buildField,
      );

  String _buildField(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? '';
    final type = attributes['type'] ?? 'any';
    final required = attributes['required'] == 'true' || attributes.containsKey('required');
    final defaultValue = attributes['default'];
    final deprecated = attributes['deprecated'] == 'true';

    final requiredBadge = required
        ? '<span class="field-badge field-required">required</span>'
        : '<span class="field-badge field-optional">optional</span>';

    final deprecatedBadge = deprecated ? '<span class="field-badge field-deprecated">deprecated</span>' : '';

    final defaultHtml =
        defaultValue != null ? '<span class="field-default">Default: <code>$defaultValue</code></span>' : '';

    return '''
<div class="field${deprecated ? ' field-is-deprecated' : ''}">
  <div class="field-header">
    <code class="field-name">$name</code>
    <span class="field-type">$type</span>
    $requiredBadge
    $deprecatedBadge
  </div>
  $defaultHtml
  <div class="field-description">

$content

  </div>
</div>
''';
  }

  String _transformResponseField(String content) => _transformComponent(
        content,
        'ResponseField',
        _buildResponseField,
      );

  String _buildResponseField(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? '';
    final type = attributes['type'] ?? 'any';
    final nullable = attributes['nullable'] == 'true';

    final nullableBadge = nullable ? '<span class="field-badge field-nullable">nullable</span>' : '';

    return '''
<div class="field field-response">
  <div class="field-header">
    <code class="field-name">$name</code>
    <span class="field-type">$type</span>
    $nullableBadge
  </div>
  <div class="field-description">

$content

  </div>
</div>
''';
  }

  String _transformParamField(String content) => _transformComponent(
        content,
        'ParamField',
        _buildParamField,
      );

  String _buildParamField(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? '';
    final type = attributes['type'] ?? 'string';
    final paramType = attributes['paramType'] ?? attributes['in'] ?? 'query';
    final required = attributes['required'] == 'true' || attributes.containsKey('required');
    final defaultValue = attributes['default'];

    final requiredBadge = required
        ? '<span class="field-badge field-required">required</span>'
        : '<span class="field-badge field-optional">optional</span>';

    final paramTypeBadge = '<span class="field-badge field-param-type">$paramType</span>';

    final defaultHtml =
        defaultValue != null ? '<span class="field-default">Default: <code>$defaultValue</code></span>' : '';

    return '''
<div class="field field-param">
  <div class="field-header">
    <code class="field-name">$name</code>
    <span class="field-type">$type</span>
    $paramTypeBadge
    $requiredBadge
  </div>
  $defaultHtml
  <div class="field-description">

$content

  </div>
</div>
''';
  }

  String _transformApiEndpoint(String content) => _transformComponent(
        content,
        'Api',
        _buildApiEndpoint,
      );

  String _buildApiEndpoint(Map<String, String> attributes, String content) {
    final method = (attributes['method'] ?? 'GET').toUpperCase();
    final path = attributes['path'] ?? attributes['endpoint'] ?? '/';
    final title = attributes['title'];
    final auth = attributes['auth'];

    final methodClass = 'api-method-${method.toLowerCase()}';

    final titleHtml = title != null ? '<div class="api-title">$title</div>' : '';

    final authHtml = auth != null ? '<span class="api-auth">🔒 $auth</span>' : '';

    return '''
<div class="api-endpoint">
  <div class="api-header">
    <span class="api-method $methodClass">$method</span>
    <code class="api-path">$path</code>
    $authHtml
  </div>
  $titleHtml
  <div class="api-content">

$content

  </div>
</div>
''';
  }

  String _transformFrame(String content) => _transformComponent(
        content,
        'Frame',
        _buildFrame,
      );

  String _buildFrame(Map<String, String> attributes, String content) {
    final type = attributes['type'] ?? 'browser';
    final url = attributes['url'];

    if (type == 'phone' || type == 'mobile') {
      return _buildPhoneFrame(attributes, content);
    }

    // Browser frame
    final urlBar = url != null ? '<div class="frame-url">$url</div>' : '';

    return '''
<div class="frame frame-browser">
  <div class="frame-header">
    <div class="frame-buttons">
      <span class="frame-button frame-close"></span>
      <span class="frame-button frame-minimize"></span>
      <span class="frame-button frame-maximize"></span>
    </div>
    $urlBar
  </div>
  <div class="frame-content">

$content

  </div>
</div>
''';
  }

  String _buildPhoneFrame(Map<String, String> attributes, String content) {
    final device = attributes['device'] ?? 'iphone';

    return '''
<div class="frame frame-phone frame-$device">
  <div class="frame-phone-notch"></div>
  <div class="frame-content">

$content

  </div>
  <div class="frame-phone-home"></div>
</div>
''';
  }

  String _transformUpdate(String content) => _transformComponent(
        content,
        'Update',
        _buildUpdate,
      );

  String _buildUpdate(Map<String, String> attributes, String content) {
    final label = attributes['label'] ?? 'Update';
    final version = attributes['version'];
    final date = attributes['date'];
    final type = attributes['type'] ?? 'default';

    final typeClass = 'update-$type';

    final versionHtml = version != null ? '<span class="update-version">v$version</span>' : '';

    final dateHtml = date != null ? '<span class="update-date">$date</span>' : '';

    return '''
<div class="update $typeClass">
  <div class="update-header">
    <span class="update-label">$label</span>
    $versionHtml
    $dateHtml
  </div>
  <div class="update-content">

$content

  </div>
</div>
''';
  }

  /// Generic component transformer
  /// Finds `<ComponentName>`...`</ComponentName>` and transforms it
  String _transformComponent(
    String content,
    String componentName,
    String Function(Map<String, String> attributes, String innerContent) builder,
  ) {
    // Pattern for self-closing: <Component attr="value" />
    final selfClosingPattern = RegExp(
      '<$componentName([^>]*?)/>',
      caseSensitive: false,
      dotAll: true,
    );

    // Pattern for open/close: <Component attr="value">content</Component>
    final openClosePattern = RegExp(
      '<$componentName([^>]*)>([\\s\\S]*?)</$componentName>',
      caseSensitive: false,
      dotAll: true,
    );

    var result = content;

    // Handle self-closing tags first
    result = result.replaceAllMapped(selfClosingPattern, (match) {
      final attributesStr = match.group(1) ?? '';
      final attributes = _parseAttributes(attributesStr);
      return builder(attributes, '');
    });

    // Handle open/close tags (may need multiple passes for nested same-type components)
    var previousResult = '';
    while (previousResult != result) {
      previousResult = result;
      result = result.replaceAllMapped(openClosePattern, (match) {
        final attributesStr = match.group(1) ?? '';
        final innerContent = match.group(2) ?? '';
        final attributes = _parseAttributes(attributesStr);
        return builder(attributes, innerContent.trim());
      });
    }

    return result;
  }

  /// Extract child components from content
  List<_ExtractedComponent> _extractChildComponents(String content, String componentName) {
    final components = <_ExtractedComponent>[];

    // Pattern for open/close tags
    final pattern = RegExp(
      '<$componentName([^>]*)>([\\s\\S]*?)</$componentName>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in pattern.allMatches(content)) {
      final attributesStr = match.group(1) ?? '';
      final innerContent = match.group(2) ?? '';
      components.add(_ExtractedComponent(
        attributes: _parseAttributes(attributesStr),
        content: innerContent.trim(),
      ));
    }

    return components;
  }

  /// Parse HTML-style attributes: attr="value" attr='value' attr={value}
  Map<String, String> _parseAttributes(String attributesStr) {
    final attributes = <String, String>{};

    // Pattern for various attribute formats
    // attr="value" or attr='value' or attr={value} or just attr
    final pattern = RegExp(
      r'''(\w+)(?:=(?:"([^"]*)"|'([^']*)'|\{([^}]*)\}))?''',
    );

    for (final match in pattern.allMatches(attributesStr)) {
      if (match.group(1) case final name?) {
        final value = match.group(2) ?? match.group(3) ?? match.group(4) ?? 'true';
        attributes[name] = value;
      }
    }

    return attributes;
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  int _idCounter = 0;
  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}-${_idCounter++}';
}

/// Represents an extracted child component
class _ExtractedComponent {
  final Map<String, String> attributes;
  final String content;

  _ExtractedComponent({
    required this.attributes,
    required this.content,
  });
}

/// Represents a tree element (file or folder)
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
