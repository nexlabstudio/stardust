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

  factory SearchConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => SearchConfig(
            enabled: yaml['enabled'] as bool? ?? true,
            provider: yaml['provider'] as String? ?? 'pagefind',
            placeholder: yaml['placeholder'] as String? ?? 'Search docs...',
            hotkey: yaml['hotkey'] as String? ?? '/',
            algolia: switch (yaml['algolia']) {
              final Map algolia => AlgoliaConfig.fromYaml(algolia),
              _ => null,
            },
          ),
        _ => const SearchConfig(),
      };
}

class AlgoliaConfig {
  final String appId;
  final String apiKey;
  final String indexName;

  const AlgoliaConfig({required this.appId, required this.apiKey, required this.indexName});

  factory AlgoliaConfig.fromYaml(Map yaml) => AlgoliaConfig(
        appId: yaml['appId'] as String,
        apiKey: yaml['apiKey'] as String,
        indexName: yaml['indexName'] as String,
      );
}
