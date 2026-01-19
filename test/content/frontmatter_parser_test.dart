import 'package:stardust/src/content/frontmatter_parser.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('FrontmatterParser', () {
    test('parses valid frontmatter', () {
      const input = '''---
title: Hello World
description: A test page
---
# Content here''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.title, equals('Hello World'));
      expect(doc.description, equals('A test page'));
      expect(doc.content, equals('# Content here'));
    });

    test('returns empty frontmatter when no delimiters', () {
      const input = '# Just content\n\nNo frontmatter here.';
      final doc = FrontmatterParser.parse(input);
      expect(doc.frontmatter, isEmpty);
      expect(doc.content, equals(input));
    });

    test('returns empty frontmatter when only opening delimiter', () {
      const input = '''---
title: Incomplete
No closing delimiter''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.frontmatter, isEmpty);
      expect(doc.content, equals(input));
    });

    test('handles empty frontmatter block', () {
      const input = '''---
---
Content after empty frontmatter''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.frontmatter, isEmpty);
      expect(doc.content, equals('Content after empty frontmatter'));
    });

    test('parses all frontmatter fields', () {
      const input = '''---
title: Test Page
description: Description here
order: 5
icon: 📚
draft: true
tags:
  - dart
  - documentation
---
Content''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.title, equals('Test Page'));
      expect(doc.description, equals('Description here'));
      expect(doc.order, equals(5));
      expect(doc.icon, equals('📚'));
      expect(doc.draft, isTrue);
      expect(doc.tags, equals(['dart', 'documentation']));
    });

    test('draft defaults to false', () {
      const input = '''---
title: Not Draft
---
Content''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.draft, isFalse);
    });

    test('tags defaults to empty list', () {
      const input = '''---
title: No Tags
---
Content''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.tags, isEmpty);
    });

    test('handles leading whitespace before frontmatter', () {
      const input = '''   ---
title: With Whitespace
---
Content''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.title, equals('With Whitespace'));
    });

    test('trims leading whitespace from content', () {
      const input = '''---
title: Test
---

   Content with leading space''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.content, startsWith('Content'));
    });

    test('throws ContentException for invalid YAML', () {
      const input = '''---
title: [invalid yaml
  - missing bracket
---
Content''';

      expect(
        () => FrontmatterParser.parse(input),
        throwsA(isA<ContentException>()),
      );
    });

    test('handles non-map YAML as empty frontmatter', () {
      const input = '''---
- just
- a
- list
---
Content''';

      final doc = FrontmatterParser.parse(input);
      expect(doc.frontmatter, isEmpty);
      expect(doc.content, equals('Content'));
    });
  });

  group('ParsedDocument', () {
    test('accessors return null for missing keys', () {
      const doc = ParsedDocument(frontmatter: {}, content: 'test');
      expect(doc.title, isNull);
      expect(doc.description, isNull);
      expect(doc.order, isNull);
      expect(doc.icon, isNull);
    });
  });
}
