import 'navigation_config.dart';
import 'version_source.dart';

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
  final VersionSource? source;

  /// Sidebar for this version, replacing the shared one. Set it when a version
  /// has pages the current sidebar no longer lists.
  final List<SidebarGroup>? sidebar;

  const VersionEntry({
    required this.version,
    this.label,
    required this.path,
    this.banner,
    this.source,
    this.sidebar,
  });

  factory VersionEntry.fromYaml(Map yaml) => VersionEntry(
        version: yaml['version'] as String,
        label: yaml['label'] as String?,
        path: yaml['path'] as String,
        banner: yaml['banner'] as String?,
        source: yaml['source'] == null ? null : VersionSource.fromYaml(yaml['source']),
        sidebar: (yaml['sidebar'] as List?)?.map((e) => SidebarGroup.fromYaml(e as Map)).toList(),
      );
}

class I18nConfig {
  final bool enabled;
  final String defaultLocale;
  final List<LocaleConfig> locales;
  final I18nStrings strings;

  const I18nConfig({
    this.enabled = false,
    this.defaultLocale = 'en',
    this.locales = const [],
    this.strings = const I18nStrings(),
  });

  factory I18nConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => I18nConfig(
            enabled: yaml['enabled'] as bool? ?? false,
            defaultLocale: yaml['defaultLocale'] as String? ?? 'en',
            locales: (yaml['locales'] as List?)?.map((e) => LocaleConfig.fromYaml(e as Map)).toList() ?? [],
            strings: I18nStrings.fromYaml(yaml['strings'] as Map?),
          ),
        _ => const I18nConfig(),
      };
}

class LocaleConfig {
  final String code;
  final String label;
  final String dir;
  final String path;

  /// Directory holding this locale's translations. Defaults to
  /// `<content.dir>/<code>`; untranslated pages fall back to the default locale.
  final String? source;

  /// Sidebar for this locale, replacing the shared one — used to translate group
  /// titles and page labels. Defaults to the shared sidebar.
  final List<SidebarGroup>? sidebar;

  const LocaleConfig({
    required this.code,
    required this.label,
    this.dir = 'ltr',
    required this.path,
    this.source,
    this.sidebar,
  });

  factory LocaleConfig.fromYaml(Map yaml) => LocaleConfig(
        code: yaml['code'] as String,
        label: yaml['label'] as String,
        dir: yaml['dir'] as String? ?? 'ltr',
        path: yaml['path'] as String,
        source: yaml['source'] as String?,
        sidebar: (yaml['sidebar'] as List?)?.map((e) => SidebarGroup.fromYaml(e as Map)).toList(),
      );
}

class I18nStrings {
  final String navPrevious;
  final String navNext;
  final String footerPoweredBy;
  final String themeToggle;
  final String menuToggle;
  final String menuClose;
  final String announcementDismiss;
  final String versionSelect;
  final String versionDismiss;
  final String searchNoResults;
  final String searchOneResult;
  final String searchManyResults;
  final String searchSearching;
  final String searchClear;
  final String searchMore;
  final String searchUnavailable;
  final String localeSelect;
  final String localeUntranslated;
  final String readingTime;
  final String lastUpdated;

  const I18nStrings({
    this.navPrevious = '← Previous',
    this.navNext = 'Next →',
    this.footerPoweredBy = 'Powered by',
    this.themeToggle = 'Toggle dark mode',
    this.menuToggle = 'Toggle menu',
    this.menuClose = 'Close menu',
    this.announcementDismiss = 'Dismiss announcement',
    this.versionSelect = 'Select version',
    this.versionDismiss = 'Dismiss banner',
    this.searchNoResults = 'No results found for "%s"',
    this.searchOneResult = '1 result',
    this.searchManyResults = '%s results',
    this.searchSearching = 'Searching...',
    this.searchClear = 'Clear search',
    this.searchMore = 'Load more results',
    this.searchUnavailable = 'Search is unavailable',
    this.localeSelect = 'Select language',
    this.localeUntranslated = 'This page has not been translated yet.',
    this.readingTime = '%s min read',
    this.lastUpdated = 'Last updated %s',
  });

  static const _keyMap = {
    'nav.previous': 'navPrevious',
    'nav.next': 'navNext',
    'footer.poweredBy': 'footerPoweredBy',
    'theme.toggle': 'themeToggle',
    'menu.toggle': 'menuToggle',
    'menu.close': 'menuClose',
    'announcement.dismiss': 'announcementDismiss',
    'version.select': 'versionSelect',
    'version.dismiss': 'versionDismiss',
    'search.noResults': 'searchNoResults',
    'search.oneResult': 'searchOneResult',
    'search.manyResults': 'searchManyResults',
    'search.searching': 'searchSearching',
    'search.clear': 'searchClear',
    'search.more': 'searchMore',
    'search.unavailable': 'searchUnavailable',
    'locale.select': 'localeSelect',
    'locale.untranslated': 'localeUntranslated',
    'page.readingTime': 'readingTime',
    'page.lastUpdated': 'lastUpdated',
  };

  factory I18nStrings.fromYaml(Map? yaml) {
    if (yaml == null || yaml.isEmpty) return const I18nStrings();

    final overrides = <String, String>{};
    for (final entry in yaml.entries) {
      final field = _keyMap[entry.key as String];
      if (field != null) {
        overrides[field] = entry.value as String;
      }
    }

    return I18nStrings(
      navPrevious: overrides['navPrevious'] ?? '← Previous',
      navNext: overrides['navNext'] ?? 'Next →',
      footerPoweredBy: overrides['footerPoweredBy'] ?? 'Powered by',
      themeToggle: overrides['themeToggle'] ?? 'Toggle dark mode',
      menuToggle: overrides['menuToggle'] ?? 'Toggle menu',
      menuClose: overrides['menuClose'] ?? 'Close menu',
      announcementDismiss: overrides['announcementDismiss'] ?? 'Dismiss announcement',
      versionSelect: overrides['versionSelect'] ?? 'Select version',
      versionDismiss: overrides['versionDismiss'] ?? 'Dismiss banner',
      searchNoResults: overrides['searchNoResults'] ?? 'No results found for "%s"',
      searchOneResult: overrides['searchOneResult'] ?? '1 result',
      searchManyResults: overrides['searchManyResults'] ?? '%s results',
      searchSearching: overrides['searchSearching'] ?? 'Searching...',
      searchClear: overrides['searchClear'] ?? 'Clear search',
      searchMore: overrides['searchMore'] ?? 'Load more results',
      searchUnavailable: overrides['searchUnavailable'] ?? 'Search is unavailable',
      localeSelect: overrides['localeSelect'] ?? 'Select language',
      localeUntranslated: overrides['localeUntranslated'] ?? 'This page has not been translated yet.',
      readingTime: overrides['readingTime'] ?? '%s min read',
      lastUpdated: overrides['lastUpdated'] ?? 'Last updated %s',
    );
  }
}
