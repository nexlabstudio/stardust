import 'package:stardust/src/utils/html_utils.dart';
import 'package:test/test.dart';

void main() {
  group('encodeHtml', () {
    test('encodes ampersand', () {
      expect(encodeHtml('a & b'), equals('a &amp; b'));
    });

    test('encodes less than', () {
      expect(encodeHtml('a < b'), equals('a &lt; b'));
    });

    test('encodes greater than', () {
      expect(encodeHtml('a > b'), equals('a &gt; b'));
    });

    test('encodes double quotes', () {
      expect(encodeHtml('a "b" c'), equals('a &quot;b&quot; c'));
    });

    test('encodes single quotes', () {
      expect(encodeHtml("a 'b' c"), equals('a &#39;b&#39; c'));
    });

    test('encodes all special characters together', () {
      expect(
        encodeHtml('<div class="test">A & B</div>'),
        equals('&lt;div class=&quot;test&quot;&gt;A &amp; B&lt;/div&gt;'),
      );
    });

    test('returns empty string unchanged', () {
      expect(encodeHtml(''), equals(''));
    });

    test('returns plain text unchanged', () {
      expect(encodeHtml('hello world'), equals('hello world'));
    });
  });

  group('decodeHtmlEntities', () {
    test('decodes &lt;', () {
      expect(decodeHtmlEntities('a &lt; b'), equals('a < b'));
    });

    test('decodes &gt;', () {
      expect(decodeHtmlEntities('a &gt; b'), equals('a > b'));
    });

    test('decodes &amp;', () {
      expect(decodeHtmlEntities('a &amp; b'), equals('a & b'));
    });

    test('decodes &quot;', () {
      expect(decodeHtmlEntities('a &quot;b&quot; c'), equals('a "b" c'));
    });

    test('decodes &#39;', () {
      expect(decodeHtmlEntities('a &#39;b&#39; c'), equals("a 'b' c"));
    });

    test('decodes all entities together', () {
      expect(
        decodeHtmlEntities('&lt;div&gt;A &amp; B&lt;/div&gt;'),
        equals('<div>A & B</div>'),
      );
    });

    test('returns empty string unchanged', () {
      expect(decodeHtmlEntities(''), equals(''));
    });
  });

  group('stripHtml', () {
    test('removes simple tags', () {
      expect(stripHtml('<p>Hello</p>'), equals('Hello'));
    });

    test('removes nested tags', () {
      expect(stripHtml('<div><span>Hello</span></div>'), equals('Hello'));
    });

    test('removes self-closing tags', () {
      expect(stripHtml('Hello<br/>World'), equals('HelloWorld'));
    });

    test('removes tags with attributes', () {
      expect(stripHtml('<a href="http://example.com">Link</a>'), equals('Link'));
    });

    test('handles multiple tags', () {
      expect(stripHtml('<h1>Title</h1><p>Content</p>'), equals('TitleContent'));
    });

    test('trims whitespace', () {
      expect(stripHtml('  <p>Hello</p>  '), equals('Hello'));
    });

    test('returns empty for empty input', () {
      expect(stripHtml(''), equals(''));
    });

    test('returns plain text unchanged', () {
      expect(stripHtml('no tags here'), equals('no tags here'));
    });
  });

  group('encodeHtmlAttribute', () {
    test('works same as encodeHtml', () {
      const input = '<script>alert("xss")</script>';
      expect(encodeHtmlAttribute(input), equals(encodeHtml(input)));
    });
  });

  group('encodeJsString', () {
    test('escapes quotes and backslashes', () {
      expect(encodeJsString("l'aide"), equals(r"l\'aide"));
      expect(encodeJsString(r'a\b'), equals(r'a\\b'));
      expect(encodeJsString('say "hi"'), equals(r'say \"hi\"'));
    });

    test('neutralizes </script> breakout', () {
      expect(encodeJsString('</script><script>alert(1)</script>'), isNot(contains('</script>')));
      expect(encodeJsString('</script>'), equals(r'\x3C/script>'));
    });

    test('escapes newlines and separators', () {
      expect(encodeJsString('a\nb\rc'), equals(r'a\nb\rc'));
      expect(encodeJsString('a\u2028b'), equals(r'a\u2028b'));
    });
  });

  group('encodeXml', () {
    test('escapes the five xml specials', () {
      expect(encodeXml('a&b<c>d"e\'f'), equals('a&amp;b&lt;c&gt;d&quot;e&apos;f'));
    });
  });

  group('isSafeUrl / sanitizeUrl', () {
    test('allows http, https, mailto, tel, and relative urls', () {
      expect(isSafeUrl('https://example.com'), isTrue);
      expect(isSafeUrl('http://example.com'), isTrue);
      expect(isSafeUrl('mailto:a@b.com'), isTrue);
      expect(isSafeUrl('tel:+123'), isTrue);
      expect(isSafeUrl('/docs/page'), isTrue);
      expect(isSafeUrl('#anchor'), isTrue);
      expect(isSafeUrl('../up'), isTrue);
      expect(isSafeUrl(''), isTrue);
    });

    test('rejects javascript, data, and vbscript schemes', () {
      expect(isSafeUrl('javascript:alert(1)'), isFalse);
      expect(isSafeUrl('JavaScript:alert(1)'), isFalse);
      expect(isSafeUrl(' javascript:alert(1)'), isFalse);
      expect(isSafeUrl('data:text/html,<script>'), isFalse);
      expect(isSafeUrl('vbscript:x'), isFalse);
    });

    test('sanitizeUrl empties unsafe urls and keeps safe ones', () {
      expect(sanitizeUrl('javascript:alert(1)'), equals(''));
      expect(sanitizeUrl('/docs'), equals('/docs'));
    });
  });

  group('sanitizeCssValue', () {
    test('keeps ordinary size values', () {
      expect(sanitizeCssValue('500px'), equals('500px'));
      expect(sanitizeCssValue('16/9'), equals('16/9'));
      expect(sanitizeCssValue('50%'), equals('50%'));
    });

    test('strips breakout characters', () {
      expect(sanitizeCssValue('red;} body{display:none'), isNot(contains(';')));
      expect(sanitizeCssValue('url(evil)'), isNot(contains('(')));
      expect(sanitizeCssValue('"><script>', fallback: '1rem'), equals('script'));
    });

    test('falls back when nothing survives', () {
      expect(sanitizeCssValue(';{}', fallback: '1rem'), equals('1rem'));
    });
  });
}
