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

  factory I18nConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const I18nConfig();

    final strings = I18nStrings.fromYaml(yaml['strings'] as Map?);
    return I18nConfig(
      enabled: yaml['enabled'] as bool? ?? false,
      defaultLocale: yaml['defaultLocale'] as String? ?? 'en',
      locales: (yaml['locales'] as List?)
              ?.map((entry) => LocaleConfig.fromYaml(entry as Map, stringFallback: strings))
              .toList() ??
          [],
      strings: strings,
    );
  }
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

  /// UI string overrides for this locale. Values omitted from YAML inherit the
  /// shared [I18nConfig.strings] values.
  final I18nStrings? strings;

  const LocaleConfig({
    required this.code,
    required this.label,
    this.dir = 'ltr',
    required this.path,
    this.source,
    this.sidebar,
    this.strings,
  });

  factory LocaleConfig.fromYaml(
    Map yaml, {
    I18nStrings stringFallback = const I18nStrings(),
  }) =>
      LocaleConfig(
        code: yaml['code'] as String,
        label: yaml['label'] as String,
        dir: yaml['dir'] as String? ?? 'ltr',
        path: yaml['path'] as String,
        source: yaml['source'] as String?,
        sidebar: (yaml['sidebar'] as List?)?.map((e) => SidebarGroup.fromYaml(e as Map)).toList(),
        strings: switch (yaml['strings']) {
          final Map strings => I18nStrings.fromYaml(strings, fallback: stringFallback),
          _ => null,
        },
      );
}

class I18nStrings {
  final String? searchPlaceholder;
  final String navPrevious;
  final String navNext;
  final String? tocTitle;
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
  final String codeCopy;
  final String codeCopyLabel;
  final String codeCopied;
  final String codeCopyFailed;
  final String localeSelect;
  final String localeUntranslated;
  final String pageCopyMarkdown;
  final String readingTime;
  final String lastUpdated;
  final String dartdocApi;
  final String dartdocBackToDocs;

  const I18nStrings({
    this.searchPlaceholder,
    this.navPrevious = '← Previous',
    this.navNext = 'Next →',
    this.tocTitle,
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
    this.codeCopy = 'Copy',
    this.codeCopyLabel = 'Copy code',
    this.codeCopied = 'Copied!',
    this.codeCopyFailed = 'Copy failed',
    this.localeSelect = 'Select language',
    this.localeUntranslated = 'This page has not been translated yet.',
    this.pageCopyMarkdown = 'Copy page as Markdown',
    this.readingTime = '%s min read',
    this.lastUpdated = 'Last updated %s',
    this.dartdocApi = 'API',
    this.dartdocBackToDocs = '← Back to docs',
  });

  static const _keyMap = {
    'search.placeholder': 'searchPlaceholder',
    'nav.previous': 'navPrevious',
    'nav.next': 'navNext',
    'toc.title': 'tocTitle',
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
    'code.copy': 'codeCopy',
    'code.copyLabel': 'codeCopyLabel',
    'code.copied': 'codeCopied',
    'code.copyFailed': 'codeCopyFailed',
    'locale.select': 'localeSelect',
    'locale.untranslated': 'localeUntranslated',
    'page.copyMarkdown': 'pageCopyMarkdown',
    'page.readingTime': 'readingTime',
    'page.lastUpdated': 'lastUpdated',
    'dartdoc.api': 'dartdocApi',
    'dartdoc.backToDocs': 'dartdocBackToDocs',
  };

  factory I18nStrings.fromYaml(
    Map? yaml, {
    I18nStrings fallback = const I18nStrings(),
  }) {
    if (yaml == null || yaml.isEmpty) return fallback;

    final overrides = <String, String>{};
    for (final entry in yaml.entries) {
      final field = _keyMap[entry.key as String];
      if (field != null) {
        overrides[field] = entry.value as String;
      }
    }

    return I18nStrings(
      searchPlaceholder: overrides['searchPlaceholder'] ?? fallback.searchPlaceholder,
      navPrevious: overrides['navPrevious'] ?? fallback.navPrevious,
      navNext: overrides['navNext'] ?? fallback.navNext,
      tocTitle: overrides['tocTitle'] ?? fallback.tocTitle,
      footerPoweredBy: overrides['footerPoweredBy'] ?? fallback.footerPoweredBy,
      themeToggle: overrides['themeToggle'] ?? fallback.themeToggle,
      menuToggle: overrides['menuToggle'] ?? fallback.menuToggle,
      menuClose: overrides['menuClose'] ?? fallback.menuClose,
      announcementDismiss: overrides['announcementDismiss'] ?? fallback.announcementDismiss,
      versionSelect: overrides['versionSelect'] ?? fallback.versionSelect,
      versionDismiss: overrides['versionDismiss'] ?? fallback.versionDismiss,
      searchNoResults: overrides['searchNoResults'] ?? fallback.searchNoResults,
      searchOneResult: overrides['searchOneResult'] ?? fallback.searchOneResult,
      searchManyResults: overrides['searchManyResults'] ?? fallback.searchManyResults,
      searchSearching: overrides['searchSearching'] ?? fallback.searchSearching,
      searchClear: overrides['searchClear'] ?? fallback.searchClear,
      searchMore: overrides['searchMore'] ?? fallback.searchMore,
      searchUnavailable: overrides['searchUnavailable'] ?? fallback.searchUnavailable,
      codeCopy: overrides['codeCopy'] ?? fallback.codeCopy,
      codeCopyLabel: overrides['codeCopyLabel'] ?? fallback.codeCopyLabel,
      codeCopied: overrides['codeCopied'] ?? fallback.codeCopied,
      codeCopyFailed: overrides['codeCopyFailed'] ?? fallback.codeCopyFailed,
      localeSelect: overrides['localeSelect'] ?? fallback.localeSelect,
      localeUntranslated: overrides['localeUntranslated'] ?? fallback.localeUntranslated,
      pageCopyMarkdown: overrides['pageCopyMarkdown'] ?? fallback.pageCopyMarkdown,
      readingTime: overrides['readingTime'] ?? fallback.readingTime,
      lastUpdated: overrides['lastUpdated'] ?? fallback.lastUpdated,
      dartdocApi: overrides['dartdocApi'] ?? fallback.dartdocApi,
      dartdocBackToDocs: overrides['dartdocBackToDocs'] ?? fallback.dartdocBackToDocs,
    );
  }
}
