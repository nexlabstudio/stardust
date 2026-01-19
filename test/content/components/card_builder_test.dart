import 'package:stardust/src/content/components/card_builder.dart';
import 'package:test/test.dart';

void main() {
  group('CardBuilder', () {
    late CardBuilder builder;

    setUp(() {
      builder = CardBuilder();
    });

    test('tagNames includes all card components', () {
      expect(builder.tagNames, containsAll(['Cards', 'CardGroup', 'Card', 'Tiles']));
    });

    group('Cards component', () {
      test('builds cards container with child cards', () {
        const content = '''
<Card title="Card 1">Content 1</Card>
<Card title="Card 2">Content 2</Card>
''';
        final result = builder.build('Cards', {}, content);

        expect(result, contains('class="cards"'));
        expect(result, contains('Card 1'));
        expect(result, contains('Card 2'));
      });

      test('uses columns attribute', () {
        final result = builder.build('Cards', {'columns': '3'}, '');

        expect(result, contains('--cards-columns: 3'));
      });

      test('uses cols attribute as alternative', () {
        final result = builder.build('Cards', {'cols': '4'}, '');

        expect(result, contains('--cards-columns: 4'));
      });

      test('defaults to 2 columns', () {
        final result = builder.build('Cards', {}, '');

        expect(result, contains('--cards-columns: 2'));
      });
    });

    group('CardGroup component', () {
      test('builds same as Cards', () {
        const content = '<Card title="Test">Content</Card>';
        final result = builder.build('CardGroup', {}, content);

        expect(result, contains('class="cards"'));
        expect(result, contains('Test'));
      });
    });

    group('Card component', () {
      test('builds basic card', () {
        final result = builder.build('Card', {'title': 'My Card'}, 'Card content');

        expect(result, contains('class="card"'));
        expect(result, contains('card-title'));
        expect(result, contains('My Card'));
        expect(result, contains('card-content'));
        expect(result, contains('Card content'));
      });

      test('builds card without title', () {
        final result = builder.build('Card', {}, 'Just content');

        expect(result, contains('class="card"'));
        expect(result, contains('Just content'));
        expect(result, isNot(contains('card-title')));
      });

      test('adds emoji icon', () {
        final result = builder.build('Card', {'title': 'Card', 'icon': '🚀'}, '');

        expect(result, contains('card-icon'));
        expect(result, contains('🚀'));
      });

      test('adds lucide icon', () {
        final result = builder.build('Card', {'title': 'Card', 'icon': 'star'}, '');

        expect(result, contains('card-icon'));
        // Lucide icons are SVG
        expect(result, contains('</span>'));
      });

      test('builds link card when href provided', () {
        final result = builder.build('Card', {'title': 'Link Card', 'href': '/docs'}, 'Click me');

        expect(result, contains('<a href="/docs"'));
        expect(result, contains('card-link'));
      });

      test('builds div card when no href', () {
        final result = builder.build('Card', {'title': 'Card'}, 'Content');

        expect(result, contains('<div class="card">'));
        expect(result, isNot(contains('<a ')));
      });
    });

    group('Tiles component', () {
      test('builds tiles container with child tiles', () {
        const content = '''
<Tile title="Tile 1">Content 1</Tile>
<Tile title="Tile 2">Content 2</Tile>
''';
        final result = builder.build('Tiles', {}, content);

        expect(result, contains('class="tiles"'));
        expect(result, contains('Tile 1'));
        expect(result, contains('Tile 2'));
      });

      test('uses columns attribute', () {
        final result = builder.build('Tiles', {'columns': '4'}, '<Tile title="T">C</Tile>');

        expect(result, contains('--tiles-columns: 4'));
      });

      test('defaults to 3 columns', () {
        final result = builder.build('Tiles', {}, '<Tile title="T">C</Tile>');

        expect(result, contains('--tiles-columns: 3'));
      });

      test('shows empty message when no tiles', () {
        final result = builder.build('Tiles', {}, '');

        expect(result, contains('tiles-empty'));
        expect(result, contains('No tiles defined'));
      });

      test('builds tile with title', () {
        const content = '<Tile title="Feature">Description</Tile>';
        final result = builder.build('Tiles', {}, content);

        expect(result, contains('tile-title'));
        expect(result, contains('Feature'));
      });

      test('builds tile with emoji icon', () {
        const content = '<Tile title="Feature" icon="✨">Content</Tile>';
        final result = builder.build('Tiles', {}, content);

        expect(result, contains('tile-icon'));
        expect(result, contains('✨'));
      });

      test('builds tile with lucide icon', () {
        const content = '<Tile title="Feature" icon="zap">Content</Tile>';
        final result = builder.build('Tiles', {}, content);

        expect(result, contains('tile-icon'));
      });

      test('builds link tile when href provided', () {
        const content = '<Tile title="Link" href="/page">Content</Tile>';
        final result = builder.build('Tiles', {}, content);

        expect(result, contains('<a href="/page"'));
        expect(result, contains('tile-link'));
      });

      test('builds div tile when no href', () {
        const content = '<Tile title="Tile">Content</Tile>';
        final result = builder.build('Tiles', {}, content);

        expect(result, contains('<div class="tile">'));
      });
    });

    test('unknown tag returns content unchanged', () {
      final result = builder.build('Unknown', {}, 'content');

      expect(result, equals('content'));
    });
  });
}
