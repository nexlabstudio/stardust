import 'package:stardust/src/utils/patterns.dart';
import 'package:test/test.dart';

void main() {
  group('htmlTagPattern', () {
    test('matches simple HTML tags', () {
      expect(htmlTagPattern.hasMatch('<div>'), isTrue);
      expect(htmlTagPattern.hasMatch('<span>'), isTrue);
      expect(htmlTagPattern.hasMatch('</div>'), isTrue);
    });

    test('matches self-closing tags', () {
      expect(htmlTagPattern.hasMatch('<br/>'), isTrue);
      expect(htmlTagPattern.hasMatch('<img />'), isTrue);
    });

    test('matches tags with attributes', () {
      expect(htmlTagPattern.hasMatch('<div class="test">'), isTrue);
      expect(htmlTagPattern.hasMatch('<a href="http://example.com">'), isTrue);
    });

    test('does not match plain text', () {
      expect(htmlTagPattern.hasMatch('hello world'), isFalse);
    });
  });

  group('codeBlockPattern', () {
    test('matches code blocks with language', () {
      const html = '<pre><code class="language-dart">void main() {}</code></pre>';
      final match = codeBlockPattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(1), equals('dart'));
      expect(match.group(2), equals('void main() {}'));
    });

    test('captures multiline code', () {
      const html = '<pre><code class="language-js">line1\nline2\nline3</code></pre>';
      final match = codeBlockPattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(2), contains('line1'));
      expect(match.group(2), contains('line3'));
    });
  });

  group('headingPattern', () {
    test('matches h1-h6 with id attribute', () {
      const html = '<h2 id="intro">Introduction</h2>';
      final match = headingPattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(1), equals('2'));
      expect(match.group(2), equals('intro'));
      expect(match.group(3), equals('Introduction'));
    });

    test('matches headings with nested elements', () {
      const html = '<h3 id="api"><code>API</code> Reference</h3>';
      final match = headingPattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(2), equals('api'));
    });
  });

  group('attributePattern', () {
    test('matches double-quoted attributes', () {
      const attr = 'src="image.png"';
      final match = attributePattern.firstMatch(attr);
      expect(match, isNotNull);
      expect(match!.group(1), equals('src'));
      expect(match.group(2), equals('image.png'));
    });

    test('matches single-quoted attributes', () {
      const attr = "alt='description'";
      final match = attributePattern.firstMatch(attr);
      expect(match, isNotNull);
      expect(match!.group(1), equals('alt'));
      expect(match.group(3), equals('description'));
    });

    test('matches curly-brace attributes (JSX style)', () {
      const attr = 'value={42}';
      final match = attributePattern.firstMatch(attr);
      expect(match, isNotNull);
      expect(match!.group(1), equals('value'));
      expect(match.group(4), equals('42'));
    });

    test('matches boolean attributes', () {
      const attr = 'disabled';
      final match = attributePattern.firstMatch(attr);
      expect(match, isNotNull);
      expect(match!.group(1), equals('disabled'));
    });
  });

  group('emojiPattern', () {
    test('matches common emojis', () {
      expect(emojiPattern.hasMatch('🔥'), isTrue);
      expect(emojiPattern.hasMatch('✨'), isTrue);
      expect(emojiPattern.hasMatch('🚀'), isTrue);
      expect(emojiPattern.hasMatch('😀'), isTrue);
    });

    test('does not match regular text', () {
      expect(emojiPattern.hasMatch('hello'), isFalse);
      expect(emojiPattern.hasMatch('123'), isFalse);
    });
  });

  group('youtubePatterns', () {
    test('matches youtu.be short URLs', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ';
      final id = youtubePatterns[0].firstMatch(url)?.group(1);
      expect(id, equals('dQw4w9WgXcQ'));
    });

    test('matches youtube.com watch URLs', () {
      const url = 'https://youtube.com/watch?v=dQw4w9WgXcQ';
      final id = youtubePatterns[1].firstMatch(url)?.group(1);
      expect(id, equals('dQw4w9WgXcQ'));
    });

    test('matches youtube.com embed URLs', () {
      const url = 'https://youtube.com/embed/dQw4w9WgXcQ';
      final id = youtubePatterns[2].firstMatch(url)?.group(1);
      expect(id, equals('dQw4w9WgXcQ'));
    });
  });

  group('vimeoPattern', () {
    test('matches vimeo.com URLs', () {
      const url = 'https://vimeo.com/123456789';
      final id = vimeoPattern.firstMatch(url)?.group(1);
      expect(id, equals('123456789'));
    });

    test('matches vimeo.com/video URLs', () {
      const url = 'https://vimeo.com/video/123456789';
      final id = vimeoPattern.firstMatch(url)?.group(1);
      expect(id, equals('123456789'));
    });
  });

  group('sanitization patterns', () {
    test('bracesPattern matches curly braces', () {
      expect(bracesPattern.hasMatch('{'), isTrue);
      expect(bracesPattern.hasMatch('}'), isTrue);
      expect(bracesPattern.hasMatch('a'), isFalse);
    });

    test('leadingTrailingDashPattern matches edge dashes', () {
      expect(leadingTrailingDashPattern.hasMatch('-hello'), isTrue);
      expect(leadingTrailingDashPattern.hasMatch('hello-'), isTrue);
      expect(leadingTrailingDashPattern.hasMatch('he-llo'), isFalse);
    });

    test('multipleDashPattern matches consecutive dashes', () {
      expect(multipleDashPattern.hasMatch('--'), isTrue);
      expect(multipleDashPattern.hasMatch('---'), isTrue);
      final replaced = 'a---b'.replaceAll(multipleDashPattern, '-');
      expect(replaced, equals('a-b'));
    });

    test('nonAlphanumericPattern matches special chars', () {
      expect(nonAlphanumericPattern.hasMatch('!'), isTrue);
      expect(nonAlphanumericPattern.hasMatch('@'), isTrue);
      expect(nonAlphanumericPattern.hasMatch('a'), isFalse);
      expect(nonAlphanumericPattern.hasMatch('1'), isFalse);
    });
  });

  group('component patterns', () {
    test('selfClosingComponentPattern matches self-closing tags', () {
      final pattern = selfClosingComponentPattern('Image');
      const html = '<Image src="test.png" />';
      final match = pattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(1), contains('src="test.png"'));
    });

    test('selfClosingComponentPattern is cached', () {
      final pattern1 = selfClosingComponentPattern('Test');
      final pattern2 = selfClosingComponentPattern('Test');
      expect(identical(pattern1, pattern2), isTrue);
    });

    test('openCloseComponentPattern matches component with content', () {
      final pattern = openCloseComponentPattern('Info');
      const html = '<Info title="Note">Some content here</Info>';
      final match = pattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(1), contains('title="Note"'));
      expect(match.group(2), equals('Some content here'));
    });

    test('openCloseComponentPattern is cached', () {
      final pattern1 = openCloseComponentPattern('Test');
      final pattern2 = openCloseComponentPattern('Test');
      expect(identical(pattern1, pattern2), isTrue);
    });

    test('childComponentPattern matches nested components', () {
      final pattern = childComponentPattern('Tab');
      const html = '<Tab label="First">Tab content</Tab>';
      final match = pattern.firstMatch(html);
      expect(match, isNotNull);
      expect(match!.group(1), contains('label="First"'));
      expect(match.group(2), equals('Tab content'));
    });
  });
}
