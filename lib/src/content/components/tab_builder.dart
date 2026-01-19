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

  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}-${_idCounter++}';
}
