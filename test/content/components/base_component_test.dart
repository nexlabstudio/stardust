import 'package:stardust/src/content/components/base_component.dart';
import 'package:test/test.dart';

class TestBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Test', 'Demo'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) {
    final title = attributes['title'] ?? '';
    return '<div class="$tagName" data-title="$title">$content</div>';
  }
}

class NoSelfCloseBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['Block'];

  @override
  bool get allowSelfClosing => false;

  @override
  String build(String tagName, Map<String, String> attributes, String content) => '<div class="block">$content</div>';
}

void main() {
  group('ComponentBuilder', () {
    group('transformAll', () {
      late TestBuilder builder;

      setUp(() {
        builder = TestBuilder();
      });

      test('transforms self-closing tags', () {
        const content = '<Test title="Hello" />';
        final result = builder.transformAll(content, (_) => '');

        expect(result, contains('<div class="Test"'));
        expect(result, contains('data-title="Hello"'));
      });

      test('transforms open/close tags', () {
        const content = '<Test title="World">Inner content</Test>';
        final result = builder.transformAll(content, (_) => '');

        expect(result, contains('<div class="Test"'));
        expect(result, contains('data-title="World"'));
        expect(result, contains('Inner content'));
      });

      test('transforms multiple tag types', () {
        const content = '<Test /><Demo />';
        final result = builder.transformAll(content, (_) => '');

        expect(result, contains('class="Test"'));
        expect(result, contains('class="Demo"'));
      });

      test('transforms nested same-type components', () {
        const content = '''<Test title="outer">
<Test title="inner">Nested</Test>
</Test>''';
        final result = builder.transformAll(content, (_) => '');

        expect(result, contains('data-title="outer"'));
        expect(result, contains('data-title="inner"'));
        expect(result, contains('Nested'));
      });

      test('leaves non-matching content unchanged', () {
        const content = '<div>Plain HTML</div>';
        final result = builder.transformAll(content, (_) => '');

        expect(result, equals(content));
      });

      test('handles empty content', () {
        const content = '';
        final result = builder.transformAll(content, (_) => '');

        expect(result, equals(''));
      });

      test('handles content with no components', () {
        const content = 'Just some text without any components';
        final result = builder.transformAll(content, (_) => '');

        expect(result, equals(content));
      });
    });

    group('allowSelfClosing', () {
      test('defaults to true', () {
        final builder = TestBuilder();

        expect(builder.allowSelfClosing, isTrue);
      });

      test('can be overridden to false', () {
        final builder = NoSelfCloseBuilder();

        expect(builder.allowSelfClosing, isFalse);
      });

      test('does not transform self-closing when disabled', () {
        final builder = NoSelfCloseBuilder();
        const content = '<Block />';
        final result = builder.transformAll(content, (_) => '');

        // Should remain unchanged since self-closing is not allowed
        expect(result, equals(content));
      });

      test('still transforms open/close when self-closing disabled', () {
        final builder = NoSelfCloseBuilder();
        const content = '<Block>Content</Block>';
        final result = builder.transformAll(content, (_) => '');

        expect(result, contains('class="block"'));
        expect(result, contains('Content'));
      });
    });
  });
}
