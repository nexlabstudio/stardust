/// Parse HTML-style attributes: attr="value" attr='value' attr={value}
Map<String, String> parseAttributes(String attributesStr) {
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

/// Represents an extracted child component
class ExtractedComponent {
  final Map<String, String> attributes;
  final String content;

  ExtractedComponent({
    required this.attributes,
    required this.content,
  });
}

/// Extract child components from content
List<ExtractedComponent> extractChildComponents(String content, String componentName) {
  final components = <ExtractedComponent>[];

  // Pattern for open/close tags
  final pattern = RegExp(
    '<$componentName([^>]*)>([\\s\\S]*?)</$componentName>',
    caseSensitive: false,
    dotAll: true,
  );

  for (final match in pattern.allMatches(content)) {
    final attributesStr = match.group(1) ?? '';
    final innerContent = match.group(2) ?? '';
    components.add(ExtractedComponent(
      attributes: parseAttributes(attributesStr),
      content: innerContent.trim(),
    ));
  }

  return components;
}
