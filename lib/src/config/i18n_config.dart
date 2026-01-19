class VersionsConfig {
  final bool enabled;
  final String? current;
  final String? defaultVersion;
  final bool dropdown;
  final List<VersionEntry> list;

  const VersionsConfig({
    this.enabled = false,
    this.current,
    this.defaultVersion,
    this.dropdown = true,
    this.list = const [],
  });

  factory VersionsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => VersionsConfig(
            enabled: yaml['enabled'] as bool? ?? false,
            current: yaml['current'] as String?,
            defaultVersion: yaml['default'] as String?,
            dropdown: yaml['dropdown'] as bool? ?? true,
            list: (yaml['list'] as List?)?.map((e) => VersionEntry.fromYaml(e as Map)).toList() ?? [],
          ),
        _ => const VersionsConfig(),
      };
}

class VersionEntry {
  final String version;
  final String? label;
  final String path;
  final String? banner;

  const VersionEntry({required this.version, this.label, required this.path, this.banner});

  factory VersionEntry.fromYaml(Map yaml) => VersionEntry(
        version: yaml['version'] as String,
        label: yaml['label'] as String?,
        path: yaml['path'] as String,
        banner: yaml['banner'] as String?,
      );
}

class I18nConfig {
  final bool enabled;
  final String defaultLocale;
  final List<LocaleConfig> locales;

  const I18nConfig({this.enabled = false, this.defaultLocale = 'en', this.locales = const []});

  factory I18nConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => I18nConfig(
            enabled: yaml['enabled'] as bool? ?? false,
            defaultLocale: yaml['defaultLocale'] as String? ?? 'en',
            locales: (yaml['locales'] as List?)?.map((e) => LocaleConfig.fromYaml(e as Map)).toList() ?? [],
          ),
        _ => const I18nConfig(),
      };
}

class LocaleConfig {
  final String code;
  final String label;
  final String dir;

  const LocaleConfig({required this.code, required this.label, this.dir = 'ltr'});

  factory LocaleConfig.fromYaml(Map yaml) => LocaleConfig(
        code: yaml['code'] as String,
        label: yaml['label'] as String,
        dir: yaml['dir'] as String? ?? 'ltr',
      );
}
