import '../../utils/html_utils.dart';
import '../utils/icon_utils.dart';
import 'base_component.dart';

/// Builds utility components: Badge, Icon, Tooltip, Update
class UtilityBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Badge', 'Icon', 'Tooltip', 'Update'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'Badge' => _buildBadge(attributes, content),
        'Icon' => _buildIcon(attributes, content),
        'Tooltip' => _buildTooltip(attributes, content),
        'Update' => _buildUpdate(attributes, content),
        _ => content
      };

  String _buildBadge(Map<String, String> attributes, String content) {
    final variant = attributes['variant'] ?? 'default';
    final size = attributes['size'] ?? 'md';
    final icon = attributes['icon'];

    String iconHtml = '';
    if (icon != null) {
      if (isEmoji(icon)) {
        iconHtml = '<span class="badge-icon">$icon</span>';
      } else {
        iconHtml = '<span class="badge-icon">${getLucideIcon(icon, '14')}</span>';
      }
    }

    return '<span class="badge badge-$variant badge-$size">$iconHtml$content</span>';
  }

  String _buildIcon(Map<String, String> attributes, String content) {
    final name = attributes['name'] ?? content.trim();
    final size = attributes['size'] ?? '20';
    final color = attributes['color'];

    final styleAttr = color != null ? ' style="color: $color;"' : '';

    if (isEmoji(name)) {
      return '<span class="icon icon-emoji" style="font-size: ${size}px;"$styleAttr>$name</span>';
    }

    final svg = getLucideIcon(name, size);
    return '<span class="icon icon-svg"$styleAttr>$svg</span>';
  }

  String _buildTooltip(Map<String, String> attributes, String content) {
    final tip = attributes['content'] ?? attributes['tip'] ?? '';
    final position = attributes['position'] ?? 'top';

    final escapedTip = encodeHtml(tip);

    return '''<span class="tooltip tooltip-$position" data-tooltip="$escapedTip">$content</span>''';
  }

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
}
