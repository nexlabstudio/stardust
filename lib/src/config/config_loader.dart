import 'dart:io';
import 'package:yaml/yaml.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'config.dart';
import 'schema_validator.dart';

/// Loads and parses Stardust configuration from YAML files
class ConfigLoader {
  /// Load configuration from a YAML file
  static Future<StardustConfig> load(String path, {Logger logger = const Logger()}) async {
    final String content;
    try {
      content = await File(path).readAsString();
    } on FileSystemException catch (e) {
      throw ConfigException('Cannot read config file "$path": ${e.osError?.message ?? e.message}');
    }

    final Object? yaml;
    try {
      yaml = loadYaml(content);
    } on YamlException catch (e) {
      throw ConfigException('Invalid YAML in "$path": ${e.message}');
    }

    if (yaml case final Map yaml) return parse(yaml, logger: logger);
    throw ConfigException('Invalid config file: $path — expected a YAML mapping');
  }

  /// Parse configuration from a YAML map
  static StardustConfig parse(Map yaml, {Logger logger = const Logger()}) {
    final issues = SchemaValidator().validate(yaml);
    for (final warning in issues.where((issue) => issue.isWarning)) {
      logger.error('⚠️  $warning');
    }
    final errors = issues.where((issue) => !issue.isWarning).toList();
    if (errors.isNotEmpty) {
      throw ConfigException('Invalid configuration:\n${errors.map((error) => '  • $error').join('\n')}');
    }

    final name = yaml['name'] as String?;
    if (name == null || name.isEmpty) {
      throw const ConfigException('Config must have a "name" field');
    }

    final search = SearchConfig.fromYaml(yaml['search'] as Map?);
    if (search.provider != 'pagefind') {
      throw ConfigException('search.provider "${search.provider}" is not supported — only "pagefind" is available');
    }

    final config = StardustConfig(
      name: name,
      description: yaml['description'] as String?,
      tagline: yaml['tagline'] as String?,
      logo: yaml['logo'] != null ? LogoConfig.fromYaml(yaml['logo']) : null,
      favicon: yaml['favicon'] as String?,
      url: yaml['url'] as String?,
      content: ContentConfig.fromYaml(yaml['content'] as Map?),
      nav: (yaml['nav'] as List?)?.map((e) => NavItem.fromYaml(e as Map)).toList() ?? [],
      sidebar: (yaml['sidebar'] as List?)?.map((e) => SidebarGroup.fromYaml(e as Map)).toList() ?? [],
      toc: TocConfig.fromYaml(yaml['toc'] as Map?),
      theme: ThemeConfig.fromYaml(yaml['theme'] as Map?),
      code: CodeConfig.fromYaml(yaml['code'] as Map?),
      components: ComponentsConfig.fromYaml(yaml['components'] as Map?),
      search: search,
      seo: SeoConfig.fromYaml(yaml['seo'] as Map?),
      social: SocialConfig.fromYaml(yaml['social'] as Map?),
      header: HeaderConfig.fromYaml(yaml['header'] as Map?),
      footer: FooterConfig.fromYaml(yaml['footer'] as Map?),
      pageInfo: PageInfoConfig.fromYaml(yaml['pageInfo'] as Map?),
      versions: yaml['versions'] != null ? VersionsConfig.fromYaml(yaml['versions'] as Map) : null,
      i18n: yaml['i18n'] != null ? I18nConfig.fromYaml(yaml['i18n'] as Map) : null,
      integrations: IntegrationsConfig.fromYaml(yaml['integrations'] as Map?),
      build: BuildConfig.fromYaml(yaml['build'] as Map?),
      dev: DevConfig.fromYaml(yaml['dev'] as Map?),
    );

    _validateCrossReferences(config, logger);
    return config;
  }

  static void _validateCrossReferences(StardustConfig config, Logger logger) {
    if (config.i18n case final i18n? when i18n.locales.isNotEmpty) {
      if (!i18n.locales.any((locale) => locale.code == i18n.defaultLocale)) {
        throw ConfigException('i18n.defaultLocale "${i18n.defaultLocale}" is not defined in i18n.locales');
      }
    }
    if (config.versions case final versions? when versions.enabled && versions.list.isNotEmpty) {
      if (versions.current case final current? when !versions.list.any((entry) => entry.version == current)) {
        logger.error('⚠️  versions.current "$current" does not match any entry in versions.list');
      }
    }
  }
}
