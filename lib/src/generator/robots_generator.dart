import 'package:path/path.dart' as p;

import '../config/build_config.dart';
import '../core/file_system.dart';
import '../utils/logger.dart';

/// Generates `robots.txt`. A site has exactly one, served from the origin root,
/// so versioned builds emit it once at the site root rather than per version.
class RobotsGenerator {
  final String outputDir;
  final RobotsConfig robots;
  final String? sitemapUrl;
  final Logger logger;
  final FileSystem fileSystem;

  RobotsGenerator({
    required this.outputDir,
    required this.robots,
    this.sitemapUrl,
    this.logger = const Logger(),
    FileSystem? fileSystem,
  }) : fileSystem = fileSystem ?? const LocalFileSystem();

  Future<void> generate() async {
    final buffer = StringBuffer()..writeln('User-agent: *');
    for (final path in robots.allow) {
      buffer.writeln('Allow: $path');
    }
    for (final path in robots.disallow) {
      buffer.writeln('Disallow: $path');
    }
    if (sitemapUrl case final url?) {
      buffer
        ..writeln('')
        ..writeln('Sitemap: $url');
    }

    await fileSystem.writeFile(p.join(outputDir, 'robots.txt'), buffer.toString());
    logger.log('🤖 Generated robots.txt');
  }
}
