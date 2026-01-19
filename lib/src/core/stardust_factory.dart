import '../config/config.dart';
import '../content/component_transformer.dart';
import '../content/markdown_parser.dart';
import '../generator/page_builder.dart';
import '../generator/site_generator.dart';
import '../utils/logger.dart';
import 'file_system.dart';

class StardustFactory {
  final FileSystem fileSystem;
  final Logger logger;

  const StardustFactory({
    this.fileSystem = const LocalFileSystem(),
    this.logger = const Logger(),
  });

  ComponentTransformer createComponentTransformer({
    ComponentsConfig config = const ComponentsConfig(),
  }) =>
      ComponentTransformer(config: config);

  MarkdownParser createMarkdownParser({
    required StardustConfig config,
    ComponentTransformer? componentTransformer,
  }) =>
      MarkdownParser(
        config: config,
        componentTransformer: componentTransformer ?? createComponentTransformer(config: config.components),
      );

  PageBuilder createPageBuilder({required StardustConfig config}) => PageBuilder(config: config);

  SiteGenerator createSiteGenerator({
    required StardustConfig config,
    required String outputDir,
    MarkdownParser? markdownParser,
    PageBuilder? pageBuilder,
  }) =>
      SiteGenerator(
        config: config,
        outputDir: outputDir,
        logger: logger,
        fileSystem: fileSystem,
        contentParser: markdownParser ?? createMarkdownParser(config: config),
        pageBuilder: pageBuilder ?? createPageBuilder(config: config),
      );
}
