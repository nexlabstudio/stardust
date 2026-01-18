/// Stardust configuration model
class StardustConfig {
  final String name;
  final String? description;
  final String? tagline;
  final LogoConfig? logo;
  final String? favicon;
  final String? url;
  final ContentConfig content;
  final List<NavItem> nav;
  final List<SidebarGroup> sidebar;
  final TocConfig toc;
  final ThemeConfig theme;
  final CodeConfig code;
  final ComponentsConfig components;
  final SearchConfig search;
  final SeoConfig seo;
  final SocialConfig social;
  final HeaderConfig header;
  final FooterConfig footer;
  final VersionsConfig? versions;
  final I18nConfig? i18n;
  final IntegrationsConfig integrations;
  final BuildConfig build;
  final DevConfig dev;

  const StardustConfig({
    required this.name,
    this.description,
    this.tagline,
    this.logo,
    this.favicon,
    this.url,
    this.content = const ContentConfig(),
    this.nav = const [],
    this.sidebar = const [],
    this.toc = const TocConfig(),
    this.theme = const ThemeConfig(),
    this.code = const CodeConfig(),
    this.components = const ComponentsConfig(),
    this.search = const SearchConfig(),
    this.seo = const SeoConfig(),
    this.social = const SocialConfig(),
    this.header = const HeaderConfig(),
    this.footer = const FooterConfig(),
    this.versions,
    this.i18n,
    this.integrations = const IntegrationsConfig(),
    this.build = const BuildConfig(),
    this.dev = const DevConfig(),
  });
}

class LogoConfig {
  final String? light;
  final String? dark;
  final String? single;

  const LogoConfig({this.light, this.dark, this.single});

  factory LogoConfig.fromYaml(dynamic yaml) {
    if (yaml is String) {
      return LogoConfig(single: yaml);
    }
    if (yaml is Map) {
      return LogoConfig(
        light: yaml['light'] as String?,
        dark: yaml['dark'] as String?,
      );
    }
    return const LogoConfig();
  }

  String? get effectiveLight => light ?? single;
  String? get effectiveDark => dark ?? single;
}

class ContentConfig {
  final String dir;
  final String index;
  final List<String> include;
  final List<String> exclude;

  const ContentConfig({
    this.dir = 'docs/',
    this.index = 'index.md',
    this.include = const ['*.md', '**/*.md', '*.mdx', '**/*.mdx'],
    this.exclude = const [],
  });

  factory ContentConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const ContentConfig();
    return ContentConfig(
      dir: yaml['dir'] as String? ?? 'docs/',
      index: yaml['index'] as String? ?? 'index.md',
      include: (yaml['include'] as List?)?.cast<String>() ??
          const ['*.md', '**/*.md', '*.mdx', '**/*.mdx'],
      exclude: (yaml['exclude'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class NavItem {
  final String label;
  final String href;
  final bool external;
  final String? icon;

  const NavItem({
    required this.label,
    required this.href,
    this.external = false,
    this.icon,
  });

  factory NavItem.fromYaml(Map yaml) => NavItem(
        label: yaml['label'] as String,
        href: yaml['href'] as String,
        external: yaml['external'] as bool? ?? false,
        icon: yaml['icon'] as String?,
      );
}

class SidebarGroup {
  final String group;
  final String? icon;
  final bool collapsed;
  final List<SidebarPage> pages;
  final AutogenerateConfig? autogenerate;

  const SidebarGroup({
    required this.group,
    this.icon,
    this.collapsed = false,
    this.pages = const [],
    this.autogenerate,
  });

  factory SidebarGroup.fromYaml(Map yaml) => SidebarGroup(
        group: yaml['group'] as String,
        icon: yaml['icon'] as String?,
        collapsed: yaml['collapsed'] as bool? ?? false,
        pages:
            (yaml['pages'] as List?)?.map(SidebarPage.fromYaml).toList() ?? [],
        autogenerate: yaml['autogenerate'] != null
            ? AutogenerateConfig.fromYaml(yaml['autogenerate'] as Map)
            : null,
      );
}

class SidebarPage {
  final String slug;
  final String? label;
  final String? icon;

  const SidebarPage({
    required this.slug,
    this.label,
    this.icon,
  });

  factory SidebarPage.fromYaml(dynamic yaml) {
    if (yaml is String) {
      return SidebarPage(slug: yaml);
    }
    if (yaml is Map) {
      return SidebarPage(
        slug: yaml['slug'] as String,
        label: yaml['label'] as String?,
        icon: yaml['icon'] as String?,
      );
    }
    throw ArgumentError('Invalid sidebar page: $yaml');
  }
}

class AutogenerateConfig {
  final String dir;
  final String order;

  const AutogenerateConfig({
    required this.dir,
    this.order = 'filename',
  });

  factory AutogenerateConfig.fromYaml(Map yaml) => AutogenerateConfig(
        dir: yaml['dir'] as String,
        order: yaml['order'] as String? ?? 'filename',
      );
}

class TocConfig {
  final bool enabled;
  final int minDepth;
  final int maxDepth;
  final String title;

  const TocConfig({
    this.enabled = true,
    this.minDepth = 2,
    this.maxDepth = 4,
    this.title = 'On this page',
  });

  factory TocConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const TocConfig();
    return TocConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      minDepth: yaml['minDepth'] as int? ?? 2,
      maxDepth: yaml['maxDepth'] as int? ?? 4,
      title: yaml['title'] as String? ?? 'On this page',
    );
  }
}

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

  factory ThemeConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const ThemeConfig();
    return ThemeConfig(
      colors: ColorsConfig.fromYaml(yaml['colors'] as Map?),
      darkMode: DarkModeConfig.fromYaml(yaml['darkMode'] as Map?),
      fonts: FontsConfig.fromYaml(yaml['fonts'] as Map?),
      radius: yaml['radius'] as String? ?? '8px',
      custom: yaml['custom'] != null
          ? CustomThemeConfig.fromYaml(yaml['custom'] as Map)
          : null,
    );
  }
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

  factory ColorsConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const ColorsConfig();
    return ColorsConfig(
      primary: yaml['primary'] as String? ?? '#6366f1',
      secondary: yaml['secondary'] as String?,
      accent: yaml['accent'] as String?,
      background: yaml['background'] != null
          ? BackgroundColors.fromYaml(yaml['background'] as Map)
          : null,
      text: yaml['text'] != null
          ? TextColors.fromYaml(yaml['text'] as Map)
          : null,
    );
  }
}

class BackgroundColors {
  final String light;
  final String dark;

  const BackgroundColors({
    this.light = '#ffffff',
    this.dark = '#0f172a',
  });

  factory BackgroundColors.fromYaml(Map yaml) => BackgroundColors(
        light: yaml['light'] as String? ?? '#ffffff',
        dark: yaml['dark'] as String? ?? '#0f172a',
      );
}

class TextColors {
  final String light;
  final String dark;

  const TextColors({
    this.light = '#1e293b',
    this.dark = '#e2e8f0',
  });

  factory TextColors.fromYaml(Map yaml) => TextColors(
        light: yaml['light'] as String? ?? '#1e293b',
        dark: yaml['dark'] as String? ?? '#e2e8f0',
      );
}

class DarkModeConfig {
  final bool enabled;
  final String defaultMode;

  const DarkModeConfig({
    this.enabled = true,
    this.defaultMode = 'system',
  });

  factory DarkModeConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const DarkModeConfig();
    return DarkModeConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      defaultMode: yaml['default'] as String? ?? 'system',
    );
  }
}

class FontsConfig {
  final String sans;
  final String mono;

  const FontsConfig({
    this.sans = 'Inter',
    this.mono = 'JetBrains Mono',
  });

  factory FontsConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const FontsConfig();
    return FontsConfig(
      sans: yaml['sans'] as String? ?? 'Inter',
      mono: yaml['mono'] as String? ?? 'JetBrains Mono',
    );
  }
}

class CustomThemeConfig {
  final String? css;

  const CustomThemeConfig({this.css});

  factory CustomThemeConfig.fromYaml(Map yaml) =>
      CustomThemeConfig(css: yaml['css'] as String?);
}

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

  factory CodeConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const CodeConfig();
    return CodeConfig(
      theme: CodeThemeConfig.fromYaml(yaml['theme']),
      lineNumbers: yaml['lineNumbers'] as bool? ?? false,
      copyButton: yaml['copyButton'] as bool? ?? true,
      wrapLongLines: yaml['wrapLongLines'] as bool? ?? false,
      defaultLanguage: yaml['defaultLanguage'] as String? ?? 'plaintext',
      aliases: (yaml['aliases'] as Map?)?.cast<String, String>() ?? const {},
    );
  }
}

class CodeThemeConfig {
  final String light;
  final String dark;

  const CodeThemeConfig({
    this.light = 'github-light',
    this.dark = 'github-dark',
  });

  factory CodeThemeConfig.fromYaml(dynamic yaml) {
    if (yaml is String) {
      return CodeThemeConfig(light: yaml, dark: yaml);
    }
    if (yaml is Map) {
      return CodeThemeConfig(
        light: yaml['light'] as String? ?? 'github-light',
        dark: yaml['dark'] as String? ?? 'github-dark',
      );
    }
    return const CodeThemeConfig();
  }
}

class ComponentsConfig {
  final Map<String, CalloutConfig> callouts;

  const ComponentsConfig({
    this.callouts = const {
      'info': CalloutConfig(icon: 'ℹ️', color: '#3b82f6'),
      'warning': CalloutConfig(icon: '⚠️', color: '#f59e0b'),
      'danger': CalloutConfig(icon: '🚨', color: '#ef4444'),
      'tip': CalloutConfig(icon: '💡', color: '#22c55e'),
      'note': CalloutConfig(icon: '📝', color: '#8b5cf6'),
    },
  });

  factory ComponentsConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const ComponentsConfig();
    final calloutsYaml = yaml['callouts'] as Map?;
    if (calloutsYaml == null) return const ComponentsConfig();

    return ComponentsConfig(
      callouts: calloutsYaml.map(
        (key, value) =>
            MapEntry(key as String, CalloutConfig.fromYaml(value as Map)),
      ),
    );
  }
}

class CalloutConfig {
  final String icon;
  final String color;

  const CalloutConfig({
    required this.icon,
    required this.color,
  });

  factory CalloutConfig.fromYaml(Map yaml) => CalloutConfig(
        icon: yaml['icon'] as String,
        color: yaml['color'] as String,
      );
}

class SearchConfig {
  final bool enabled;
  final String provider;
  final String placeholder;
  final String hotkey;
  final AlgoliaConfig? algolia;

  const SearchConfig({
    this.enabled = true,
    this.provider = 'pagefind',
    this.placeholder = 'Search docs...',
    this.hotkey = '/',
    this.algolia,
  });

  factory SearchConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const SearchConfig();
    return SearchConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      provider: yaml['provider'] as String? ?? 'pagefind',
      placeholder: yaml['placeholder'] as String? ?? 'Search docs...',
      hotkey: yaml['hotkey'] as String? ?? '/',
      algolia: yaml['algolia'] != null
          ? AlgoliaConfig.fromYaml(yaml['algolia'] as Map)
          : null,
    );
  }
}

class AlgoliaConfig {
  final String appId;
  final String apiKey;
  final String indexName;

  const AlgoliaConfig({
    required this.appId,
    required this.apiKey,
    required this.indexName,
  });

  factory AlgoliaConfig.fromYaml(Map yaml) => AlgoliaConfig(
        appId: yaml['appId'] as String,
        apiKey: yaml['apiKey'] as String,
        indexName: yaml['indexName'] as String,
      );
}

class SeoConfig {
  final String titleTemplate;
  final String? ogImage;
  final String twitterCard;
  final String? twitterHandle;
  final bool structuredData;

  const SeoConfig({
    this.titleTemplate = '%s',
    this.ogImage,
    this.twitterCard = 'summary_large_image',
    this.twitterHandle,
    this.structuredData = true,
  });

  factory SeoConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const SeoConfig();
    return SeoConfig(
      titleTemplate: yaml['titleTemplate'] as String? ?? '%s',
      ogImage: yaml['ogImage'] as String?,
      twitterCard: yaml['twitterCard'] as String? ?? 'summary_large_image',
      twitterHandle: yaml['twitterHandle'] as String?,
      structuredData: yaml['structuredData'] as bool? ?? true,
    );
  }
}

class SocialConfig {
  final String? github;
  final String? discord;
  final String? twitter;
  final String? youtube;
  final String? linkedin;
  final String? mastodon;
  final String? slack;

  const SocialConfig({
    this.github,
    this.discord,
    this.twitter,
    this.youtube,
    this.linkedin,
    this.mastodon,
    this.slack,
  });

  factory SocialConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const SocialConfig();
    return SocialConfig(
      github: yaml['github'] as String?,
      discord: yaml['discord'] as String?,
      twitter: yaml['twitter'] as String?,
      youtube: yaml['youtube'] as String?,
      linkedin: yaml['linkedin'] as String?,
      mastodon: yaml['mastodon'] as String?,
      slack: yaml['slack'] as String?,
    );
  }
}

class HeaderConfig {
  final bool showName;
  final bool showSearch;
  final bool showThemeToggle;
  final bool showSocial;
  final AnnouncementConfig? announcement;

  const HeaderConfig({
    this.showName = true,
    this.showSearch = true,
    this.showThemeToggle = true,
    this.showSocial = true,
    this.announcement,
  });

  factory HeaderConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const HeaderConfig();
    return HeaderConfig(
      showName: yaml['showName'] as bool? ?? true,
      showSearch: yaml['showSearch'] as bool? ?? true,
      showThemeToggle: yaml['showThemeToggle'] as bool? ?? true,
      showSocial: yaml['showSocial'] as bool? ?? true,
      announcement: yaml['announcement'] != null
          ? AnnouncementConfig.fromYaml(yaml['announcement'] as Map)
          : null,
    );
  }
}

class AnnouncementConfig {
  final String text;
  final String? link;
  final bool dismissible;
  final String style;

  const AnnouncementConfig({
    required this.text,
    this.link,
    this.dismissible = true,
    this.style = 'info',
  });

  factory AnnouncementConfig.fromYaml(Map yaml) => AnnouncementConfig(
        text: yaml['text'] as String,
        link: yaml['link'] as String?,
        dismissible: yaml['dismissible'] as bool? ?? true,
        style: yaml['style'] as String? ?? 'info',
      );
}

class FooterConfig {
  final String? copyright;
  final List<FooterLinkGroup> links;

  const FooterConfig({
    this.copyright,
    this.links = const [],
  });

  factory FooterConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const FooterConfig();
    return FooterConfig(
      copyright: yaml['copyright'] as String?,
      links: (yaml['links'] as List?)
              ?.map((e) => FooterLinkGroup.fromYaml(e as Map))
              .toList() ??
          [],
    );
  }
}

class FooterLinkGroup {
  final String group;
  final List<FooterLink> items;

  const FooterLinkGroup({
    required this.group,
    this.items = const [],
  });

  factory FooterLinkGroup.fromYaml(Map yaml) => FooterLinkGroup(
        group: yaml['group'] as String,
        items: (yaml['items'] as List?)
                ?.map((e) => FooterLink.fromYaml(e as Map))
                .toList() ??
            [],
      );
}

class FooterLink {
  final String label;
  final String href;

  const FooterLink({
    required this.label,
    required this.href,
  });

  factory FooterLink.fromYaml(Map yaml) => FooterLink(
        label: yaml['label'] as String,
        href: yaml['href'] as String,
      );
}

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

  factory VersionsConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const VersionsConfig();
    return VersionsConfig(
      enabled: yaml['enabled'] as bool? ?? false,
      current: yaml['current'] as String?,
      defaultVersion: yaml['default'] as String?,
      dropdown: yaml['dropdown'] as bool? ?? true,
      list: (yaml['list'] as List?)
              ?.map((e) => VersionEntry.fromYaml(e as Map))
              .toList() ??
          [],
    );
  }
}

class VersionEntry {
  final String version;
  final String? label;
  final String path;
  final String? banner;

  const VersionEntry({
    required this.version,
    this.label,
    required this.path,
    this.banner,
  });

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

  const I18nConfig({
    this.enabled = false,
    this.defaultLocale = 'en',
    this.locales = const [],
  });

  factory I18nConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const I18nConfig();
    return I18nConfig(
      enabled: yaml['enabled'] as bool? ?? false,
      defaultLocale: yaml['defaultLocale'] as String? ?? 'en',
      locales: (yaml['locales'] as List?)
              ?.map((e) => LocaleConfig.fromYaml(e as Map))
              .toList() ??
          [],
    );
  }
}

class LocaleConfig {
  final String code;
  final String label;
  final String dir;

  const LocaleConfig({
    required this.code,
    required this.label,
    this.dir = 'ltr',
  });

  factory LocaleConfig.fromYaml(Map yaml) => LocaleConfig(
        code: yaml['code'] as String,
        label: yaml['label'] as String,
        dir: yaml['dir'] as String? ?? 'ltr',
      );
}

class IntegrationsConfig {
  final EditLinkConfig? editLink;
  final LastUpdatedConfig? lastUpdated;
  final AnalyticsConfig? analytics;
  final CommentsConfig? comments;

  const IntegrationsConfig({
    this.editLink,
    this.lastUpdated,
    this.analytics,
    this.comments,
  });

  factory IntegrationsConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const IntegrationsConfig();
    return IntegrationsConfig(
      editLink: yaml['editLink'] != null
          ? EditLinkConfig.fromYaml(yaml['editLink'] as Map)
          : null,
      lastUpdated: yaml['lastUpdated'] != null
          ? LastUpdatedConfig.fromYaml(yaml['lastUpdated'] as Map)
          : null,
      analytics: yaml['analytics'] != null
          ? AnalyticsConfig.fromYaml(yaml['analytics'] as Map)
          : null,
      comments: yaml['comments'] != null
          ? CommentsConfig.fromYaml(yaml['comments'] as Map)
          : null,
    );
  }
}

class EditLinkConfig {
  final bool enabled;
  final String? repo;
  final String branch;
  final String path;
  final String text;

  const EditLinkConfig({
    this.enabled = false,
    this.repo,
    this.branch = 'main',
    this.path = 'docs/',
    this.text = 'Edit this page on GitHub',
  });

  factory EditLinkConfig.fromYaml(Map yaml) => EditLinkConfig(
        enabled: yaml['enabled'] as bool? ?? false,
        repo: yaml['repo'] as String?,
        branch: yaml['branch'] as String? ?? 'main',
        path: yaml['path'] as String? ?? 'docs/',
        text: yaml['text'] as String? ?? 'Edit this page on GitHub',
      );
}

class LastUpdatedConfig {
  final bool enabled;
  final String format;
  final String text;

  const LastUpdatedConfig({
    this.enabled = false,
    this.format = 'MMM d, yyyy',
    this.text = 'Last updated',
  });

  factory LastUpdatedConfig.fromYaml(Map yaml) => LastUpdatedConfig(
        enabled: yaml['enabled'] as bool? ?? false,
        format: yaml['format'] as String? ?? 'MMM d, yyyy',
        text: yaml['text'] as String? ?? 'Last updated',
      );
}

class AnalyticsConfig {
  final String? google;
  final String? plausible;
  final PosthogConfig? posthog;

  const AnalyticsConfig({
    this.google,
    this.plausible,
    this.posthog,
  });

  factory AnalyticsConfig.fromYaml(Map yaml) => AnalyticsConfig(
        google: yaml['google'] as String?,
        plausible: yaml['plausible'] as String?,
        posthog: yaml['posthog'] != null
            ? PosthogConfig.fromYaml(yaml['posthog'] as Map)
            : null,
      );
}

class PosthogConfig {
  final String key;
  final String? host;

  const PosthogConfig({
    required this.key,
    this.host,
  });

  factory PosthogConfig.fromYaml(Map yaml) => PosthogConfig(
        key: yaml['key'] as String,
        host: yaml['host'] as String?,
      );
}

class CommentsConfig {
  final String? provider;
  final GiscusConfig? giscus;
  final DisqusConfig? disqus;

  const CommentsConfig({
    this.provider,
    this.giscus,
    this.disqus,
  });

  factory CommentsConfig.fromYaml(Map yaml) => CommentsConfig(
        provider: yaml['provider'] as String?,
        giscus: yaml['giscus'] != null
            ? GiscusConfig.fromYaml(yaml['giscus'] as Map)
            : null,
        disqus: yaml['disqus'] != null
            ? DisqusConfig.fromYaml(yaml['disqus'] as Map)
            : null,
      );
}

class GiscusConfig {
  final String? repo;
  final String? repoId;
  final String? category;
  final String? categoryId;

  const GiscusConfig({
    this.repo,
    this.repoId,
    this.category,
    this.categoryId,
  });

  factory GiscusConfig.fromYaml(Map yaml) => GiscusConfig(
        repo: yaml['repo'] as String?,
        repoId: yaml['repoId'] as String?,
        category: yaml['category'] as String?,
        categoryId: yaml['categoryId'] as String?,
      );
}

class DisqusConfig {
  final String? shortname;

  const DisqusConfig({this.shortname});

  factory DisqusConfig.fromYaml(Map yaml) =>
      DisqusConfig(shortname: yaml['shortname'] as String?);
}

class BuildConfig {
  final String outDir;
  final bool cleanUrls;
  final bool trailingSlash;
  final SitemapConfig sitemap;
  final RobotsConfig robots;
  final AssetsConfig assets;
  final List<RedirectConfig> redirects;

  const BuildConfig({
    this.outDir = 'dist/',
    this.cleanUrls = true,
    this.trailingSlash = false,
    this.sitemap = const SitemapConfig(),
    this.robots = const RobotsConfig(),
    this.assets = const AssetsConfig(),
    this.redirects = const [],
  });

  factory BuildConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const BuildConfig();
    return BuildConfig(
      outDir: yaml['outDir'] as String? ?? 'dist/',
      cleanUrls: yaml['cleanUrls'] as bool? ?? true,
      trailingSlash: yaml['trailingSlash'] as bool? ?? false,
      sitemap: SitemapConfig.fromYaml(yaml['sitemap'] as Map?),
      robots: RobotsConfig.fromYaml(yaml['robots'] as Map?),
      assets: AssetsConfig.fromYaml(yaml['assets'] as Map?),
      redirects: (yaml['redirects'] as List?)
              ?.map((e) => RedirectConfig.fromYaml(e as Map))
              .toList() ??
          [],
    );
  }
}

class SitemapConfig {
  final bool enabled;
  final String changefreq;
  final double priority;

  const SitemapConfig({
    this.enabled = true,
    this.changefreq = 'weekly',
    this.priority = 0.7,
  });

  factory SitemapConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const SitemapConfig();
    return SitemapConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      changefreq: yaml['changefreq'] as String? ?? 'weekly',
      priority: (yaml['priority'] as num?)?.toDouble() ?? 0.7,
    );
  }
}

class RobotsConfig {
  final bool enabled;
  final List<String> allow;
  final List<String> disallow;

  const RobotsConfig({
    this.enabled = true,
    this.allow = const ['/'],
    this.disallow = const [],
  });

  factory RobotsConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const RobotsConfig();
    return RobotsConfig(
      enabled: yaml['enabled'] as bool? ?? true,
      allow: (yaml['allow'] as List?)?.cast<String>() ?? const ['/'],
      disallow: (yaml['disallow'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class AssetsConfig {
  final String dir;
  final ImagesConfig images;

  const AssetsConfig({
    this.dir = 'public/',
    this.images = const ImagesConfig(),
  });

  factory AssetsConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const AssetsConfig();
    return AssetsConfig(
      dir: yaml['dir'] as String? ?? 'public/',
      images: ImagesConfig.fromYaml(yaml['images'] as Map?),
    );
  }
}

class ImagesConfig {
  final bool optimize;
  final int quality;
  final List<String> formats;

  const ImagesConfig({
    this.optimize = false,
    this.quality = 80,
    this.formats = const ['original'],
  });

  factory ImagesConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const ImagesConfig();
    return ImagesConfig(
      optimize: yaml['optimize'] as bool? ?? false,
      quality: yaml['quality'] as int? ?? 80,
      formats: (yaml['formats'] as List?)?.cast<String>() ?? const ['original'],
    );
  }
}

class RedirectConfig {
  final String from;
  final String to;
  final int status;

  const RedirectConfig({
    required this.from,
    required this.to,
    this.status = 301,
  });

  factory RedirectConfig.fromYaml(Map yaml) => RedirectConfig(
        from: yaml['from'] as String,
        to: yaml['to'] as String,
        status: yaml['status'] as int? ?? 301,
      );
}

class DevConfig {
  final int port;
  final String host;
  final bool open;
  final List<String> watch;

  const DevConfig({
    this.port = 4000,
    this.host = 'localhost',
    this.open = true,
    this.watch = const ['docs/', 'public/'],
  });

  factory DevConfig.fromYaml(Map? yaml) {
    if (yaml == null) return const DevConfig();
    return DevConfig(
      port: yaml['port'] as int? ?? 4000,
      host: yaml['host'] as String? ?? 'localhost',
      open: yaml['open'] as bool? ?? true,
      watch: (yaml['watch'] as List?)?.cast<String>() ??
          const ['docs/', 'public/'],
    );
  }
}
