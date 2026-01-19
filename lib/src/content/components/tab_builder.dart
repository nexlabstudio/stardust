import 'package:markdown/markdown.dart' as md;

import '../utils/attribute_parser.dart';
import 'base_component.dart';

/// Builds tab components: Tabs, Tab, CodeGroup, Code
class TabBuilder extends ComponentBuilder {
  int _idCounter = 0;

  @override
  List<String> get tagNames => ['Tabs', 'CodeGroup'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'Tabs' => _buildTabs(attributes, content),
        'CodeGroup' => _buildCodeGroup(attributes, content),
        _ => content
      };

  String _buildTabs(Map<String, String> attributes, String content) {
    final tabs = extractChildComponents(content, 'Tab');

    if (tabs.isEmpty) {
      return '<div class="tabs-empty">No tabs defined</div>';
    }

    final tabsId = 'tabs-${_generateId()}';
    final tabButtons = StringBuffer();
    final tabPanels = StringBuffer();

    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final name = tab.attributes['label'] ?? tab.attributes['name'] ?? 'Tab ${i + 1}';
      final isActive = i == 0;
      final tabId = '$tabsId-$i';

      tabButtons.writeln('''
    <button class="tab-button${isActive ? ' active' : ''}"
            data-tab="$tabId"
            role="tab"
            aria-selected="${isActive ? 'true' : 'false'}">
      $name
    </button>''');

      final hiddenAttr = isActive ? '' : ' hidden';
      final processedContent = _processMarkdown(tab.content);
      tabPanels.writeln('''
    <div class="tab-panel${isActive ? ' active' : ''}" id="$tabId" role="tabpanel"$hiddenAttr>
$processedContent
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

  String _buildCodeGroup(Map<String, String> attributes, String content) {
    final codeBlocks = extractChildComponents(content, 'Code');

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

      var codeContent = block.content.trim();
      if (!codeContent.startsWith('```')) {
        codeContent = '```$language\n$codeContent\n```';
      }
      final processedContent = _processMarkdown(codeContent);

      tabPanels.writeln('''
    <div class="tab-panel${isActive ? ' active' : ''}"
         id="$tabId"
         role="tabpanel"${isActive ? '' : ' hidden'}>

$processedContent

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

  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}-${_idCounter++}';

  String _processMarkdown(String content) {
    final dedented = _dedent(content).trim();
    return md.markdownToHtml(
      dedented,
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
}
