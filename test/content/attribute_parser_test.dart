import 'package:stardust/src/content/utils/attribute_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseAttributes', () {
    test('parses double-quoted attributes', () {
      final attrs = parseAttributes('src="image.png" alt="My Image"');
      expect(attrs['src'], equals('image.png'));
      expect(attrs['alt'], equals('My Image'));
    });

    test('parses single-quoted attributes', () {
      final attrs = parseAttributes("src='image.png' alt='My Image'");
      expect(attrs['src'], equals('image.png'));
      expect(attrs['alt'], equals('My Image'));
    });

    test('parses curly-brace attributes', () {
      final attrs = parseAttributes('count={42} enabled={true}');
      expect(attrs['count'], equals('42'));
      expect(attrs['enabled'], equals('true'));
    });

    test('parses boolean attributes', () {
      final attrs = parseAttributes('disabled readonly');
      expect(attrs['disabled'], equals('true'));
      expect(attrs['readonly'], equals('true'));
    });

    test('parses mixed attribute styles', () {
      final attrs = parseAttributes('src="test.png" zoom count={5}');
      expect(attrs['src'], equals('test.png'));
      expect(attrs['zoom'], equals('true'));
      expect(attrs['count'], equals('5'));
    });

    test('returns empty map for empty string', () {
      final attrs = parseAttributes('');
      expect(attrs, isEmpty);
    });

    test('returns empty map for whitespace only', () {
      final attrs = parseAttributes('   ');
      expect(attrs, isEmpty);
    });

    test('handles attributes with spaces in values', () {
      final attrs = parseAttributes('title="Hello World" class="my class"');
      expect(attrs['title'], equals('Hello World'));
      expect(attrs['class'], equals('my class'));
    });
  });

  group('ExtractedComponent', () {
    test('stores attributes and content', () {
      final component = ExtractedComponent(
        attributes: {'label': 'Test'},
        content: 'Inner content',
      );
      expect(component.attributes['label'], equals('Test'));
      expect(component.content, equals('Inner content'));
    });
  });

  group('extractChildComponents', () {
    test('extracts child components', () {
      const content = '''
<Tab label="First">Content 1</Tab>
<Tab label="Second">Content 2</Tab>
''';

      final components = extractChildComponents(content, 'Tab');
      expect(components.length, equals(2));
      expect(components[0].attributes['label'], equals('First'));
      expect(components[0].content, equals('Content 1'));
      expect(components[1].attributes['label'], equals('Second'));
      expect(components[1].content, equals('Content 2'));
    });

    test('returns empty list when no components found', () {
      const content = 'Just plain text';
      final components = extractChildComponents(content, 'Tab');
      expect(components, isEmpty);
    });

    test('handles components with multiple attributes', () {
      const content = '<Item id="1" name="Test" active>Content</Item>';
      final components = extractChildComponents(content, 'Item');
      expect(components.length, equals(1));
      expect(components[0].attributes['id'], equals('1'));
      expect(components[0].attributes['name'], equals('Test'));
      expect(components[0].attributes['active'], equals('true'));
    });

    test('handles nested same-type components', () {
      const content = '''
<Box name="outer">
  <Box name="inner">Nested content</Box>
  More outer content
</Box>
''';
      final components = extractChildComponents(content, 'Box');
      expect(components.length, equals(1));
      expect(components[0].attributes['name'], equals('outer'));
      expect(components[0].content, contains('<Box name="inner">'));
      expect(components[0].content, contains('More outer content'));
    });

    test('handles deeply nested same-type components', () {
      const content = '''
<Folder name="root">
  <Folder name="level1">
    <Folder name="level2">Deep content</Folder>
  </Folder>
</Folder>
''';
      final components = extractChildComponents(content, 'Folder');
      expect(components.length, equals(1));
      expect(components[0].attributes['name'], equals('root'));
      expect(components[0].content, contains('<Folder name="level1">'));
      expect(components[0].content, contains('<Folder name="level2">'));
    });

    test('handles multiple sibling components with nested same-type', () {
      const content = '''
<Folder name="src">
  <Folder name="components">Inner</Folder>
</Folder>
<Folder name="tests">
  <Folder name="unit">Tests</Folder>
</Folder>
''';
      final components = extractChildComponents(content, 'Folder');
      expect(components.length, equals(2));
      expect(components[0].attributes['name'], equals('src'));
      expect(components[0].content, contains('<Folder name="components">'));
      expect(components[1].attributes['name'], equals('tests'));
      expect(components[1].content, contains('<Folder name="unit">'));
    });
  });

  group('findBalancedTags', () {
    test('finds simple tags', () {
      const content = '<Tag>Content</Tag>';
      final matches = findBalancedTags(content, 'Tag');
      expect(matches.length, equals(1));
      expect(matches[0].content, equals('Content'));
    });

    test('finds tags with attributes', () {
      const content = '<Tag id="1" name="test">Content</Tag>';
      final matches = findBalancedTags(content, 'Tag');
      expect(matches.length, equals(1));
      expect(matches[0].attributes, contains('id="1"'));
      expect(matches[0].attributes, contains('name="test"'));
    });

    test('handles nested same-type tags correctly', () {
      const content = '<Box><Box>Inner</Box></Box>';
      final matches = findBalancedTags(content, 'Box');
      expect(matches.length, equals(1));
      expect(matches[0].content, equals('<Box>Inner</Box>'));
    });

    test('handles case-insensitive closing tags', () {
      const content = '<Tag>Content</tag>';
      final matches = findBalancedTags(content, 'Tag');
      expect(matches.length, equals(1));
      expect(matches[0].content, equals('Content'));
    });

    test('returns empty list when no tags found', () {
      const content = 'Just plain text';
      final matches = findBalancedTags(content, 'Tag');
      expect(matches, isEmpty);
    });

    test('tracks start position correctly', () {
      const content = 'prefix <Tag>Content</Tag> suffix';
      final matches = findBalancedTags(content, 'Tag');
      expect(matches.length, equals(1));
      expect(matches[0].start, equals(7));
    });
  });
}
