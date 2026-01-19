import 'package:stardust/src/content/components/embed_builder.dart';
import 'package:test/test.dart';

void main() {
  group('EmbedBuilder', () {
    late EmbedBuilder builder;

    setUp(() {
      builder = EmbedBuilder();
    });

    test('tagNames includes all embed components', () {
      expect(builder.tagNames, containsAll(['YouTube', 'Vimeo', 'Zapp', 'CodePen', 'StackBlitz']));
    });

    group('YouTube component', () {
      test('builds basic YouTube embed', () {
        final result = builder.build('YouTube', {'id': 'dQw4w9WgXcQ'}, '');

        expect(result, contains('embed-youtube'));
        expect(result, contains('youtube.com/embed/dQw4w9WgXcQ'));
        expect(result, contains('iframe'));
        expect(result, contains('allowfullscreen'));
      });

      test('uses content as ID when no id attribute', () {
        final result = builder.build('YouTube', {}, 'dQw4w9WgXcQ');

        expect(result, contains('youtube.com/embed/dQw4w9WgXcQ'));
      });

      test('extracts ID from youtu.be URL', () {
        final result = builder.build('YouTube', {'id': 'https://youtu.be/dQw4w9WgXcQ'}, '');

        expect(result, contains('youtube.com/embed/dQw4w9WgXcQ'));
      });

      test('extracts ID from youtube.com/watch URL', () {
        final result = builder.build('YouTube', {'id': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'}, '');

        expect(result, contains('youtube.com/embed/dQw4w9WgXcQ'));
      });

      test('extracts ID from youtube.com/embed URL', () {
        final result = builder.build('YouTube', {'id': 'https://www.youtube.com/embed/dQw4w9WgXcQ'}, '');

        expect(result, contains('youtube.com/embed/dQw4w9WgXcQ'));
      });

      test('extracts ID from youtube.com/v URL', () {
        final result = builder.build('YouTube', {'id': 'https://www.youtube.com/v/dQw4w9WgXcQ'}, '');

        expect(result, contains('youtube.com/embed/dQw4w9WgXcQ'));
      });

      test('includes start time when provided', () {
        final result = builder.build('YouTube', {'id': 'abc123', 'start': '60'}, '');

        expect(result, contains('?start=60'));
      });

      test('uses custom title when provided', () {
        final result = builder.build('YouTube', {'id': 'abc123', 'title': 'My Video'}, '');

        expect(result, contains('title="My Video"'));
      });

      test('uses default title when not provided', () {
        final result = builder.build('YouTube', {'id': 'abc123'}, '');

        expect(result, contains('title="YouTube video"'));
      });

      test('uses custom aspect ratio when provided', () {
        final result = builder.build('YouTube', {'id': 'abc123', 'aspectRatio': '4/3'}, '');

        expect(result, contains('aspect-ratio: 4/3'));
      });

      test('uses default 16/9 aspect ratio', () {
        final result = builder.build('YouTube', {'id': 'abc123'}, '');

        expect(result, contains('aspect-ratio: 16/9'));
      });

      test('returns error when ID is empty', () {
        final result = builder.build('YouTube', {}, '');

        expect(result, contains('embed-error'));
        expect(result, contains('Missing video ID'));
      });
    });

    group('Vimeo component', () {
      test('builds basic Vimeo embed', () {
        final result = builder.build('Vimeo', {'id': '123456789'}, '');

        expect(result, contains('embed-vimeo'));
        expect(result, contains('player.vimeo.com/video/123456789'));
        expect(result, contains('iframe'));
      });

      test('uses content as ID when no id attribute', () {
        final result = builder.build('Vimeo', {}, '123456789');

        expect(result, contains('player.vimeo.com/video/123456789'));
      });

      test('extracts ID from vimeo.com URL', () {
        final result = builder.build('Vimeo', {'id': 'https://vimeo.com/123456789'}, '');

        expect(result, contains('player.vimeo.com/video/123456789'));
      });

      test('extracts ID from vimeo.com/video URL', () {
        final result = builder.build('Vimeo', {'id': 'https://vimeo.com/video/123456789'}, '');

        expect(result, contains('player.vimeo.com/video/123456789'));
      });

      test('uses custom title when provided', () {
        final result = builder.build('Vimeo', {'id': '123', 'title': 'My Vimeo Video'}, '');

        expect(result, contains('title="My Vimeo Video"'));
      });

      test('uses default title', () {
        final result = builder.build('Vimeo', {'id': '123'}, '');

        expect(result, contains('title="Vimeo video"'));
      });

      test('uses custom aspect ratio', () {
        final result = builder.build('Vimeo', {'id': '123', 'aspectRatio': '21/9'}, '');

        expect(result, contains('aspect-ratio: 21/9'));
      });

      test('returns error when ID is empty', () {
        final result = builder.build('Vimeo', {}, '');

        expect(result, contains('embed-error'));
        expect(result, contains('Missing video ID'));
      });
    });

    group('Zapp component', () {
      test('builds basic Zapp embed', () {
        final result = builder.build('Zapp', {'id': 'flutter_demo'}, '');

        expect(result, contains('embed-zapp'));
        expect(result, contains('zapp.run/edit/flutter_demo'));
        expect(result, contains('iframe'));
      });

      test('uses content as ID when no id attribute', () {
        final result = builder.build('Zapp', {}, 'my_project');

        expect(result, contains('zapp.run/edit/my_project'));
      });

      test('uses dark theme by default', () {
        final result = builder.build('Zapp', {'id': 'test'}, '');

        expect(result, contains('theme=dark'));
      });

      test('supports custom theme', () {
        final result = builder.build('Zapp', {'id': 'test', 'theme': 'light'}, '');

        expect(result, contains('theme=light'));
      });

      test('enables lazy loading by default', () {
        final result = builder.build('Zapp', {'id': 'test'}, '');

        expect(result, contains('lazy=true'));
      });

      test('can disable lazy loading', () {
        final result = builder.build('Zapp', {'id': 'test', 'lazy': 'false'}, '');

        expect(result, contains('lazy=false'));
      });

      test('uses custom height when provided', () {
        final result = builder.build('Zapp', {'id': 'test', 'height': '600px'}, '');

        expect(result, contains('height: 600px'));
      });

      test('uses default 500px height', () {
        final result = builder.build('Zapp', {'id': 'test'}, '');

        expect(result, contains('height: 500px'));
      });

      test('returns error when ID is empty', () {
        final result = builder.build('Zapp', {}, '');

        expect(result, contains('embed-error'));
        expect(result, contains('Missing project ID'));
      });
    });

    group('CodePen component', () {
      test('builds basic CodePen embed', () {
        final result = builder.build('CodePen', {'id': 'abcdef', 'user': 'johndoe'}, '');

        expect(result, contains('embed-codepen'));
        expect(result, contains('codepen.io/johndoe/embed/abcdef'));
        expect(result, contains('iframe'));
      });

      test('uses custom title', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user', 'title': 'My Pen'}, '');

        expect(result, contains('title="My Pen"'));
      });

      test('uses custom height', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user', 'height': '500'}, '');

        expect(result, contains('height: 500px'));
      });

      test('uses default 400px height', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user'}, '');

        expect(result, contains('height: 400px'));
      });

      test('uses custom default tab', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user', 'defaultTab': 'html,result'}, '');

        expect(result, contains('default-tab=html,result'));
      });

      test('uses result as default tab', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user'}, '');

        expect(result, contains('default-tab=result'));
      });

      test('uses custom theme', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user', 'theme': 'light'}, '');

        expect(result, contains('theme-id=light'));
      });

      test('uses dark theme by default', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user'}, '');

        expect(result, contains('theme-id=dark'));
      });

      test('supports editable mode', () {
        final result = builder.build('CodePen', {'id': 'abc', 'user': 'user', 'editable': 'true'}, '');

        expect(result, contains('editable=true'));
      });

      test('returns error when ID is missing', () {
        final result = builder.build('CodePen', {'user': 'user'}, '');

        expect(result, contains('embed-error'));
        expect(result, contains('Missing user or pen ID'));
      });

      test('returns error when user is missing', () {
        final result = builder.build('CodePen', {'id': 'abc'}, '');

        expect(result, contains('embed-error'));
        expect(result, contains('Missing user or pen ID'));
      });
    });

    group('StackBlitz component', () {
      test('builds basic StackBlitz embed', () {
        final result = builder.build('StackBlitz', {'id': 'my-project'}, '');

        expect(result, contains('embed-stackblitz'));
        expect(result, contains('stackblitz.com/edit/my-project'));
        expect(result, contains('iframe'));
      });

      test('uses content as ID when no id attribute', () {
        final result = builder.build('StackBlitz', {}, 'project-id');

        expect(result, contains('stackblitz.com/edit/project-id'));
      });

      test('uses custom title', () {
        final result = builder.build('StackBlitz', {'id': 'test', 'title': 'Demo Project'}, '');

        expect(result, contains('title="Demo Project"'));
      });

      test('uses custom height', () {
        final result = builder.build('StackBlitz', {'id': 'test', 'height': '700px'}, '');

        expect(result, contains('height: 700px'));
      });

      test('uses default 500px height', () {
        final result = builder.build('StackBlitz', {'id': 'test'}, '');

        expect(result, contains('height: 500px'));
      });

      test('includes file parameter when provided', () {
        final result = builder.build('StackBlitz', {'id': 'test', 'file': 'src/index.ts'}, '');

        expect(result, contains('file=src/index.ts'));
      });

      test('supports hideNavigation option', () {
        final result = builder.build('StackBlitz', {'id': 'test', 'hideNavigation': 'true'}, '');

        expect(result, contains('hideNavigation=1'));
      });

      test('supports hideDevTools option', () {
        final result = builder.build('StackBlitz', {'id': 'test', 'hideDevTools': 'true'}, '');

        expect(result, contains('hideDevtools=1'));
      });

      test('supports custom view', () {
        final result = builder.build('StackBlitz', {'id': 'test', 'view': 'editor'}, '');

        expect(result, contains('view=editor'));
      });

      test('uses preview view by default', () {
        final result = builder.build('StackBlitz', {'id': 'test'}, '');

        expect(result, contains('view=preview'));
      });

      test('returns error when ID is empty', () {
        final result = builder.build('StackBlitz', {}, '');

        expect(result, contains('embed-error'));
        expect(result, contains('Missing project ID'));
      });
    });

    test('unknown tag returns content unchanged', () {
      final result = builder.build('Unknown', {}, 'content');

      expect(result, equals('content'));
    });
  });
}
