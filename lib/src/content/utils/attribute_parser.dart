import '../../utils/patterns.dart';

/// Parse HTML-style attributes: attr="value" attr='value' attr={value}
Map<String, String> parseAttributes(String attributesStr) {
  final attributes = <String, String>{};

  for (final match in attributePattern.allMatches(attributesStr)) {
    if (match.group(1) case final name?) {
      final value = match.group(2) ?? match.group(3) ?? match.group(4) ?? 'true';
      attributes[name] = value;
    }
  }

  return attributes;
}

/// Represents an extracted child component
class ExtractedComponent {
  final Map<String, String> attributes;
  final String content;

  ExtractedComponent({
    required this.attributes,
    required this.content,
  });
}

/// Extracts child components using balanced tag matching.
List<ExtractedComponent> extractChildComponents(String content, String componentName) {
  final components = <ExtractedComponent>[];

  for (final match in findBalancedTags(content, componentName)) {
    components.add(ExtractedComponent(
      attributes: parseAttributes(match.attributes),
      content: match.content.trim(),
    ));
  }

  return components;
}

/// Represents a matched balanced tag
class BalancedTagMatch {
  final int start;
  final int end;
  final String attributes;
  final String content;

  BalancedTagMatch({
    required this.start,
    required this.end,
    required this.attributes,
    required this.content,
  });
}

/// Finds balanced tags using nesting level tracking.
/// Returns only top-level matches; nested same-type tags are included in content.
List<BalancedTagMatch> findBalancedTags(String content, String tagName) {
  final results = <BalancedTagMatch>[];
  final openTagPattern = RegExp('<$tagName([^>]*)>', caseSensitive: false);
  final closeTagLower = '</${tagName.toLowerCase()}>';

  var searchStart = 0;
  while (searchStart < content.length) {
    final openMatch = openTagPattern.firstMatch(content.substring(searchStart));
    if (openMatch == null) break;

    final absoluteStart = searchStart + openMatch.start;
    final attributes = openMatch.group(1) ?? '';
    final contentStart = searchStart + openMatch.end;

    var nestLevel = 1;
    var pos = contentStart;
    var matchEnd = -1;

    while (pos < content.length && nestLevel > 0) {
      final remaining = content.substring(pos);

      if (remaining.toLowerCase().startsWith(closeTagLower)) {
        nestLevel--;
        if (nestLevel == 0) {
          final innerContent = content.substring(contentStart, pos);
          matchEnd = pos + closeTagLower.length;
          results.add(BalancedTagMatch(
            start: absoluteStart,
            end: matchEnd,
            attributes: attributes,
            content: innerContent,
          ));
        }
        pos += closeTagLower.length;
        continue;
      }

      final nestedOpen = openTagPattern.firstMatch(remaining);
      if (nestedOpen != null && nestedOpen.start == 0) {
        nestLevel++;
        pos += nestedOpen.end;
        continue;
      }

      pos++;
    }

    searchStart = matchEnd > 0 ? matchEnd : contentStart;
  }

  return results;
}
