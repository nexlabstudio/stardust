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
String stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

/// Encodes text for safe use in HTML attributes.
///
/// Same as [encodeHtml] but explicitly named for attribute context.
String encodeHtmlAttribute(String text) => encodeHtml(text);
