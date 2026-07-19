class CodeConfig {
  final CodeThemeConfig theme;
  final bool lineNumbers;
  final bool copyButton;
  final bool wrapLongLines;
  final String defaultLanguage;
  final Map<String, String> aliases;

  const CodeConfig({
    this.theme = const CodeThemeConfig(),
    this.lineNumbers = false,
    this.copyButton = true,
    this.wrapLongLines = false,
    this.defaultLanguage = 'plaintext',
    this.aliases = const {},
  });

  factory CodeConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => CodeConfig(
            theme: CodeThemeConfig.fromYaml(yaml['theme']),
            lineNumbers: yaml['lineNumbers'] as bool? ?? false,
            copyButton: yaml['copyButton'] as bool? ?? true,
            wrapLongLines: yaml['wrapLongLines'] as bool? ?? false,
            defaultLanguage: yaml['defaultLanguage'] as String? ?? 'plaintext',
            aliases: (yaml['aliases'] as Map?)?.cast<String, String>() ?? const {},
          ),
        _ => const CodeConfig(),
      };
}

class CodeThemeConfig {
  final String light;
  final String dark;

  const CodeThemeConfig({this.light = 'github-light', this.dark = 'github-dark'});

  factory CodeThemeConfig.fromYaml(dynamic yaml) => switch (yaml) {
        final String theme => CodeThemeConfig(light: theme, dark: theme),
        final Map yaml => CodeThemeConfig(
            light: yaml['light'] as String? ?? 'github-light',
            dark: yaml['dark'] as String? ?? 'github-dark',
          ),
        _ => const CodeThemeConfig(),
      };
}

class ComponentsConfig {
  static const defaultMermaidScriptUrl = 'https://cdn.jsdelivr.net/npm/mermaid@10.9.6/dist/mermaid.min.js';

  final Map<String, CalloutConfig> callouts;

  /// Where the Mermaid renderer is loaded from; point at a self-hosted copy
  /// (e.g. /vendor/mermaid.min.js in public/) for air-gapped sites.
  final String mermaidScriptUrl;

  const ComponentsConfig({
    this.callouts = const {
      'info': CalloutConfig(icon: 'ℹ️', color: '#3b82f6'),
      'warning': CalloutConfig(icon: '⚠️', color: '#f59e0b'),
      'danger': CalloutConfig(icon: '🚨', color: '#ef4444'),
      'tip': CalloutConfig(icon: '💡', color: '#22c55e'),
      'note': CalloutConfig(icon: '📝', color: '#8b5cf6'),
    },
    this.mermaidScriptUrl = defaultMermaidScriptUrl,
  });

  factory ComponentsConfig.fromYaml(Map? yaml) {
    final mermaidScriptUrl = switch (yaml?['mermaid']) {
      {'scriptUrl': final String url} => url,
      _ => defaultMermaidScriptUrl,
    };
    return switch (yaml?['callouts']) {
      null => ComponentsConfig(mermaidScriptUrl: mermaidScriptUrl),
      final Map calloutsYaml => ComponentsConfig(
          mermaidScriptUrl: mermaidScriptUrl,
          callouts: calloutsYaml.map(
            (key, value) => MapEntry(key as String, CalloutConfig.fromYaml(value as Map)),
          ),
        ),
      _ => ComponentsConfig(mermaidScriptUrl: mermaidScriptUrl),
    };
  }
}

class CalloutConfig {
  final String icon;
  final String color;

  const CalloutConfig({required this.icon, required this.color});

  factory CalloutConfig.fromYaml(Map yaml) => CalloutConfig(
        icon: yaml['icon'] as String,
        color: yaml['color'] as String,
      );
}
