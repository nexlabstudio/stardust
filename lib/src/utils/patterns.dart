library;

final htmlTagPattern = RegExp(r'<[^>]*>');
final codeBlockPattern = RegExp(r'<pre><code class="language-(\w+)">([\s\S]*?)</code></pre>');
final headingPattern = RegExp(r'<h([1-6])[^>]*id="([^"]+)"[^>]*>(.*?)</h\1>', dotAll: true);

final fencedCodeBlockPattern = RegExp(
  r'(`{3,}|~{3,})(\w*)\n([\s\S]*?)\1',
  multiLine: true,
);

final attributePattern = RegExp(
  r'''(\w+)(?:=(?:"([^"]*)"|'([^']*)'|\{([^}]*)\}))?''',
);

final emojiPattern = RegExp(
  r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]',
  unicode: true,
);

final youtubePatterns = [
  RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
  RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
  RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
  RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]+)'),
];

final vimeoPattern = RegExp(r'vimeo\.com/(?:video/)?(\d+)');

final bracesPattern = RegExp(r'[{}]');
final leadingTrailingDashPattern = RegExp(r'^-|-$');
final multipleDashPattern = RegExp(r'-+');
final nonAlphanumericPattern = RegExp(r'[^a-z0-9]+');

final _selfClosingCache = <String, RegExp>{};
final _openCloseCache = <String, RegExp>{};

RegExp selfClosingComponentPattern(String tagName) => _selfClosingCache.putIfAbsent(
      tagName,
      () => RegExp(
        '<$tagName([^>]*?)/>',
        dotAll: true,
      ),
    );

RegExp openCloseComponentPattern(String tagName) => _openCloseCache.putIfAbsent(
      tagName,
      () => RegExp(
        '<$tagName([^>]*)>([\\s\\S]*?)</$tagName>',
        dotAll: true,
      ),
    );

RegExp childComponentPattern(String componentName) => RegExp(
      '<$componentName([^>]*)>([\\s\\S]*?)</$componentName>',
      dotAll: true,
    );
