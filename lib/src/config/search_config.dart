class SearchConfig {
  final bool enabled;
  final String provider;
  final String placeholder;
  final String hotkey;

  const SearchConfig({
    this.enabled = true,
    this.provider = 'pagefind',
    this.placeholder = 'Search docs...',
    this.hotkey = '/',
  });

  factory SearchConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => SearchConfig(
            enabled: yaml['enabled'] as bool? ?? true,
            provider: yaml['provider'] as String? ?? 'pagefind',
            placeholder: yaml['placeholder'] as String? ?? 'Search docs...',
            hotkey: yaml['hotkey'] as String? ?? '/',
          ),
        _ => const SearchConfig(),
      };
}
