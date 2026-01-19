class IntegrationsConfig {
  final EditLinkConfig? editLink;
  final LastUpdatedConfig? lastUpdated;
  final AnalyticsConfig? analytics;
  final CommentsConfig? comments;

  const IntegrationsConfig({this.editLink, this.lastUpdated, this.analytics, this.comments});

  factory IntegrationsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => IntegrationsConfig(
            editLink: switch (yaml['editLink']) {
              final Map e => EditLinkConfig.fromYaml(e),
              _ => null,
            },
            lastUpdated: switch (yaml['lastUpdated']) {
              final Map e => LastUpdatedConfig.fromYaml(e),
              _ => null,
            },
            analytics: switch (yaml['analytics']) {
              final Map e => AnalyticsConfig.fromYaml(e),
              _ => null,
            },
            comments: switch (yaml['comments']) {
              final Map e => CommentsConfig.fromYaml(e),
              _ => null,
            },
          ),
        _ => const IntegrationsConfig(),
      };
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

  const LastUpdatedConfig({this.enabled = false, this.format = 'MMM d, yyyy', this.text = 'Last updated'});

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

  const AnalyticsConfig({this.google, this.plausible, this.posthog});

  factory AnalyticsConfig.fromYaml(Map yaml) => AnalyticsConfig(
        google: yaml['google'] as String?,
        plausible: yaml['plausible'] as String?,
        posthog: switch (yaml['posthog']) {
          final Map p => PosthogConfig.fromYaml(p),
          _ => null,
        },
      );
}

class PosthogConfig {
  final String key;
  final String? host;

  const PosthogConfig({required this.key, this.host});

  factory PosthogConfig.fromYaml(Map yaml) => PosthogConfig(
        key: yaml['key'] as String,
        host: yaml['host'] as String?,
      );
}

class CommentsConfig {
  final String? provider;
  final GiscusConfig? giscus;
  final DisqusConfig? disqus;

  const CommentsConfig({this.provider, this.giscus, this.disqus});

  factory CommentsConfig.fromYaml(Map yaml) => CommentsConfig(
        provider: yaml['provider'] as String?,
        giscus: switch (yaml['giscus']) {
          final Map g => GiscusConfig.fromYaml(g),
          _ => null,
        },
        disqus: switch (yaml['disqus']) {
          final Map d => DisqusConfig.fromYaml(d),
          _ => null,
        },
      );
}

class GiscusConfig {
  final String? repo;
  final String? repoId;
  final String? category;
  final String? categoryId;

  const GiscusConfig({this.repo, this.repoId, this.category, this.categoryId});

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

  factory DisqusConfig.fromYaml(Map yaml) => DisqusConfig(shortname: yaml['shortname'] as String?);
}
