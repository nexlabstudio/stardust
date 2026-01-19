import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/content/component_transformer.dart';
import 'package:stardust/src/content/markdown_parser.dart';
import 'package:stardust/src/core/file_system.dart';
import 'package:stardust/src/core/stardust_factory.dart';
import 'package:stardust/src/generator/page_builder.dart';
import 'package:stardust/src/generator/site_generator.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('StardustFactory', () {
    test('uses LocalFileSystem and no-op Logger by default', () {
      const factory = StardustFactory();

      expect(factory.fileSystem, isA<LocalFileSystem>());
      expect(factory.logger, isA<Logger>());
    });

    test('accepts custom FileSystem', () {
      final mockFs = MockFileSystem();
      final factory = StardustFactory(fileSystem: mockFs);

      expect(factory.fileSystem, same(mockFs));
    });

    test('accepts custom Logger', () {
      final messages = <String>[];
      final customLogger = Logger(onLog: messages.add);
      final factory = StardustFactory(logger: customLogger);

      expect(factory.logger, same(customLogger));
    });

    group('createComponentTransformer', () {
      test('creates transformer with default config', () {
        const factory = StardustFactory();
        final transformer = factory.createComponentTransformer();

        expect(transformer, isA<ComponentTransformer>());
      });

      test('creates transformer with custom config', () {
        const factory = StardustFactory();
        const customConfig = ComponentsConfig(
          callouts: {
            'custom': CalloutConfig(icon: '✨', color: '#ff0000'),
          },
        );
        final transformer = factory.createComponentTransformer(config: customConfig);

        expect(transformer, isA<ComponentTransformer>());
      });
    });

    group('createMarkdownParser', () {
      test('creates parser with config', () {
        const factory = StardustFactory();
        const config = StardustConfig(name: 'Test');

        final parser = factory.createMarkdownParser(config: config);

        expect(parser, isA<MarkdownParser>());
      });

      test('uses provided componentTransformer', () {
        const factory = StardustFactory();
        const config = StardustConfig(name: 'Test');
        final customTransformer = ComponentTransformer();

        final parser = factory.createMarkdownParser(
          config: config,
          componentTransformer: customTransformer,
        );

        expect(parser, isA<MarkdownParser>());
      });

      test('creates default componentTransformer when not provided', () {
        const factory = StardustFactory();
        const config = StardustConfig(name: 'Test');

        final parser = factory.createMarkdownParser(config: config);

        // Parser should work with created transformer
        final result = parser.parse('<Info>Test</Info>');
        expect(result.html, contains('callout'));
      });
    });

    group('createPageBuilder', () {
      test('creates builder with config', () {
        const factory = StardustFactory();
        const config = StardustConfig(name: 'Test');

        final builder = factory.createPageBuilder(config: config);

        expect(builder, isA<PageBuilder>());
      });
    });

    group('createSiteGenerator', () {
      test('creates generator with required params', () {
        final mockFs = MockFileSystem();
        final factory = StardustFactory(fileSystem: mockFs);
        const config = StardustConfig(name: 'Test');

        final generator = factory.createSiteGenerator(
          config: config,
          outputDir: 'dist',
        );

        expect(generator, isA<SiteGenerator>());
      });

      test('uses factory logger', () {
        final messages = <String>[];
        final mockFs = MockFileSystem();
        final factory = StardustFactory(
          fileSystem: mockFs,
          logger: Logger(onLog: messages.add),
        );
        const config = StardustConfig(name: 'Test');

        final generator = factory.createSiteGenerator(
          config: config,
          outputDir: 'dist',
        );

        expect(generator, isA<SiteGenerator>());
      });

      test('uses factory fileSystem', () {
        final mockFs = MockFileSystem();
        final factory = StardustFactory(fileSystem: mockFs);
        const config = StardustConfig(name: 'Test');

        final generator = factory.createSiteGenerator(
          config: config,
          outputDir: 'dist',
        );

        expect(generator, isA<SiteGenerator>());
      });

      test('accepts custom markdownParser', () {
        final mockFs = MockFileSystem();
        final factory = StardustFactory(fileSystem: mockFs);
        const config = StardustConfig(name: 'Test');
        final customParser = MarkdownParser(config: config);

        final generator = factory.createSiteGenerator(
          config: config,
          outputDir: 'dist',
          markdownParser: customParser,
        );

        expect(generator, isA<SiteGenerator>());
      });

      test('accepts custom pageBuilder', () {
        final mockFs = MockFileSystem();
        final factory = StardustFactory(fileSystem: mockFs);
        const config = StardustConfig(name: 'Test');
        final customBuilder = PageBuilder(config: config);

        final generator = factory.createSiteGenerator(
          config: config,
          outputDir: 'dist',
          pageBuilder: customBuilder,
        );

        expect(generator, isA<SiteGenerator>());
      });
    });
  });
}
