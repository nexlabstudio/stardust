class BuildConfig {
  final String outDir;
  final String? basePath;
  final bool cleanUrls;
  final bool trailingSlash;
  final SitemapConfig sitemap;
  final RobotsConfig robots;
  final LlmsConfig llms;
  final AssetsConfig assets;
  final List<RedirectConfig> redirects;

  const BuildConfig({
    this.outDir = 'dist/',
    this.basePath,
    this.cleanUrls = true,
    this.trailingSlash = false,
    this.sitemap = const SitemapConfig(),
    this.robots = const RobotsConfig(),
    this.llms = const LlmsConfig(),
    this.assets = const AssetsConfig(),
    this.redirects = const [],
  });

  factory BuildConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => BuildConfig(
            outDir: yaml['outDir'] as String? ?? 'dist/',
            basePath: yaml['basePath'] as String?,
            cleanUrls: yaml['cleanUrls'] as bool? ?? true,
            trailingSlash: yaml['trailingSlash'] as bool? ?? false,
            sitemap: SitemapConfig.fromYaml(yaml['sitemap'] as Map?),
            robots: RobotsConfig.fromYaml(yaml['robots'] as Map?),
            llms: LlmsConfig.fromYaml(yaml['llms'] as Map?),
            assets: AssetsConfig.fromYaml(yaml['assets'] as Map?),
            redirects: (yaml['redirects'] as List?)?.map((e) => RedirectConfig.fromYaml(e as Map)).toList() ?? [],
          ),
        _ => const BuildConfig(),
      };
}

class SitemapConfig {
  final bool enabled;
  final String changefreq;
  final double priority;

  const SitemapConfig({this.enabled = true, this.changefreq = 'weekly', this.priority = 0.7});

  factory SitemapConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => SitemapConfig(
            enabled: yaml['enabled'] as bool? ?? true,
            changefreq: yaml['changefreq'] as String? ?? 'weekly',
            priority: (yaml['priority'] as num?)?.toDouble() ?? 0.7,
          ),
        _ => const SitemapConfig(),
      };
}

class RobotsConfig {
  final bool enabled;
  final List<String> allow;
  final List<String> disallow;

  const RobotsConfig({this.enabled = true, this.allow = const ['/'], this.disallow = const []});

  factory RobotsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => RobotsConfig(
            enabled: yaml['enabled'] as bool? ?? true,
            allow: (yaml['allow'] as List?)?.cast<String>() ?? const ['/'],
            disallow: (yaml['disallow'] as List?)?.cast<String>() ?? const [],
          ),
        _ => const RobotsConfig(),
      };
}

class LlmsConfig {
  final bool enabled;

  const LlmsConfig({this.enabled = true});

  factory LlmsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => LlmsConfig(enabled: yaml['enabled'] as bool? ?? true),
        _ => const LlmsConfig(),
      };
}

class AssetsConfig {
  final String dir;
  final ImagesConfig images;

  const AssetsConfig({
    this.dir = 'public/',
    this.images = const ImagesConfig(),
  });

  factory AssetsConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => AssetsConfig(
            dir: yaml['dir'] as String? ?? 'public/',
            images: ImagesConfig.fromYaml(yaml['images'] as Map?),
          ),
        _ => const AssetsConfig(),
      };
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

  factory ImagesConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => ImagesConfig(
            optimize: yaml['optimize'] as bool? ?? false,
            quality: yaml['quality'] as int? ?? 80,
            formats: (yaml['formats'] as List?)?.cast<String>() ?? const ['original'],
          ),
        _ => const ImagesConfig(),
      };
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

  factory DevConfig.fromYaml(Map? yaml) => switch (yaml) {
        final Map yaml => DevConfig(
            port: yaml['port'] as int? ?? 4000,
            host: yaml['host'] as String? ?? 'localhost',
            open: yaml['open'] as bool? ?? true,
            watch: (yaml['watch'] as List?)?.cast<String>() ?? const ['docs/', 'public/'],
          ),
        _ => const DevConfig(),
      };
}
