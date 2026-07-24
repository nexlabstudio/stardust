import 'package:path/path.dart' as p;

import '../config/config.dart';
import 'version_planner.dart';

/// One locale to build when i18n is enabled: where its translations live, where
/// it is written, and how its URLs are prefixed.
class LocaleBuildTask {
  final LocaleConfig locale;
  final bool isDefault;
  final String translatedDir;
  final String outputDir;
  final String? localeBasePath;

  const LocaleBuildTask({
    required this.locale,
    required this.isDefault,
    required this.translatedDir,
    required this.outputDir,
    required this.localeBasePath,
  });
}

/// Plans the per-locale builds for [config] writing under [baseOutputDir]. The
/// default locale builds from the live content dir; each other locale's
/// translations default to `<content.dir>/<code>` unless [LocaleConfig.source]
/// overrides it, and fall back to the default content per page at build time.
List<LocaleBuildTask> planLocaleBuilds(StardustConfig config, String baseOutputDir) {
  final i18n = config.i18n;
  if (i18n == null || !i18n.enabled) return const [];

  final base = config.basePath;
  final tasks = <LocaleBuildTask>[];
  for (final locale in i18n.locales) {
    final route = routeUnderPath(locale.path, base, baseOutputDir);
    tasks.add(LocaleBuildTask(
      locale: locale,
      isDefault: locale.code == i18n.defaultLocale,
      translatedDir: locale.source ?? p.join(config.content.dir, locale.code),
      outputDir: route.outputDir,
      localeBasePath: route.basePath,
    ));
  }
  return tasks;
}
