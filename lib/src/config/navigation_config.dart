class NavItem {
  final String label;
  final String href;
  final bool external;
  final String? icon;

  const NavItem({required this.label, required this.href, this.external = false, this.icon});

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
        pages: (yaml['pages'] as List?)?.map(SidebarPage.fromYaml).toList() ?? [],
        autogenerate: switch (yaml['autogenerate']) {
          final Map auto => AutogenerateConfig.fromYaml(auto),
          _ => null,
        },
      );
}

class SidebarPage {
  final String slug;
  final String? label;
  final String? icon;

  const SidebarPage({required this.slug, this.label, this.icon});

  factory SidebarPage.fromYaml(dynamic yaml) => switch (yaml) {
        final String slug => SidebarPage(slug: slug),
        final Map yaml => SidebarPage(
            slug: yaml['slug'] as String,
            label: yaml['label'] as String?,
            icon: yaml['icon'] as String?,
          ),
        _ => throw ArgumentError('Invalid sidebar page: $yaml'),
      };
}

class AutogenerateConfig {
  final String dir;
  final String order;

  const AutogenerateConfig({required this.dir, this.order = 'filename'});

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

  factory TocConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => TocConfig(
            enabled: yaml['enabled'] as bool? ?? true,
            minDepth: yaml['minDepth'] as int? ?? 2,
            maxDepth: yaml['maxDepth'] as int? ?? 4,
            title: yaml['title'] as String? ?? 'On this page',
          ),
        _ => const TocConfig(),
      };
}
