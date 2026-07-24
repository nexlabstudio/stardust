import '../../config/config.dart';
import 'stardust_css.dart';

/// Builds CSS styles and font imports for pages
class PageStylesBuilder {
  final StardustConfig config;

  /// Pre-resolved CSS file content, set externally before building
  String? resolvedCssFileContent;

  PageStylesBuilder({required this.config});

  String buildFonts() {
    if (config.theme.fonts.source == 'local') return '';
    final sans = config.theme.fonts.sans;
    final mono = config.theme.fonts.mono;

    return '''
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=${sans.replaceAll(' ', '+')}:wght@400;500;600;700&family=${mono.replaceAll(' ', '+')}:wght@400;500&display=swap" rel="stylesheet">
''';
  }

  String buildStyles() => '''
  <style>
${buildCss()}
  </style>
''';

  /// The site's full stylesheet, written once per build to assets/styles.css.
  String buildCss() {
    final primary = config.theme.colors.primary;
    final bgLight = config.theme.colors.background?.light ?? '#ffffff';
    final bgDark = config.theme.colors.background?.dark ?? '#0f172a';
    final textLight = config.theme.colors.text?.light ?? '#1e293b';
    final textDark = config.theme.colors.text?.dark ?? '#e2e8f0';
    final sans = config.theme.fonts.sans;
    final mono = config.theme.fonts.mono;
    final radius = config.theme.radius;

    return '''
    :root {
      --color-primary: $primary;
      --color-bg: $bgLight;
      --color-bg-secondary: #f8fafc;
      --color-text: $textLight;
      --color-text-secondary: #64748b;
      --color-border: #e2e8f0;
      --font-sans: '$sans', system-ui, sans-serif;
      --font-mono: '$mono', monospace;
      --radius: $radius;
    }

    .dark {
      --color-bg: $bgDark;
      --color-bg-secondary: #1e293b;
      --color-text: $textDark;
      --color-text-secondary: #94a3b8;
      --color-border: #334155;
    }

${_section('base')}
${_section('announcement')}
${_section('dropdowns')}
${_section('rtl')}
${_section('header')}
${_section('search')}
${_section('layout')}
${_section('prose')}
${_section('code')}
${_section('component')}
${_section('toc')}
${_section('navigation')}
${_section('footer')}
${_section('social')}
${_section('syntax-highlighting')}
${_section('responsive')}
${_section('landing')}
${_buildCustomStyles()}
''';
  }

  String _section(String key) => stardustCssSections[key] ?? '';

  String _buildCustomStyles() {
    final custom = config.theme.custom;
    if (custom == null) return '';

    final buffer = StringBuffer();

    if (resolvedCssFileContent case final String content when content.isNotEmpty) {
      buffer.write(content);
    }

    if (custom.css case final String css when css.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(css);
    }

    if (buffer.isEmpty) return '';
    return '\n    /* Custom styles */\n    $buffer';
  }
}
