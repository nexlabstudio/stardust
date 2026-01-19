import '../../utils/patterns.dart';
import '../utils/attribute_parser.dart';

/// Base interface for all JSX-style component builders
abstract class ComponentBuilder {
  /// Tag names this builder handles (e.g., ['Info', 'Warning', 'Tip'])
  List<String> get tagNames;

  /// Whether this component supports self-closing syntax (`<Component />`)
  bool get allowSelfClosing => true;

  /// Build the HTML output for a component
  String build(String tagName, Map<String, String> attributes, String content);

  /// Transform all instances of this component's tags in content
  String transformAll(String content, String Function(String) parseAttributes) {
    var result = content;

    for (final tagName in tagNames) {
      result = _transformTag(result, tagName);
    }

    return result;
  }

  String _transformTag(String content, String tagName) {
    var result = content;

    // Handle self-closing: <Component />
    if (allowSelfClosing) {
      result = result.replaceAllMapped(selfClosingComponentPattern(tagName), (match) {
        final attrs = parseAttributes(match.group(1) ?? '');
        return build(tagName, attrs, '');
      });
    }

    // Handle open/close: <Component>...</Component>
    final pattern = openCloseComponentPattern(tagName);

    // May need multiple passes for nested same-type components
    var previousResult = '';
    while (previousResult != result) {
      previousResult = result;
      result = result.replaceAllMapped(pattern, (match) {
        final attrs = parseAttributes(match.group(1) ?? '');
        final innerContent = match.group(2) ?? '';
        return build(tagName, attrs, innerContent.trim());
      });
    }

    return result;
  }
}
