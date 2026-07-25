class SearchConfig {
  final bool enabled;
  final String placeholder;
  final String hotkey;
  final int pageSize;

  const SearchConfig({
    this.enabled = true,
    this.placeholder = 'Search docs...',
    this.hotkey = '/',
    this.pageSize = 8,
  });

  factory SearchConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => SearchConfig(
            enabled: yaml['enabled'] as bool? ?? true,
            placeholder: yaml['placeholder'] as String? ?? 'Search docs...',
            hotkey: yaml['hotkey'] as String? ?? '/',
            pageSize: (yaml['pageSize'] as num?)?.toInt() ?? 8,
          ),
        _ => const SearchConfig(),
      };
}
