/// A component tag occurrence found by [findFirstComponent].
class ComponentMatch {
  final String name;
  final int start;
  final int end;
  final String attributes;

  /// Raw inner source for open/close pairs; null for self-closing tags.
  final String? inner;

  const ComponentMatch({
    required this.name,
    required this.start,
    required this.end,
    required this.attributes,
    this.inner,
  });

  bool get selfClosing => inner == null;
}

/// Finds the earliest well-formed component tag: word-boundary name matching,
/// balanced same-name nesting, quote-aware attributes. Malformed occurrences
/// fall through as literal text.
ComponentMatch? findFirstComponent(String text, Set<String> names, [int from = 0]) {
  var pos = from;
  while (true) {
    final lt = text.indexOf('<', pos);
    if (lt == -1) return null;

    if (_matchName(text, lt + 1, names) case final name?) {
      if (_parseTag(text, lt, name) case final match?) return match;
    }
    pos = lt + 1;
  }
}

String? _matchName(String text, int at, Set<String> names) {
  for (final name in names) {
    if (text.startsWith(name, at) && _isBoundary(text, at + name.length)) {
      return name;
    }
  }
  return null;
}

bool _isBoundary(String text, int at) {
  if (at >= text.length) return false;
  return switch (text[at]) { ' ' || '\t' || '\n' || '\r' || '>' || '/' => true, _ => false };
}

ComponentMatch? _parseTag(String text, int lt, String name) {
  final tagEnd = _findTagEnd(text, lt + 1 + name.length);
  if (tagEnd == -1) return null;

  final rawAttributes = text.substring(lt + 1 + name.length, tagEnd);
  if (rawAttributes.trimRight().endsWith('/')) {
    final trimmed = rawAttributes.trimRight();
    return ComponentMatch(
      name: name,
      start: lt,
      end: tagEnd + 1,
      attributes: trimmed.substring(0, trimmed.length - 1),
    );
  }

  final closeTag = '</$name>';
  var depth = 1;
  var pos = tagEnd + 1;

  while (depth > 0) {
    final nextClose = text.indexOf(closeTag, pos);
    if (nextClose == -1) return null;

    if (_nextOpenTag(text, pos, nextClose, name) case (_, final openEnd)?) {
      depth++;
      pos = openEnd;
      continue;
    }

    depth--;
    if (depth == 0) {
      return ComponentMatch(
        name: name,
        start: lt,
        end: nextClose + closeTag.length,
        attributes: rawAttributes,
        inner: text.substring(tagEnd + 1, nextClose),
      );
    }
    pos = nextClose + closeTag.length;
  }
  return null;
}

/// The next same-name, non-self-closing open tag before [limit], or null.
(int, int)? _nextOpenTag(String text, int from, int limit, String name) {
  var pos = from;
  final needle = '<$name';
  while (true) {
    final start = text.indexOf(needle, pos);
    if (start == -1 || start >= limit) return null;
    if (_isBoundary(text, start + needle.length)) {
      final tagEnd = _findTagEnd(text, start + needle.length);
      if (tagEnd != -1) {
        final attrs = text.substring(start + needle.length, tagEnd);
        if (!attrs.trimRight().endsWith('/')) return (start, tagEnd + 1);
        pos = tagEnd + 1;
        continue;
      }
    }
    pos = start + 1;
  }
}

/// Index of the `>` ending the tag, skipping `>` inside quoted values; -1 if unclosed.
int _findTagEnd(String text, int from) {
  String? quote;
  for (var i = from; i < text.length; i++) {
    final char = text[i];
    if (quote != null) {
      if (char == quote) quote = null;
      continue;
    }
    switch (char) {
      case '"' || "'":
        quote = char;
      case '>':
        return i;
      case '<':
        return -1;
    }
  }
  return -1;
}
