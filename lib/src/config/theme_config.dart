class ThemeConfig {
  final ColorsConfig colors;
  final DarkModeConfig darkMode;
  final FontsConfig fonts;
  final String radius;
  final CustomThemeConfig? custom;

  /// Design-token overrides applied in `:root` (light) — keys are token names
  /// without the leading `--` (e.g. `color-border`), values are CSS values.
  final Map<String, String> tokens;

  /// Design-token overrides applied in `.dark`.
  final Map<String, String> tokensDark;

  /// Raw HTML injected into the header, footer, and sidebar regions.
  final SlotsConfig slots;

  const ThemeConfig({
    this.colors = const ColorsConfig(),
    this.darkMode = const DarkModeConfig(),
    this.fonts = const FontsConfig(),
    this.radius = '8px',
    this.custom,
    this.tokens = const {},
    this.tokensDark = const {},
    this.slots = const SlotsConfig(),
  });

  factory ThemeConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => ThemeConfig(
            colors: ColorsConfig.fromYaml(yaml['colors'] as Map?),
            darkMode: DarkModeConfig.fromYaml(yaml['darkMode'] as Map?),
            fonts: FontsConfig.fromYaml(yaml['fonts'] as Map?),
            radius: yaml['radius'] as String? ?? '8px',
            custom: switch (yaml['custom']) {
              final Map custom => CustomThemeConfig.fromYaml(custom),
              _ => null,
            },
            tokens: _tokens(yaml['tokens']),
            tokensDark: _tokens(yaml['tokensDark']),
            slots: SlotsConfig.fromYaml(yaml['slots'] as Map?),
          ),
        _ => const ThemeConfig(),
      };

  /// Reads a `{token: value}` map, keeping only safe token names so a value can
  /// never break out of the CSS declaration via the key.
  static Map<String, String> _tokens(Object? yaml) => switch (yaml) {
        final Map map => {
            for (final MapEntry(:key, :value) in map.entries)
              if (RegExp(r'^[a-z0-9-]+$').hasMatch('$key')) '$key': '$value',
          },
        _ => const {},
      };
}

/// Raw HTML injected at the end of the header, footer, and sidebar regions.
class SlotsConfig {
  final String? header;
  final String? footer;
  final String? sidebar;

  const SlotsConfig({this.header, this.footer, this.sidebar});

  factory SlotsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => SlotsConfig(
            header: yaml['header'] as String?,
            footer: yaml['footer'] as String?,
            sidebar: yaml['sidebar'] as String?,
          ),
        _ => const SlotsConfig(),
      };
}

class ColorsConfig {
  final String primary;
  final String? secondary;
  final String? accent;
  final BackgroundColors? background;
  final TextColors? text;

  const ColorsConfig({
    this.primary = '#6366f1',
    this.secondary,
    this.accent,
    this.background,
    this.text,
  });

  factory ColorsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => ColorsConfig(
            primary: yaml['primary'] as String? ?? '#6366f1',
            secondary: yaml['secondary'] as String?,
            accent: yaml['accent'] as String?,
            background: switch (yaml['background']) {
              final Map bg => BackgroundColors.fromYaml(bg),
              _ => null,
            },
            text: switch (yaml['text']) {
              final Map text => TextColors.fromYaml(text),
              _ => null,
            },
          ),
        _ => const ColorsConfig(),
      };
}

class BackgroundColors {
  final String light;
  final String dark;

  const BackgroundColors({this.light = '#ffffff', this.dark = '#0f172a'});

  factory BackgroundColors.fromYaml(Map yaml) => BackgroundColors(
        light: yaml['light'] as String? ?? '#ffffff',
        dark: yaml['dark'] as String? ?? '#0f172a',
      );
}

class TextColors {
  final String light;
  final String dark;

  const TextColors({this.light = '#1e293b', this.dark = '#e2e8f0'});

  factory TextColors.fromYaml(Map yaml) => TextColors(
        light: yaml['light'] as String? ?? '#1e293b',
        dark: yaml['dark'] as String? ?? '#e2e8f0',
      );
}

class DarkModeConfig {
  final bool enabled;
  final String defaultMode;

  const DarkModeConfig({this.enabled = true, this.defaultMode = 'system'});

  factory DarkModeConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => DarkModeConfig(
            enabled: yaml['enabled'] as bool? ?? true,
            defaultMode: yaml['default'] as String? ?? 'system',
          ),
        _ => const DarkModeConfig(),
      };
}

class FontsConfig {
  final String sans;
  final String mono;

  /// 'google' loads from Google Fonts; 'local' emits no font links so the
  /// site works air-gapped (supply @font-face via theme.custom).
  final String source;

  const FontsConfig({this.sans = 'Inter', this.mono = 'JetBrains Mono', this.source = 'google'});

  factory FontsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => FontsConfig(
            sans: yaml['sans'] as String? ?? 'Inter',
            mono: yaml['mono'] as String? ?? 'JetBrains Mono',
            source: yaml['source'] as String? ?? 'google',
          ),
        _ => const FontsConfig(),
      };
}

class CustomThemeConfig {
  final String? css;
  final String? cssFile;

  const CustomThemeConfig({this.css, this.cssFile});

  factory CustomThemeConfig.fromYaml(Map yaml) => CustomThemeConfig(
        css: yaml['css'] as String?,
        cssFile: yaml['cssFile'] as String?,
      );
}
