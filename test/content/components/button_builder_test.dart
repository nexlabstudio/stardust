import 'package:stardust/src/content/components/button_builder.dart';
import 'package:test/test.dart';

void main() {
  group('ButtonBuilder', () {
    late ButtonBuilder builder;

    setUp(() => builder = ButtonBuilder());

    test('handles the Button tag', () {
      expect(builder.tagNames, ['Button']);
    });

    test('builds a primary button with the label', () {
      final html = builder.build('Button', {'href': '/quickstart', 'variant': 'primary'}, 'Get Started');

      expect(html, contains('class="button button--primary"'));
      expect(html, contains('href="/quickstart"'));
      expect(html, contains('>Get Started<'));
    });

    test('defaults to the secondary variant', () {
      expect(builder.build('Button', {'href': '/x'}, 'Go'), contains('button--secondary'));
    });

    test('adds target/rel for external buttons', () {
      final html = builder.build('Button', {'href': 'https://x.com', 'external': 'true'}, 'Out');

      expect(html, contains('target="_blank" rel="noopener"'));
    });

    test('strips a wrapping paragraph and sanitizes the href', () {
      final html = builder.build('Button', {'href': 'javascript:alert(1)'}, '<p>Bad</p>');

      expect(html, contains('>Bad<'));
      expect(html, isNot(contains('javascript:')));
      expect(html, contains('href=""'));
    });
  });
}
