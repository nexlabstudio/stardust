import 'package:stardust/src/content/components/layout_builder.dart';
import 'package:test/test.dart';

void main() {
  group('LayoutBuilder', () {
    late LayoutBuilder builder;

    setUp(() {
      builder = LayoutBuilder();
    });

    test('tagNames includes all layout components', () {
      expect(builder.tagNames, containsAll(['Columns', 'Panel', 'Frame']));
    });

    group('Columns component', () {
      test('builds columns container with child columns', () {
        const content = '''
<Column>Left column</Column>
<Column>Right column</Column>
''';
        final result = builder.build('Columns', {}, content);

        expect(result, contains('class="columns"'));
        expect(result, contains('class="column"'));
        expect(result, contains('Left column'));
        expect(result, contains('Right column'));
      });

      test('uses custom gap', () {
        final result = builder.build('Columns', {'gap': '2rem'}, '<Column>Content</Column>');

        expect(result, contains('--columns-gap: 2rem'));
      });

      test('defaults to 1rem gap', () {
        final result = builder.build('Columns', {}, '<Column>Content</Column>');

        expect(result, contains('--columns-gap: 1rem'));
      });

      test('wraps content in single column when no Column children', () {
        final result = builder.build('Columns', {}, 'Plain content without columns');

        expect(result, contains('class="columns"'));
        expect(result, contains('class="column"'));
        expect(result, contains('Plain content without columns'));
      });

      test('applies width to column', () {
        const content = '<Column width="60%">Wide column</Column><Column>Normal column</Column>';
        final result = builder.build('Columns', {}, content);

        expect(result, contains('flex: 0 0 60%'));
        expect(result, contains('max-width: 60%'));
      });
    });

    group('Panel component', () {
      test('builds basic panel', () {
        final result = builder.build('Panel', {}, 'Panel content');

        expect(result, contains('class="panel panel-default"'));
        expect(result, contains('panel-content'));
        expect(result, contains('Panel content'));
      });

      test('builds panel with title', () {
        final result = builder.build('Panel', {'title': 'Important'}, 'Content');

        expect(result, contains('panel-header'));
        expect(result, contains('panel-title'));
        expect(result, contains('Important'));
      });

      test('builds panel without header when no title', () {
        final result = builder.build('Panel', {}, 'Just content');

        expect(result, isNot(contains('panel-header')));
      });

      test('supports variant attribute', () {
        final result = builder.build('Panel', {'variant': 'info'}, 'Content');

        expect(result, contains('panel-info'));
      });

      test('adds emoji icon', () {
        final result = builder.build('Panel', {'title': 'Note', 'icon': '📝'}, 'Content');

        expect(result, contains('panel-icon'));
        expect(result, contains('📝'));
      });

      test('adds lucide icon', () {
        final result = builder.build('Panel', {'title': 'Settings', 'icon': 'settings'}, 'Content');

        expect(result, contains('panel-icon'));
      });
    });

    group('Frame component', () {
      test('builds browser frame by default', () {
        final result = builder.build('Frame', {}, '<p>Content</p>');

        expect(result, contains('frame-browser'));
        expect(result, contains('frame-header'));
        expect(result, contains('frame-buttons'));
        expect(result, contains('frame-close'));
        expect(result, contains('frame-minimize'));
        expect(result, contains('frame-maximize'));
        expect(result, contains('frame-content'));
      });

      test('builds browser frame with url', () {
        final result = builder.build('Frame', {'url': 'https://example.com'}, 'Content');

        expect(result, contains('frame-url'));
        expect(result, contains('https://example.com'));
      });

      test('builds phone frame', () {
        final result = builder.build('Frame', {'type': 'phone'}, 'Content');

        expect(result, contains('frame-phone'));
        expect(result, contains('frame-phone-notch'));
        expect(result, contains('frame-phone-home'));
      });

      test('builds mobile frame (alias for phone)', () {
        final result = builder.build('Frame', {'type': 'mobile'}, 'Content');

        expect(result, contains('frame-phone'));
      });

      test('supports device attribute for phone', () {
        final result = builder.build('Frame', {'type': 'phone', 'device': 'android'}, 'Content');

        expect(result, contains('frame-android'));
      });

      test('defaults to iphone device', () {
        final result = builder.build('Frame', {'type': 'phone'}, 'Content');

        expect(result, contains('frame-iphone'));
      });
    });

    test('unknown tag returns content unchanged', () {
      final result = builder.build('Unknown', {}, 'content');

      expect(result, equals('content'));
    });
  });
}
