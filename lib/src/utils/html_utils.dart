import 'patterns.dart';

/// Encodes special HTML characters to their entity equivalents.
///
/// Converts: & < > " '
String encodeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Decodes HTML entities back to their character equivalents.
///
/// Converts: &amp; &lt; &gt; &quot; &#39;
String decodeHtmlEntities(String text) => text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");

/// Strips all HTML tags from text.
String stripHtml(String html) => html.replaceAll(htmlTagPattern, '').trim();

/// Encodes text for safe use in HTML attributes.
///
/// Same as [encodeHtml] but explicitly named for attribute context.
String encodeHtmlAttribute(String text) => encodeHtml(text);

/// Encodes text for safe embedding inside a quoted JavaScript string literal.
///
/// `<` becomes `\x3C` so `</script>` in data can never terminate the script element.
String encodeJsString(String text) => text
    .replaceAll('\\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll('"', r'\"')
    .replaceAll('<', r'\x3C')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r')
    .replaceAll('\u2028', r'\u2028')
    .replaceAll('\u2029', r'\u2029');

/// Encodes text for safe use in XML content and attributes.
String encodeXml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// Whether [url] is safe to emit as a link or media target.
///
/// Allows http(s), mailto, tel, and site-relative/anchor/protocol-relative
/// URLs; rejects everything else (javascript:, data:, vbscript:, ...).
bool isSafeUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return true;
  return switch (Uri.tryParse(trimmed)) {
    Uri(scheme: 'http' || 'https' || 'mailto' || 'tel') => true,
    Uri(:final scheme) when scheme.isEmpty => true,
    _ => false,
  };
}

/// Returns [url] when [isSafeUrl], otherwise an empty string.
String sanitizeUrl(String url) => isSafeUrl(url) ? url : '';

/// Strips characters that could break out of an inline `style` declaration.
String sanitizeCssValue(String value, {String fallback = ''}) {
  final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9./%\s-]'), '').trim();
  return cleaned.isEmpty ? fallback : cleaned;
}
