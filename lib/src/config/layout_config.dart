class LogoConfig {
  final String? light;
  final String? dark;
  final String? single;

  const LogoConfig({this.light, this.dark, this.single});

  factory LogoConfig.fromYaml(dynamic yaml) => switch (yaml) {
        final String yaml => LogoConfig(single: yaml),
        final Map yaml => LogoConfig(light: yaml['light'] as String?, dark: yaml['dark'] as String?),
        _ => const LogoConfig(),
      };

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

  factory ContentConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => ContentConfig(
            dir: yaml['dir'] as String? ?? 'docs/',
            index: yaml['index'] as String? ?? 'index.md',
            include: (yaml['include'] as List?)?.cast<String>() ?? const ['*.md', '**/*.md', '*.mdx', '**/*.mdx'],
            exclude: (yaml['exclude'] as List?)?.cast<String>() ?? const [],
          ),
        _ => const ContentConfig(),
      };
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

  factory HeaderConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => HeaderConfig(
            showName: yaml['showName'] as bool? ?? true,
            showSearch: yaml['showSearch'] as bool? ?? true,
            showThemeToggle: yaml['showThemeToggle'] as bool? ?? true,
            showSocial: yaml['showSocial'] as bool? ?? true,
            announcement: switch (yaml['announcement']) {
              final Map a => AnnouncementConfig.fromYaml(a),
              _ => null,
            },
          ),
        _ => const HeaderConfig(),
      };
}

class AnnouncementConfig {
  final String text;
  final String? link;
  final bool dismissible;
  final String style;

  const AnnouncementConfig({required this.text, this.link, this.dismissible = true, this.style = 'info'});

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

  const FooterConfig({this.copyright, this.links = const []});

  factory FooterConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => FooterConfig(
            copyright: yaml['copyright'] as String?,
            links: (yaml['links'] as List?)?.map((e) => FooterLinkGroup.fromYaml(e as Map)).toList() ?? [],
          ),
        _ => const FooterConfig(),
      };
}

class FooterLinkGroup {
  final String group;
  final List<FooterLink> items;

  const FooterLinkGroup({required this.group, this.items = const []});

  factory FooterLinkGroup.fromYaml(Map yaml) => FooterLinkGroup(
        group: yaml['group'] as String,
        items: (yaml['items'] as List?)?.map((e) => FooterLink.fromYaml(e as Map)).toList() ?? [],
      );
}

class FooterLink {
  final String label;
  final String href;

  const FooterLink({required this.label, required this.href});

  factory FooterLink.fromYaml(Map yaml) => FooterLink(
        label: yaml['label'] as String,
        href: yaml['href'] as String,
      );
}
