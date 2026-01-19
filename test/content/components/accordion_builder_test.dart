import 'package:stardust/src/content/components/accordion_builder.dart';
import 'package:test/test.dart';

void main() {
  group('AccordionBuilder', () {
    late AccordionBuilder builder;

    setUp(() {
      builder = AccordionBuilder();
    });

    test('tagNames includes accordion components', () {
      expect(builder.tagNames, containsAll(['AccordionGroup', 'Accordion']));
    });

    group('AccordionGroup component', () {
      test('builds group with child accordions', () {
        const content = '''
<Accordion title="First">Content 1</Accordion>
<Accordion title="Second">Content 2</Accordion>
''';
        final result = builder.build('AccordionGroup', {}, content);

        expect(result, contains('class="accordion-group"'));
        expect(result, contains('First'));
        expect(result, contains('Second'));
        expect(result, contains('Content 1'));
        expect(result, contains('Content 2'));
      });

      test('builds empty group when no accordions', () {
        final result = builder.build('AccordionGroup', {}, '');

        expect(result, contains('class="accordion-group"'));
      });
    });

    group('Accordion component', () {
      test('builds basic accordion', () {
        final result = builder.build('Accordion', {'title': 'Question'}, 'Answer here');

        expect(result, contains('<details class="accordion">'));
        expect(result, contains('accordion-summary'));
        expect(result, contains('Question'));
        expect(result, contains('accordion-content'));
        expect(result, contains('Answer here'));
      });

      test('uses default title when not provided', () {
        final result = builder.build('Accordion', {}, 'Content');

        expect(result, contains('Details'));
      });

      test('opens when defaultOpen is true', () {
        final result = builder.build('Accordion', {'defaultOpen': 'true'}, 'Content');

        expect(result, contains('<details class="accordion" open>'));
      });

      test('opens when open is true', () {
        final result = builder.build('Accordion', {'open': 'true'}, 'Content');

        expect(result, contains('<details class="accordion" open>'));
      });

      test('closed by default', () {
        final result = builder.build('Accordion', {'title': 'Test'}, 'Content');

        expect(result, contains('<details class="accordion">'));
        expect(result, isNot(contains('open>')));
      });

      test('adds emoji icon', () {
        final result = builder.build('Accordion', {'title': 'FAQ', 'icon': '❓'}, 'Content');

        expect(result, contains('accordion-icon'));
        expect(result, contains('❓'));
      });

      test('adds lucide icon', () {
        final result = builder.build('Accordion', {'title': 'Help', 'icon': 'help-circle'}, 'Content');

        expect(result, contains('accordion-icon'));
        expect(result, contains('data-lucide'));
      });

      test('no icon when icon attribute is empty', () {
        final result = builder.build('Accordion', {'title': 'Test', 'icon': ''}, 'Content');

        expect(result, isNot(contains('accordion-icon')));
      });
    });

    test('unknown tag returns content unchanged', () {
      final result = builder.build('Unknown', {}, 'content');

      expect(result, equals('content'));
    });
  });
}
