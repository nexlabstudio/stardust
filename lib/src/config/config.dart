import 'build_config.dart';
import 'code_config.dart';
import 'i18n_config.dart';
import 'integrations_config.dart';
import 'layout_config.dart';
import 'navigation_config.dart';
import 'search_config.dart';
import 'seo_config.dart';
import 'theme_config.dart';

export 'build_config.dart';
export 'code_config.dart';
export 'i18n_config.dart';
export 'integrations_config.dart';
export 'layout_config.dart';
export 'navigation_config.dart';
export 'search_config.dart';
export 'seo_config.dart';
export 'theme_config.dart';

/// Main Stardust configuration
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
