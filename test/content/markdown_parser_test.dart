import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/content/markdown_parser.dart';
import 'package:stardust/src/core/interfaces.dart';
import 'package:test/test.dart';

const _defaultConfig = StardustConfig(name: 'Test');

void main() {
  group('MarkdownParser', () {
    late MarkdownParser parser;

    setUp(() {
      parser = MarkdownParser(config: _defaultConfig);
    });

    group('parse', () {
      test('parses simple markdown', () {
        const content = 'Hello **world**';
        final result = parser.parse(content);
        expect(result.html, contains('<strong>world</strong>'));
      });

      test('parses headings with IDs', () {
        const content = '# Hello World';
        final result = parser.parse(content);
        expect(result.html, contains('id="hello-world"'));
        expect(result.html, contains('Hello World'));
      });

      test('parses multiple heading levels', () {
        const content = '''
# Heading 1
## Heading 2
### Heading 3
''';
        final result = parser.parse(content);
        expect(result.html, contains('<h1'));
        expect(result.html, contains('<h2'));
        expect(result.html, contains('<h3'));
      });

      test('parses code blocks with language', () {
        const content = '''
```dart
void main() {
  print('hello');
}
```
''';
        final result = parser.parse(content);
        expect(result.html, contains('language-dart'));
        expect(result.html, contains('code-block'));
      });

      test('parses inline code', () {
        const content = 'Use `print()` to output';
        final result = parser.parse(content);
        expect(result.html, contains('<code>print()</code>'));
      });

      test('parses links', () {
        const content = '[Google](https://google.com)';
        final result = parser.parse(content);
        expect(result.html, contains('href="https://google.com"'));
        expect(result.html, contains('Google'));
      });

      test('parses lists', () {
        const content = '''
- Item 1
- Item 2
- Item 3
''';
        final result = parser.parse(content);
        expect(result.html, contains('<ul>'));
        expect(result.html, contains('<li>'));
      });

      test('parses ordered lists', () {
        const content = '''
1. First
2. Second
3. Third
''';
        final result = parser.parse(content);
        expect(result.html, contains('<ol>'));
        expect(result.html, contains('<li>'));
      });

      test('parses blockquotes', () {
        const content = '> This is a quote';
        final result = parser.parse(content);
        expect(result.html, contains('<blockquote>'));
      });

      test('parses tables', () {
        const content = '''
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
''';
        final result = parser.parse(content);
        expect(result.html, contains('<table>'));
        expect(result.html, contains('<th>'));
        expect(result.html, contains('<td>'));
      });

      test('parses strikethrough', () {
        const content = '~~deleted~~';
        final result = parser.parse(content);
        expect(result.html, contains('<del>'));
      });
    });

    group('frontmatter handling', () {
      test('extracts title from frontmatter', () {
        const content = '''
---
title: My Page Title
---

Content here
''';
        final result = parser.parse(content);
        expect(result.title, equals('My Page Title'));
      });

      test('extracts description from frontmatter', () {
        const content = '''
---
title: Test
description: A test page description
---

Content
''';
        final result = parser.parse(content);
        expect(result.description, equals('A test page description'));
      });

      test('uses defaultTitle when no frontmatter title', () {
        const content = 'Just content without frontmatter';
        final result = parser.parse(content, defaultTitle: 'Default Title');
        expect(result.title, equals('Default Title'));
      });

      test('uses Untitled when no title provided', () {
        const content = 'Just content';
        final result = parser.parse(content);
        expect(result.title, equals('Untitled'));
      });

      test('frontmatter title takes precedence over defaultTitle', () {
        const content = '''
---
title: Frontmatter Title
---

Content
''';
        final result = parser.parse(content, defaultTitle: 'Default Title');
        expect(result.title, equals('Frontmatter Title'));
      });

      test('preserves all frontmatter fields', () {
        const content = '''
---
title: Test
custom_field: custom_value
number_field: 42
---

Content
''';
        final result = parser.parse(content);
        expect(result.frontmatter['title'], equals('Test'));
        expect(result.frontmatter['custom_field'], equals('custom_value'));
        expect(result.frontmatter['number_field'], equals(42));
      });
    });

    group('table of contents', () {
      test('extracts TOC from headings', () {
        const content = '''
## Introduction

Some content

## Getting Started

More content

### Installation

Install instructions
''';
        final result = parser.parse(content);
        expect(result.toc.length, equals(3));
        expect(result.toc[0].text, equals('Introduction'));
        expect(result.toc[0].level, equals(2));
        expect(result.toc[1].text, equals('Getting Started'));
        expect(result.toc[2].text, equals('Installation'));
        expect(result.toc[2].level, equals(3));
      });

      test('extracts heading IDs', () {
        const content = '## Hello World';
        final result = parser.parse(content);
        expect(result.toc.length, equals(1));
        expect(result.toc[0].id, equals('hello-world'));
      });

      test('respects minDepth config', () {
        const customConfig = StardustConfig(
          name: 'Test',
          toc: TocConfig(minDepth: 3, maxDepth: 4),
        );
        final customParser = MarkdownParser(config: customConfig);
        const content = '''
## H2 heading
### H3 heading
#### H4 heading
##### H5 heading
''';
        final result = customParser.parse(content);
        expect(result.toc.length, equals(2));
        expect(result.toc.every((e) => e.level >= 3), isTrue);
      });

      test('respects maxDepth config', () {
        const customConfig = StardustConfig(
          name: 'Test',
          toc: TocConfig(minDepth: 2, maxDepth: 3),
        );
        final customParser = MarkdownParser(config: customConfig);
        const content = '''
## H2 heading
### H3 heading
#### H4 heading
''';
        final result = customParser.parse(content);
        expect(result.toc.length, equals(2));
        expect(result.toc.every((e) => e.level <= 3), isTrue);
      });

      test('returns empty TOC when no headings', () {
        const content = 'Just paragraphs without headings';
        final result = parser.parse(content);
        expect(result.toc, isEmpty);
      });

      test('strips HTML from TOC text', () {
        const content = '## Heading with **bold** text';
        final result = parser.parse(content);
        expect(result.toc.length, equals(1));
        expect(result.toc[0].text, equals('Heading with bold text'));
      });
    });

    group('syntax highlighting', () {
      test('adds code header with language', () {
        const content = '''
```javascript
const x = 1;
```
''';
        final result = parser.parse(content);
        expect(result.html, contains('code-header'));
        expect(result.html, contains('code-language'));
        expect(result.html, contains('javascript'));
      });

      test('applies hljs classes', () {
        const content = '''
```javascript
const x = 1;
```
''';
        final result = parser.parse(content);
        expect(result.html, contains('hljs'));
      });

      test('includes copy button by default', () {
        const content = '''
```dart
print('hello');
```
''';
        final result = parser.parse(content);
        expect(result.html, contains('copy-button'));
      });

      test('excludes copy button when disabled', () {
        const customConfig = StardustConfig(
          name: 'Test',
          code: CodeConfig(copyButton: false),
        );
        final customParser = MarkdownParser(config: customConfig);
        const content = '''
```dart
print('hello');
```
''';
        final result = customParser.parse(content);
        expect(result.html, isNot(contains('copy-button')));
      });

      test('includes line numbers when enabled', () {
        const customConfig = StardustConfig(
          name: 'Test',
          code: CodeConfig(lineNumbers: true),
        );
        final customParser = MarkdownParser(config: customConfig);
        const content = '''
```dart
line1
line2
line3
```
''';
        final result = customParser.parse(content);
        expect(result.html, contains('line-numbers'));
        expect(result.html, contains('line-number'));
      });

      test('handles code blocks without language', () {
        const content = '''
```
plain code
```
''';
        final result = parser.parse(content);
        // Code blocks without language don't get syntax highlighting wrapper
        expect(result.html, contains('<pre><code>'));
        expect(result.html, contains('plain code'));
      });
    });

    group('component transformation', () {
      test('transforms Info callout', () {
        const content = '<Info>Important information</Info>';
        final result = parser.parse(content);
        expect(result.html, contains('callout'));
        expect(result.html, contains('Important information'));
      });

      test('transforms Warning callout', () {
        const content = '<Warning>Be careful</Warning>';
        final result = parser.parse(content);
        expect(result.html, contains('callout'));
        expect(result.html, contains('warning'));
      });
    });

    group('custom transformer', () {
      test('accepts custom ContentTransformer', () {
        final customTransformer = _MockTransformer();
        final customParser = MarkdownParser(
          config: _defaultConfig,
          componentTransformer: customTransformer,
        );
        const content = 'Test content';
        customParser.parse(content);
        expect(customTransformer.transformCalled, isTrue);
      });
    });

    group('edge cases', () {
      test('handles empty content', () {
        const content = '';
        final result = parser.parse(content);
        // Markdown parser may add trailing newline
        expect(result.html.trim(), isEmpty);
        expect(result.title, equals('Untitled'));
      });

      test('handles content with only whitespace', () {
        const content = '   \n\n  ';
        final result = parser.parse(content);
        expect(result.title, equals('Untitled'));
      });

      test('handles special characters in headings', () {
        const content = '## C++ Programming & Design';
        final result = parser.parse(content);
        expect(result.html, contains('C++ Programming &amp; Design'));
      });

      test('handles mixed content', () {
        const content = '''
---
title: Test Page
---

# Main Title

Some **bold** and _italic_ text.

<Info>A callout</Info>

```dart
void main() {}
```

## Another Section

- List item
- Another item
''';
        final result = parser.parse(content);
        expect(result.title, equals('Test Page'));
        expect(result.html, contains('<strong>'));
        expect(result.html, contains('<em>'));
        expect(result.html, contains('callout'));
        expect(result.html, contains('code-block'));
        expect(result.html, contains('<ul>'));
        expect(result.toc.isNotEmpty, isTrue);
      });
    });
  });

  group('ParsedPage', () {
    test('stores all properties correctly', () {
      const toc = [TocEntry(level: 2, text: 'Test', id: 'test')];
      const frontmatter = {'key': 'value'};

      const page = ParsedPage(
        title: 'Test Title',
        description: 'Test Description',
        html: '<p>Content</p>',
        toc: toc,
        frontmatter: frontmatter,
      );

      expect(page.title, equals('Test Title'));
      expect(page.description, equals('Test Description'));
      expect(page.html, equals('<p>Content</p>'));
      expect(page.toc, equals(toc));
      expect(page.frontmatter, equals(frontmatter));
    });

    test('allows null description', () {
      const page = ParsedPage(
        title: 'Test',
        html: '<p>Content</p>',
        toc: [],
        frontmatter: {},
      );

      expect(page.description, isNull);
    });
  });

  group('TocEntry', () {
    test('stores properties correctly', () {
      const entry = TocEntry(level: 2, text: 'Introduction', id: 'introduction');

      expect(entry.level, equals(2));
      expect(entry.text, equals('Introduction'));
      expect(entry.id, equals('introduction'));
    });
  });
}

class _MockTransformer implements ContentTransformer {
  bool transformCalled = false;

  @override
  String transform(String content) {
    transformCalled = true;
    return content;
  }
}
