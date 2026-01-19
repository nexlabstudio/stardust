import '../utils/attribute_parser.dart';
import '../utils/icon_utils.dart';
import 'base_component.dart';

/// Builds accordion components: Accordion, AccordionGroup
class AccordionBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['AccordionGroup', 'Accordion'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'AccordionGroup' => _buildAccordionGroup(attributes, content),
        'Accordion' => _buildAccordion(attributes, content),
        _ => content
      };

  String _buildAccordionGroup(Map<String, String> attributes, String content) {
    final accordions = extractChildComponents(content, 'Accordion');

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
      if (isEmoji(icon)) {
        iconHtml = '<span class="accordion-icon">$icon</span> ';
      } else {
        final svg = getLucideIcon(icon, '18');
        iconHtml = '<span class="accordion-icon">$svg</span> ';
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
}
