import '../../utils/html_utils.dart';
import 'base_component.dart';

/// Builds a call-to-action button: `<Button href variant external>Label</Button>`.
/// The href is base-path-prefixed downstream like other content links.
class ButtonBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Button'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) {
    final href = sanitizeUrl(attributes['href'] ?? '');
    final variant = attributes['variant'] == 'primary' ? 'primary' : 'secondary';
    final external = attributes['external'] == 'true';
    final externalAttrs = external ? ' target="_blank" rel="noopener"' : '';
    final label = content.replaceAll(RegExp(r'</?p>'), '').trim();

    return '<a href="${encodeHtmlAttribute(href)}" class="button button--$variant"$externalAttrs>$label</a>';
  }
}
