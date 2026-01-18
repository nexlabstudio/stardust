import 'dart:io';
import 'package:yaml/yaml.dart';
import 'config.dart';

/// Loads and parses Stardust configuration from YAML files
class ConfigLoader {
  /// Load configuration from a YAML file
  static Future<StardustConfig> load(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    final yaml = loadYaml(content) as Map?;

    if (yaml == null) {
      throw ConfigException('Invalid config file: $path');
    }

    return parse(yaml);
  }

  /// Parse configuration from a YAML map
  static StardustConfig parse(Map yaml) {
    final name = yaml['name'] as String?;
    if (name == null || name.isEmpty) {
      throw ConfigException('Config must have a "name" field');
    }

    return StardustConfig(
      name: name,
      description: yaml['description'] as String?,
      tagline: yaml['tagline'] as String?,
      logo: yaml['logo'] != null ? LogoConfig.fromYaml(yaml['logo']) : null,
      favicon: yaml['favicon'] as String?,
      url: yaml['url'] as String?,
      content: ContentConfig.fromYaml(yaml['content'] as Map?),
      nav: (yaml['nav'] as List?)
              ?.map((e) => NavItem.fromYaml(e as Map))
              .toList() ??
          [],
      sidebar: (yaml['sidebar'] as List?)
              ?.map((e) => SidebarGroup.fromYaml(e as Map))
              .toList() ??
          [],
      toc: TocConfig.fromYaml(yaml['toc'] as Map?),
      theme: ThemeConfig.fromYaml(yaml['theme'] as Map?),
      code: CodeConfig.fromYaml(yaml['code'] as Map?),
      components: ComponentsConfig.fromYaml(yaml['components'] as Map?),
      search: SearchConfig.fromYaml(yaml['search'] as Map?),
      seo: SeoConfig.fromYaml(yaml['seo'] as Map?),
      social: SocialConfig.fromYaml(yaml['social'] as Map?),
      header: HeaderConfig.fromYaml(yaml['header'] as Map?),
      footer: FooterConfig.fromYaml(yaml['footer'] as Map?),
      versions: yaml['versions'] != null
          ? VersionsConfig.fromYaml(yaml['versions'] as Map)
          : null,
      i18n: yaml['i18n'] != null
          ? I18nConfig.fromYaml(yaml['i18n'] as Map)
          : null,
      integrations: IntegrationsConfig.fromYaml(yaml['integrations'] as Map?),
      build: BuildConfig.fromYaml(yaml['build'] as Map?),
      dev: DevConfig.fromYaml(yaml['dev'] as Map?),
    );
  }
}

/// Exception thrown when configuration is invalid
class ConfigException implements Exception {
  final String message;

  ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}
