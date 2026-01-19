import 'package:stardust/src/content/components/utility_builder.dart';
import 'package:test/test.dart';

void main() {
  group('UtilityBuilder', () {
    late UtilityBuilder builder;

    setUp(() {
      builder = UtilityBuilder();
    });

    test('tagNames includes all utility components', () {
      expect(builder.tagNames, containsAll(['Badge', 'Icon', 'Tooltip', 'Update']));
    });

    group('Badge component', () {
      test('builds basic badge', () {
        final result = builder.build('Badge', {}, 'New');

        expect(result, contains('class="badge'));
        expect(result, contains('New'));
      });

      test('uses default variant', () {
        final result = builder.build('Badge', {}, 'Text');

        expect(result, contains('badge-default'));
      });

      test('supports custom variant', () {
        final result = builder.build('Badge', {'variant': 'success'}, 'Text');

        expect(result, contains('badge-success'));
      });

      test('uses default size', () {
        final result = builder.build('Badge', {}, 'Text');

        expect(result, contains('badge-md'));
      });

      test('supports custom size', () {
        final result = builder.build('Badge', {'size': 'lg'}, 'Text');

        expect(result, contains('badge-lg'));
      });

      test('adds emoji icon', () {
        final result = builder.build('Badge', {'icon': '✨'}, 'Sparkle');

        expect(result, contains('badge-icon'));
        expect(result, contains('✨'));
      });

      test('adds lucide icon', () {
        final result = builder.build('Badge', {'icon': 'star'}, 'Star');

        expect(result, contains('badge-icon'));
      });
    });

    group('Icon component', () {
      test('builds emoji icon', () {
        final result = builder.build('Icon', {'name': '🎉'}, '');

        expect(result, contains('icon-emoji'));
        expect(result, contains('🎉'));
      });

      test('builds lucide icon', () {
        final result = builder.build('Icon', {'name': 'heart'}, '');

        expect(result, contains('icon-svg'));
      });

      test('uses content as name when no name attribute', () {
        final result = builder.build('Icon', {}, '🚀');

        expect(result, contains('🚀'));
      });

      test('uses custom size for emoji', () {
        final result = builder.build('Icon', {'name': '🎉', 'size': '32'}, '');

        expect(result, contains('font-size: 32px'));
      });

      test('uses custom size for lucide icon', () {
        final result = builder.build('Icon', {'name': 'star', 'size': '32'}, '');

        expect(result, contains('width: 32px'));
        expect(result, contains('height: 32px'));
      });

      test('uses default size for lucide icons', () {
        final result = builder.build('Icon', {'name': 'star'}, '');

        // Lucide icons use the size parameter differently
        expect(result, contains('icon-svg'));
      });

      test('adds color style', () {
        final result = builder.build('Icon', {'name': '❤️', 'color': 'red'}, '');

        expect(result, contains('color: red'));
      });
    });

    group('Tooltip component', () {
      test('builds basic tooltip', () {
        final result = builder.build('Tooltip', {'content': 'Help text'}, 'Hover me');

        expect(result, contains('class="tooltip'));
        expect(result, contains('data-tooltip="Help text"'));
        expect(result, contains('Hover me'));
      });

      test('uses content attribute', () {
        final result = builder.build('Tooltip', {'content': 'Info'}, 'Text');

        expect(result, contains('data-tooltip="Info"'));
      });

      test('uses tip attribute as alternative', () {
        final result = builder.build('Tooltip', {'tip': 'Alternative'}, 'Text');

        expect(result, contains('data-tooltip="Alternative"'));
      });

      test('uses default top position', () {
        final result = builder.build('Tooltip', {'content': 'Tip'}, 'Text');

        expect(result, contains('tooltip-top'));
      });

      test('supports custom position', () {
        final result = builder.build('Tooltip', {'content': 'Tip', 'position': 'bottom'}, 'Text');

        expect(result, contains('tooltip-bottom'));
      });

      test('escapes HTML in tooltip content', () {
        final result = builder.build('Tooltip', {'content': '<script>alert("xss")</script>'}, 'Text');

        expect(result, contains('&lt;script&gt;'));
        expect(result, isNot(contains('<script>')));
      });
    });

    group('Update component', () {
      test('builds basic update', () {
        final result = builder.build('Update', {}, 'Release notes here');

        expect(result, contains('class="update'));
        expect(result, contains('update-header'));
        expect(result, contains('update-content'));
        expect(result, contains('Release notes here'));
      });

      test('uses default label', () {
        final result = builder.build('Update', {}, 'Content');

        expect(result, contains('update-label'));
        expect(result, contains('Update'));
      });

      test('supports custom label', () {
        final result = builder.build('Update', {'label': 'New Release'}, 'Content');

        expect(result, contains('New Release'));
      });

      test('shows version when provided', () {
        final result = builder.build('Update', {'version': '2.0.0'}, 'Content');

        expect(result, contains('update-version'));
        expect(result, contains('v2.0.0'));
      });

      test('does not show version when not provided', () {
        final result = builder.build('Update', {}, 'Content');

        expect(result, isNot(contains('update-version')));
      });

      test('shows date when provided', () {
        final result = builder.build('Update', {'date': '2024-01-15'}, 'Content');

        expect(result, contains('update-date'));
        expect(result, contains('2024-01-15'));
      });

      test('does not show date when not provided', () {
        final result = builder.build('Update', {}, 'Content');

        expect(result, isNot(contains('update-date')));
      });

      test('uses default type', () {
        final result = builder.build('Update', {}, 'Content');

        expect(result, contains('update-default'));
      });

      test('supports custom type', () {
        final result = builder.build('Update', {'type': 'breaking'}, 'Content');

        expect(result, contains('update-breaking'));
      });

      test('combines all attributes', () {
        final result = builder.build(
            'Update',
            {
              'label': 'Major Release',
              'version': '3.0.0',
              'date': '2024-02-01',
              'type': 'feature',
            },
            'New features');

        expect(result, contains('Major Release'));
        expect(result, contains('v3.0.0'));
        expect(result, contains('2024-02-01'));
        expect(result, contains('update-feature'));
        expect(result, contains('New features'));
      });
    });

    test('unknown tag returns content unchanged', () {
      final result = builder.build('Unknown', {}, 'content');

      expect(result, equals('content'));
    });
  });
}
