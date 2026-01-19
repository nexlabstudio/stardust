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

  factory SeoConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => SeoConfig(
            titleTemplate: yaml['titleTemplate'] as String? ?? '%s',
            ogImage: yaml['ogImage'] as String?,
            twitterCard: yaml['twitterCard'] as String? ?? 'summary_large_image',
            twitterHandle: yaml['twitterHandle'] as String?,
            structuredData: yaml['structuredData'] as bool? ?? true,
          ),
        _ => const SeoConfig(),
      };
}

class SocialConfig {
  final String? github;
  final String? discord;
  final String? twitter;
  final String? youtube;
  final String? linkedin;
  final String? mastodon;
  final String? slack;
  final String? pubdev;

  const SocialConfig({
    this.github,
    this.discord,
    this.twitter,
    this.youtube,
    this.linkedin,
    this.mastodon,
    this.slack,
    this.pubdev,
  });

  factory SocialConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => SocialConfig(
            github: yaml['github'] as String?,
            discord: yaml['discord'] as String?,
            twitter: yaml['twitter'] as String?,
            youtube: yaml['youtube'] as String?,
            linkedin: yaml['linkedin'] as String?,
            mastodon: yaml['mastodon'] as String?,
            slack: yaml['slack'] as String?,
            pubdev: yaml['pubdev'] as String?,
          ),
        _ => const SocialConfig(),
      };
}
