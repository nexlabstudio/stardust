import 'package:stardust/src/content/component_transformer.dart';
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
        final transformer = ComponentTransformer()..register(NoSelfCloseBuilder());
        final result = transformer.transform('<Block />');
        expect(result, contains('<Block />'));
      });

      test('still transforms open/close when self-closing disabled', () {
        final transformer = ComponentTransformer()..register(NoSelfCloseBuilder());
        final result = transformer.transform('<Block>content</Block>');
        expect(result, contains('<div class="block">content</div>'));
      });
    });
  });
}
