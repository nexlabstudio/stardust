import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/content/markdown_parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = MarkdownParser(config: const StardustConfig(name: 'Test'));

  String parse(String markdown) => parser.parse(markdown).html;

  group('pipeline invariants (must hold before and after rewrite)', () {
    test('renders a callout with markdown inside', () {
      final html = parse('<Info>\nSome **bold** text\n</Info>');

      expect(html, contains('callout callout-info'));
      expect(html, contains('<strong>bold</strong>'));
    });

    test('renders tabs with markdown panels', () {
      final html = parse('''
<Tabs>
<Tab label="First">
Hello **world**
</Tab>
<Tab label="Second">
Second panel
</Tab>
</Tabs>
''');

      expect(html, contains('tab-button'));
      expect(html, contains('<strong>world</strong>'));
      expect(html, contains('Second panel'));
    });

    test('renders a fenced code block with highlighting wrapper', () {
      final html = parse('```dart\nfinal x = 1;\n```');

      expect(html, contains('code-block'));
      expect(html, contains('language-dart'));
    });

    test('component tags inside a plain fence stay literal', () {
      final html = parse('```\n<Info>not a component</Info>\n```');

      expect(html, isNot(contains('callout')));
      expect(html, contains('&lt;Info&gt;'));
    });

    test('code fence inside a tab renders as a code block', () {
      final html = parse('''
<Tabs>
<Tab label="Code">
```dart
final x = 1;
```
</Tab>
</Tabs>
''');

      expect(html, contains('code-block'));
      expect(html, contains('hljs-keyword'));
      expect(html, contains('language-dart'));
    });

    test('nested different components render inside a callout', () {
      final html = parse('<Info>\n<Badge variant="new">New</Badge> feature\n</Info>');

      expect(html, contains('callout callout-info'));
      expect(html, contains('badge badge-new'));
    });

    test('self-closing component renders', () {
      final html = parse('<YouTube id="dQw4w9WgXcQ" />');

      expect(html, contains('embed-youtube'));
    });

    test('headings produce toc entries and ids', () {
      final page = parser.parse('## First Section\n\ntext\n\n### Sub Section\n');

      expect(page.toc, hasLength(2));
      expect(page.toc.first.text, equals('First Section'));
    });
  });

  group('bugs fixed by the rewrite', () {
    test('same-type nesting: panel inside panel', () {
      final html = parse('''
<Panel title="Outer">
<Panel title="Inner">
inner content
</Panel>
</Panel>
''');

      expect(html, contains('Outer'));
      expect(html, contains('Inner'));
      expect(html, contains('inner content'));
      expect(html, isNot(contains('</Panel>')));
      expect('panel-content'.allMatches(html).length, equals(2));
    });

    test('tag prefix collision: AccordionGroup is not eaten by Accordion', () {
      final html = parse('''
<AccordionGroup>
<Accordion title="One">first</Accordion>
<Accordion title="Two">second</Accordion>
</AccordionGroup>
''');

      expect(html, contains('accordion-group'));
      expect(html, contains('One'));
      expect(html, contains('second'));
      expect(html, isNot(contains('AccordionGroup')));
    });

    test('fence with an info string still protects components inside', () {
      final html = parse('```md title="example"\n<Info>docs sample</Info>\n```');

      expect(html, isNot(contains('callout')));
    });

    test('fence inside a component containing a closing tag does not truncate it', () {
      final html = parse('''
<Info>
Example of tab syntax:

```md
</Tab>
```

after the fence
</Info>
''');

      expect(html, contains('callout callout-info'));
      expect(html, contains('after the fence'));
    });

    test('inline code with component syntax stays literal', () {
      final html = parse('Use `<Info>` to add a callout.');

      expect(html, isNot(contains('callout callout-info')));
      expect(html, contains('&lt;Info&gt;'));
    });

    test('literal placeholder-looking text is not corrupted', () {
      final html = parse('The magic token ___CODE_0___ is plain text.\n\n```\nreal code\n```');

      expect(html, contains('CODE_0'));
      expect(html, contains('real code'));
    });
  });
}
