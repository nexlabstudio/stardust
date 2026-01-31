class ThemeConfig {
  final ColorsConfig colors;
  final DarkModeConfig darkMode;
  final FontsConfig fonts;
  final String radius;
  final CustomThemeConfig? custom;

  const ThemeConfig({
    this.colors = const ColorsConfig(),
    this.darkMode = const DarkModeConfig(),
    this.fonts = const FontsConfig(),
    this.radius = '8px',
    this.custom,
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
          ),
        _ => const ThemeConfig(),
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

  const FontsConfig({this.sans = 'Inter', this.mono = 'JetBrains Mono'});

  factory FontsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => FontsConfig(
            sans: yaml['sans'] as String? ?? 'Inter',
            mono: yaml['mono'] as String? ?? 'JetBrains Mono',
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
