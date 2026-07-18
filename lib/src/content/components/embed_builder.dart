import '../../utils/html_utils.dart';
import '../../utils/patterns.dart';
import 'base_component.dart';

/// Builds embed components: YouTube, Vimeo, Zapp, CodePen, StackBlitz
class EmbedBuilder extends ComponentBuilder {
  @override
  List<String> get tagNames => ['YouTube', 'Vimeo', 'Zapp', 'CodePen', 'StackBlitz'];

  @override
  String build(String tagName, Map<String, String> attributes, String content) => switch (tagName) {
        'YouTube' => _buildYouTube(attributes, content),
        'Vimeo' => _buildVimeo(attributes, content),
        'Zapp' => _buildZapp(attributes, content),
        'CodePen' => _buildCodePen(attributes, content),
        'StackBlitz' => _buildStackBlitz(attributes, content),
        _ => content
      };

  String _buildYouTube(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final title = attributes['title'] ?? 'YouTube video';
    final start = attributes['start'];
    final aspectRatio = attributes['aspectRatio'] ?? '16/9';

    if (id.isEmpty) {
      return '<div class="embed-error">YouTube: Missing video ID</div>';
    }

    final videoId = _extractYouTubeId(id);
    if (!youtubeIdPattern.hasMatch(videoId)) {
      return '<div class="embed-error">YouTube: Invalid video ID</div>';
    }

    var embedUrl = 'https://www.youtube.com/embed/$videoId';
    if (start case final start?) {
      embedUrl += '?start=${Uri.encodeQueryComponent(start)}';
    }

    return '''
<div class="embed embed-youtube" style="aspect-ratio: ${sanitizeCssValue(aspectRatio, fallback: '16/9')}">
  <iframe
    src="${encodeHtmlAttribute(embedUrl)}"
    title="${encodeHtmlAttribute(title)}"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _extractYouTubeId(String input) {
    if (!input.contains('/') && !input.contains('.')) {
      return input;
    }

    for (final pattern in youtubePatterns) {
      if (pattern.firstMatch(input)?.group(1) case final id?) {
        return id;
      }
    }

    return input;
  }

  String _buildVimeo(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final title = attributes['title'] ?? 'Vimeo video';
    final aspectRatio = attributes['aspectRatio'] ?? '16/9';

    if (id.isEmpty) {
      return '<div class="embed-error">Vimeo: Missing video ID</div>';
    }

    final videoId = _extractVimeoId(id);
    if (!vimeoIdPattern.hasMatch(videoId)) {
      return '<div class="embed-error">Vimeo: Invalid video ID</div>';
    }

    return '''
<div class="embed embed-vimeo" style="aspect-ratio: ${sanitizeCssValue(aspectRatio, fallback: '16/9')}">
  <iframe
    src="https://player.vimeo.com/video/$videoId"
    title="${encodeHtmlAttribute(title)}"
    frameborder="0"
    allow="autoplay; fullscreen; picture-in-picture"
    allowfullscreen
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _extractVimeoId(String input) {
    if (!input.contains('/') && !input.contains('.')) {
      return input;
    }

    if (vimeoPattern.firstMatch(input)?.group(1) case final id?) {
      return id;
    }

    return input;
  }

  String _buildZapp(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final theme = attributes['theme'] ?? 'dark';
    final lazy = attributes['lazy'] != 'false';
    final height = attributes['height'] ?? '500px';

    if (id.isEmpty) {
      return '<div class="embed-error">Zapp: Missing project ID</div>';
    }

    final embedUrl =
        'https://zapp.run/edit/${Uri.encodeComponent(id)}?theme=${Uri.encodeQueryComponent(theme)}&lazy=$lazy';

    return '''
<div class="embed embed-zapp" style="height: ${sanitizeCssValue(height, fallback: '500px')}">
  <iframe
    src="${encodeHtmlAttribute(embedUrl)}"
    title="Zapp Dart/Flutter Playground"
    frameborder="0"
    allow="clipboard-write"
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _buildCodePen(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? '';
    final user = attributes['user'] ?? '';
    final title = attributes['title'] ?? 'CodePen';
    final height = int.tryParse(attributes['height'] ?? '') ?? 400;
    final defaultTab = attributes['defaultTab'] ?? 'result';
    final theme = attributes['theme'] ?? 'dark';
    final editable = attributes['editable'] == 'true';

    if (id.isEmpty || user.isEmpty) {
      return '<div class="embed-error">CodePen: Missing user or pen ID</div>';
    }

    final editableParam = editable ? '&editable=true' : '';
    final embedUrl = 'https://codepen.io/${Uri.encodeComponent(user)}/embed/${Uri.encodeComponent(id)}'
        '?default-tab=${Uri.encodeQueryComponent(defaultTab)}&theme-id=${Uri.encodeQueryComponent(theme)}$editableParam';

    return '''
<div class="embed embed-codepen" style="height: ${height}px">
  <iframe
    src="${encodeHtmlAttribute(embedUrl)}"
    title="${encodeHtmlAttribute(title)}"
    frameborder="0"
    allowtransparency="true"
    allowfullscreen="true"
    loading="lazy"
  ></iframe>
</div>
''';
  }

  String _buildStackBlitz(Map<String, String> attributes, String content) {
    final id = attributes['id'] ?? content.trim();
    final title = attributes['title'] ?? 'StackBlitz';
    final height = attributes['height'] ?? '500px';
    final file = attributes['file'];
    final embed = attributes['embed'] ?? '1';
    final hideNavigation = attributes['hideNavigation'] == 'true' ? '1' : '0';
    final hideDevTools = attributes['hideDevTools'] == 'true' ? '1' : '0';
    final view = attributes['view'] ?? 'preview';

    if (id.isEmpty) {
      return '<div class="embed-error">StackBlitz: Missing project ID</div>';
    }

    var embedUrl = 'https://stackblitz.com/edit/${Uri.encodeComponent(id)}'
        '?embed=${Uri.encodeQueryComponent(embed)}&hideNavigation=$hideNavigation'
        '&hideDevtools=$hideDevTools&view=${Uri.encodeQueryComponent(view)}';
    if (file case final file?) {
      embedUrl += '&file=${Uri.encodeQueryComponent(file)}';
    }

    return '''
<div class="embed embed-stackblitz" style="height: ${sanitizeCssValue(height, fallback: '500px')}">
  <iframe
    src="${encodeHtmlAttribute(embedUrl)}"
    title="${encodeHtmlAttribute(title)}"
    frameborder="0"
    allow="accelerometer; ambient-light-sensor; camera; encrypted-media; geolocation; gyroscope; hid; microphone; midi; payment; usb; vr; xr-spatial-tracking"
    sandbox="allow-forms allow-modals allow-popups allow-presentation allow-same-origin allow-scripts"
    loading="lazy"
  ></iframe>
</div>
''';
  }
}
