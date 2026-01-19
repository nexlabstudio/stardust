import 'package:yaml/yaml.dart';

import '../utils/exceptions.dart';

/// Parsed frontmatter and content from a markdown file
class ParsedDocument {
  final Map<String, dynamic> frontmatter;
  final String content;

  const ParsedDocument({
    required this.frontmatter,
    required this.content,
  });

  String? get title => frontmatter['title'] as String?;
  String? get description => frontmatter['description'] as String?;
  int? get order => frontmatter['order'] as int?;
  String? get icon => frontmatter['icon'] as String?;
  bool get draft => frontmatter['draft'] as bool? ?? false;
  List<String> get tags => (frontmatter['tags'] as List?)?.cast<String>() ?? [];
}

/// Parses YAML frontmatter from markdown content
class FrontmatterParser {
  static const _delimiter = '---';

  /// Parse frontmatter and content from a markdown string
  static ParsedDocument parse(String input) {
    final trimmed = input.trimLeft();

    if (!trimmed.startsWith(_delimiter)) {
      return ParsedDocument(frontmatter: {}, content: input);
    }

    final lines = trimmed.split('\n');
    var endIndex = -1;

    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == _delimiter) {
        endIndex = i;
        break;
      }
    }

    if (endIndex == -1) {
      return ParsedDocument(frontmatter: {}, content: input);
    }

    final frontmatterLines = lines.sublist(1, endIndex);
    final frontmatterYaml = frontmatterLines.join('\n');
    final content = lines.sublist(endIndex + 1).join('\n').trimLeft();

    final Map<String, dynamic> frontmatter;
    try {
      final parsed = loadYaml(frontmatterYaml);
      if (parsed is Map) {
        frontmatter = Map<String, dynamic>.from(parsed);
      } else {
        frontmatter = {};
      }
    } on YamlException catch (e) {
      throw ContentException('Invalid YAML frontmatter', cause: e);
    }

    return ParsedDocument(
      frontmatter: frontmatter,
      content: content,
    );
  }
}
