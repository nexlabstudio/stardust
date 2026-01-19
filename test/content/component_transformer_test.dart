import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/content/component_transformer.dart';
import 'package:stardust/src/content/components/base_component.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentTransformer', () {
    late ComponentTransformer transformer;

    setUp(() {
      transformer = ComponentTransformer();
    });

    group('callout components', () {
      test('transforms Info component', () {
        const input = '<Info>This is information</Info>';
        final output = transformer.transform(input);
        expect(output, contains('class="callout callout-info"'));
        expect(output, contains('This is information'));
      });

      test('transforms Warning component', () {
        const input = '<Warning>Be careful!</Warning>';
        final output = transformer.transform(input);
        expect(output, contains('class="callout callout-warning"'));
        expect(output, contains('Be careful!'));
      });

      test('transforms Danger component', () {
        const input = '<Danger>Critical error</Danger>';
        final output = transformer.transform(input);
        expect(output, contains('class="callout callout-danger"'));
      });

      test('transforms Tip component', () {
        const input = '<Tip>Pro tip here</Tip>';
        final output = transformer.transform(input);
        expect(output, contains('class="callout callout-tip"'));
      });

      test('transforms Note component', () {
        const input = '<Note>Take note</Note>';
        final output = transformer.transform(input);
        expect(output, contains('class="callout callout-note"'));
      });

      test('transforms callout with title', () {
        const input = '<Info title="Important">Content here</Info>';
        final output = transformer.transform(input);
        expect(output, contains('Important'));
        expect(output, contains('Content here'));
      });
    });

    group('tab components', () {
      test('transforms Tabs with Tab children', () {
        const input = '''<Tabs>
<Tab label="First">Content 1</Tab>
<Tab label="Second">Content 2</Tab>
</Tabs>''';

        final output = transformer.transform(input);
        expect(output, contains('class="tabs"'));
        expect(output, contains('First'));
        expect(output, contains('Second'));
        expect(output, contains('Content 1'));
        expect(output, contains('Content 2'));
      });

      test('transforms CodeGroup', () {
        const input = '''<CodeGroup>
<Code title="JavaScript">const x = 1;</Code>
<Code title="Python">x = 1</Code>
</CodeGroup>''';

        final output = transformer.transform(input);
        expect(output, contains('class="code-group"'));
        expect(output, contains('JavaScript'));
        expect(output, contains('Python'));
      });
    });

    group('accordion components', () {
      test('transforms AccordionGroup with Accordion children', () {
        const input = '''<AccordionGroup>
<Accordion title="Question 1">Answer 1</Accordion>
<Accordion title="Question 2">Answer 2</Accordion>
</AccordionGroup>''';

        final output = transformer.transform(input);
        expect(output, contains('class="accordion-group"'));
        expect(output, contains('Question 1'));
        expect(output, contains('Answer 1'));
      });

      test('transforms standalone Accordion', () {
        const input = '<Accordion title="FAQ">Answer here</Accordion>';
        final output = transformer.transform(input);
        expect(output, contains('details'));
        expect(output, contains('FAQ'));
      });
    });

    group('step components', () {
      test('transforms Steps with Step children', () {
        const input = '''<Steps>
<Step title="First Step">Do this first</Step>
<Step title="Second Step">Then this</Step>
</Steps>''';

        final output = transformer.transform(input);
        expect(output, contains('class="steps"'));
        expect(output, contains('First Step'));
        expect(output, contains('Do this first'));
      });
    });

    group('card components', () {
      test('transforms Cards with Card children', () {
        const input = '''<Cards>
<Card title="Card 1" href="/page1">Description 1</Card>
<Card title="Card 2" href="/page2">Description 2</Card>
</Cards>''';

        final output = transformer.transform(input);
        expect(output, contains('class="cards"'));
        expect(output, contains('Card 1'));
        expect(output, contains('href="/page1"'));
      });

      test('transforms CardGroup', () {
        const input = '''<CardGroup cols={2}>
<Card title="A">Content A</Card>
<Card title="B">Content B</Card>
</CardGroup>''';

        final output = transformer.transform(input);
        expect(output, contains('cards'));
      });
    });

    group('layout components', () {
      test('transforms Columns', () {
        const input = '''<Columns>
<Column>Left content</Column>
<Column>Right content</Column>
</Columns>''';

        final output = transformer.transform(input);
        expect(output, contains('class="columns"'));
        expect(output, contains('Left content'));
        expect(output, contains('Right content'));
      });
    });

    group('embed components', () {
      test('transforms YouTube component with ID', () {
        const input = '<YouTube id="dQw4w9WgXcQ" />';
        final output = transformer.transform(input);
        expect(output, contains('youtube.com/embed/dQw4w9WgXcQ'));
        expect(output, contains('iframe'));
      });

      test('transforms YouTube with URL', () {
        const input = '<YouTube id="https://youtu.be/dQw4w9WgXcQ" />';
        final output = transformer.transform(input);
        expect(output, contains('dQw4w9WgXcQ'));
      });

      test('transforms Vimeo component', () {
        const input = '<Vimeo id="123456789" />';
        final output = transformer.transform(input);
        expect(output, contains('player.vimeo.com/video/123456789'));
      });
    });

    group('media components', () {
      test('transforms Image component', () {
        const input = '<Image src="test.png" alt="Test" />';
        final output = transformer.transform(input);
        expect(output, contains('src="test.png"'));
        expect(output, contains('alt="Test"'));
        expect(output, contains('loading="lazy"'));
      });

      test('transforms Image with caption', () {
        const input = '<Image src="test.png" alt="Test" caption="Figure 1" />';
        final output = transformer.transform(input);
        expect(output, contains('figure'));
        expect(output, contains('figcaption'));
        expect(output, contains('Figure 1'));
      });

      test('transforms Image with zoom', () {
        const input = '<Image src="test.png" alt="Test" zoom />';
        final output = transformer.transform(input);
        expect(output, contains('image-zoomable'));
        expect(output, contains('image-zoom-wrapper'));
      });

      test('transforms Video component', () {
        const input = '<Video src="video.mp4" />';
        final output = transformer.transform(input);
        expect(output, contains('video'));
        expect(output, contains('video.mp4'));
        expect(output, contains('controls'));
      });

      test('transforms Mermaid component', () {
        const input = '''<Mermaid>
graph TD
    A --> B
</Mermaid>''';

        final output = transformer.transform(input);
        expect(output, contains('class="mermaid"'));
        expect(output, contains('graph TD'));
      });
    });

    group('utility components', () {
      test('transforms Tooltip component', () {
        const input = '<Tooltip content="Helpful info">Hover me</Tooltip>';
        final output = transformer.transform(input);
        expect(output, contains('tooltip'));
        expect(output, contains('Helpful info'));
        expect(output, contains('Hover me'));
      });

      test('transforms Badge component', () {
        const input = '<Badge>New</Badge>';
        final output = transformer.transform(input);
        expect(output, contains('badge'));
        expect(output, contains('New'));
      });

      test('transforms Icon component', () {
        const input = '<Icon name="star" />';
        final output = transformer.transform(input);
        expect(output, contains('lucide'));
      });
    });

    group('custom components', () {
      test('allows registering custom component builder', () {
        final customBuilder = _TestComponentBuilder();
        transformer.register(customBuilder);

        const input = '<TestComponent attr="value">Content</TestComponent>';
        final output = transformer.transform(input);
        expect(output, contains('custom-test'));
        expect(output, contains('Content'));
      });
    });

    group('nested components', () {
      test('handles nested same-type components', () {
        const input = '''<Info>
Outer content
<Info>Inner content</Info>
More outer
</Info>''';

        final output = transformer.transform(input);
        expect(output, contains('Outer content'));
        expect(output, contains('Inner content'));
      });
    });

    group('self-closing components', () {
      test('handles self-closing syntax', () {
        const input = '<Image src="test.png" />';
        final output = transformer.transform(input);
        expect(output, contains('test.png'));
      });
    });

    group('preserves non-component content', () {
      test('passes through plain text', () {
        const input = 'Just plain text without components';
        final output = transformer.transform(input);
        expect(output, equals(input));
      });

      test('passes through HTML', () {
        const input = '<div class="custom">HTML content</div>';
        final output = transformer.transform(input);
        expect(output, equals(input));
      });
    });
  });

  group('ComponentTransformer with config', () {
    test('uses custom callout config', () {
      const config = ComponentsConfig(
        callouts: {
          'info': CalloutConfig(icon: '📘', color: '#0000ff'),
        },
      );
      final transformer = ComponentTransformer(config: config);

      const input = '<Info>Test</Info>';
      final output = transformer.transform(input);
      expect(output, contains('📘'));
    });
  });
}

class _TestComponentBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['TestComponent'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) =>
      '<div class="custom-test">$content</div>';
}
