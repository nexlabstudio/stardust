import '../utils/attribute_parser.dart';
import '../utils/icon_utils.dart';
import 'base_component.dart';

/// Builds layout components: Columns, Column, Panel, Frame
class LayoutBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Columns', 'Panel', 'Frame'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'Columns' => _buildColumns(attributes, content),
        'Panel' => _buildPanel(attributes, content),
        'Frame' => _buildFrame(attributes, content),
        _ => content
      };

  String _buildColumns(Map<String, String> attributes, String content) {
    final columns = extractChildComponents(content, 'Column');
    final gap = attributes['gap'] ?? '1rem';

    if (columns.isEmpty) {
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

  String _buildPanel(Map<String, String> attributes, String content) {
    final title = attributes['title'];
    final icon = attributes['icon'];
    final variant = attributes['variant'] ?? 'default';

    String iconHtml = '';
    switch (icon) {
      case _?:
        iconHtml = isEmoji(icon)
            ? '<span class="panel-icon">$icon</span>'
            : '<span class="panel-icon">${getLucideIcon(icon, '20')}</span>';
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
}
