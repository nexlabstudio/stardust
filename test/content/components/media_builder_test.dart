import 'package:stardust/src/content/components/media_builder.dart';
import 'package:test/test.dart';

void main() {
  group('MediaBuilder', () {
    late MediaBuilder builder;

    setUp(() {
      builder = MediaBuilder();
    });

    test('tagNames includes all media components', () {
      expect(builder.tagNames, containsAll(['Image', 'Video', 'Mermaid', 'Tree']));
    });

    group('Image component', () {
      test('builds basic image', () {
        final result = builder.build('Image', {'src': '/test.png', 'alt': 'Test image'}, '');

        expect(result, contains('image-component'));
        expect(result, contains('src="/test.png"'));
        expect(result, contains('alt="Test image"'));
        expect(result, contains('loading="lazy"'));
      });

      test('supports width and height', () {
        final result = builder.build('Image', {'src': '/test.png', 'width': '400px', 'height': '300px'}, '');

        expect(result, contains('width: 400px'));
        expect(result, contains('height: 300px'));
      });

      test('adds zoom class when zoom enabled', () {
        final result = builder.build('Image', {'src': '/test.png', 'zoom': 'true'}, '');

        expect(result, contains('image-zoomable'));
        expect(result, contains('image-zoom-wrapper'));
        expect(result, contains('data-zoom-src="/test.png"'));
      });

      test('adds zoom when zoom attribute exists', () {
        final result = builder.build('Image', {'src': '/test.png', 'zoom': ''}, '');

        expect(result, contains('image-zoomable'));
      });

      test('adds rounded class when rounded enabled', () {
        final result = builder.build('Image', {'src': '/test.png', 'rounded': 'true'}, '');

        expect(result, contains('image-rounded'));
      });

      test('adds border class when border enabled', () {
        final result = builder.build('Image', {'src': '/test.png', 'border': 'true'}, '');

        expect(result, contains('image-bordered'));
      });

      test('wraps in figure with caption', () {
        final result = builder.build('Image', {'src': '/test.png', 'caption': 'Figure 1: Test'}, '');

        expect(result, contains('<figure'));
        expect(result, contains('<figcaption class="image-caption">Figure 1: Test</figcaption>'));
      });

      test('uses div wrapper when no caption', () {
        final result = builder.build('Image', {'src': '/test.png'}, '');

        expect(result, contains('<div class="image-component">'));
        expect(result, isNot(contains('<figure')));
      });

      test('handles empty src and alt', () {
        final result = builder.build('Image', {}, '');

        expect(result, contains('src=""'));
        expect(result, contains('alt=""'));
      });
    });

    group('Video component', () {
      test('builds basic video', () {
        final result = builder.build('Video', {'src': '/video.mp4'}, '');

        expect(result, contains('embed-video'));
        expect(result, contains('<video'));
        expect(result, contains('<source src="/video.mp4"'));
        expect(result, contains('controls'));
      });

      test('uses content as src when no src attribute', () {
        final result = builder.build('Video', {}, '/video.mp4');

        expect(result, contains('<source src="/video.mp4"'));
      });

      test('supports poster attribute', () {
        final result = builder.build('Video', {'src': '/video.mp4', 'poster': '/poster.jpg'}, '');

        expect(result, contains('poster="/poster.jpg"'));
      });

      test('supports autoplay attribute', () {
        final result = builder.build('Video', {'src': '/video.mp4', 'autoplay': 'true'}, '');

        expect(result, contains('autoplay'));
        expect(result, contains('muted')); // autoplay requires muted
      });

      test('supports loop attribute', () {
        final result = builder.build('Video', {'src': '/video.mp4', 'loop': 'true'}, '');

        expect(result, contains('loop'));
      });

      test('supports muted attribute', () {
        final result = builder.build('Video', {'src': '/video.mp4', 'muted': 'true'}, '');

        expect(result, contains('muted'));
      });

      test('can disable controls', () {
        final result = builder.build('Video', {'src': '/video.mp4', 'controls': 'false'}, '');

        expect(result, isNot(contains('controls')));
      });

      test('uses custom title', () {
        final result = builder.build('Video', {'src': '/video.mp4', 'title': 'Demo Video'}, '');

        expect(result, contains('title="Demo Video"'));
      });

      test('uses default title', () {
        final result = builder.build('Video', {'src': '/video.mp4'}, '');

        expect(result, contains('title="Video"'));
      });

      test('returns error when src is empty', () {
        final result = builder.build('Video', {}, '');

        expect(result, contains('embed-error'));
        expect(result, contains('Missing source URL'));
      });
    });

    group('Mermaid component', () {
      test('builds basic mermaid diagram', () {
        const content = '''
graph TD
  A --> B
  B --> C
''';
        final result = builder.build('Mermaid', {}, content);

        expect(result, contains('mermaid-diagram'));
        expect(result, contains('<pre class="mermaid">'));
        expect(result, contains('graph TD'));
      });

      test('uses default theme', () {
        final result = builder.build('Mermaid', {}, 'graph TD');

        expect(result, contains('data-theme="default"'));
      });

      test('supports custom theme', () {
        final result = builder.build('Mermaid', {'theme': 'dark'}, 'graph TD');

        expect(result, contains('data-theme="dark"'));
      });

      test('wraps in figure with caption', () {
        final result = builder.build('Mermaid', {'caption': 'Figure 1: Flow'}, 'graph TD');

        expect(result, contains('<figure class="mermaid-figure">'));
        expect(result, contains('<figcaption class="mermaid-caption">Figure 1: Flow</figcaption>'));
      });

      test('escapes HTML in content', () {
        final result = builder.build('Mermaid', {}, 'A[Label <script>] --> B');

        expect(result, contains('&lt;script&gt;'));
        expect(result, isNot(contains('<script>')));
      });
    });

    group('Tree component', () {
      test('builds basic tree structure', () {
        const content = '''
<Folder name="src">
  <File name="index.ts" />
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('class="tree"'));
        expect(result, contains('tree-root'));
        expect(result, contains('tree-folder'));
        expect(result, contains('tree-file'));
      });

      test('renders folder with name', () {
        const content = '<Folder name="components"></Folder>';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('components'));
        expect(result, contains('tree-folder-name'));
      });

      test('renders folder with open attribute', () {
        const content = '<Folder name="src" open></Folder>';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('<details open>'));
      });

      test('renders file with name', () {
        const content = '<File name="main.dart" />';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('main.dart'));
        expect(result, contains('tree-file-name'));
      });

      test('uses appropriate file icon', () {
        const content = '<File name="script.js" />';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('tree-icon-file'));
      });

      test('supports custom icon for file', () {
        const content = '<File name="custom.xyz" icon="custom-icon" />';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('custom-icon'));
      });

      test('handles folder with nested content', () {
        const content = '''
<Folder name="src">
  <File name="index.ts" />
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('src'));
        expect(result, contains('index.ts'));
        expect(result, contains('tree-children'));
      });

      test('handles folder with files', () {
        const content = '''
<Folder name="src">
  <File name="index.ts" />
  <File name="utils.ts" />
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('src'));
        expect(result, contains('index.ts'));
        expect(result, contains('utils.ts'));
        expect(result, contains('tree-folder'));
        expect(result, contains('tree-children'));
      });

      test('handles multiple files in folder', () {
        const content = '''
<Folder name="lib">
  <File name="a.dart" />
  <File name="b.dart" />
  <File name="c.dart" />
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('a.dart'));
        expect(result, contains('b.dart'));
        expect(result, contains('c.dart'));
      });

      test('handles deeply nested folders', () {
        const content = '''
<Folder name="src">
  <Folder name="components">
    <File name="Button.tsx" />
    <Folder name="ui">
      <File name="Card.tsx" />
    </Folder>
  </Folder>
  <File name="index.ts" />
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('src'));
        expect(result, contains('components'));
        expect(result, contains('ui'));
        expect(result, contains('Button.tsx'));
        expect(result, contains('Card.tsx'));
        expect(result, contains('index.ts'));
      });

      test('handles multiple sibling folders', () {
        const content = '''
<Folder name="src">
  <File name="main.ts" />
</Folder>
<Folder name="tests">
  <File name="test.ts" />
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        expect(result, contains('src'));
        expect(result, contains('tests'));
        expect(result, contains('main.ts'));
        expect(result, contains('test.ts'));
      });

      test('does not duplicate files inside folders', () {
        const content = '''
<Folder name="src">
  <File name="index.ts" />
  <File name="utils.ts" />
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        // Count occurrences - each file should appear exactly once
        final indexCount = 'index.ts'.allMatches(result).length;
        final utilsCount = 'utils.ts'.allMatches(result).length;

        expect(indexCount, equals(1), reason: 'index.ts should appear exactly once');
        expect(utilsCount, equals(1), reason: 'utils.ts should appear exactly once');
      });

      test('does not duplicate files in deeply nested folders', () {
        const content = '''
<Folder name="src">
  <Folder name="components">
    <File name="Button.tsx" />
  </Folder>
</Folder>
''';
        final result = builder.build('Tree', {}, content);

        // Button.tsx should appear exactly once
        final buttonCount = 'Button.tsx'.allMatches(result).length;
        expect(buttonCount, equals(1), reason: 'Button.tsx should appear exactly once');
      });
    });

    test('unknown tag returns content unchanged', () {
      final result = builder.build('Unknown', {}, 'content');

      expect(result, equals('content'));
    });
  });
}
