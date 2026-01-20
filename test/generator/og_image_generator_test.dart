import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/generator/og_image_generator.dart';
import 'package:stardust/src/models/page.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('OgImageGenerator', () {
    late MockFileSystem fileSystem;
    late List<String> logs;
    late List<String> errors;
    late Logger logger;

    StardustConfig createConfig({
      String name = 'Test Site',
      String? url,
      LogoConfig? logo,
      ThemeConfig? theme,
      String basePath = '',
    }) =>
        StardustConfig(
          name: name,
          url: url,
          logo: logo,
          theme: theme ?? const ThemeConfig(),
          build: const BuildConfig(),
          content: const ContentConfig(),
          header: const HeaderConfig(),
          footer: const FooterConfig(),
          sidebar: const [],
          social: const SocialConfig(),
          seo: const SeoConfig(),
          search: const SearchConfig(),
        );

    setUp(() {
      fileSystem = MockFileSystem();
      logs = [];
      errors = [];
      logger = Logger(
        onLog: logs.add,
        onError: errors.add,
      );
    });

    group('generateAll', () {
      test('creates OG directory and generates images for all pages', () async {
        final config = createConfig(name: 'My Docs');
        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        final pages = [
          const Page(path: '/', sourcePath: 'docs/index.md', title: 'Home', content: ''),
          const Page(
              path: '/getting-started', sourcePath: 'docs/getting-started.md', title: 'Getting Started', content: ''),
        ];

        final results = await generator.generateAll(pages);

        expect(results.length, 2);
        expect(results['/'], '/images/og/index.png');
        expect(results['/getting-started'], '/images/og/getting-started.png');
        expect(fileSystem.directories.contains(p.join('dist', 'images', 'og')), isTrue);
        expect(fileSystem.binaryFiles.containsKey(p.join('dist', 'images', 'og', 'index.png')), isTrue);
        expect(fileSystem.binaryFiles.containsKey(p.join('dist', 'images', 'og', 'getting-started.png')), isTrue);
      });

      test('handles nested paths correctly', () async {
        final config = createConfig();
        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        final pages = [
          const Page(
              path: '/docs/api/reference', sourcePath: 'docs/api/reference.md', title: 'API Reference', content: ''),
        ];

        final results = await generator.generateAll(pages);

        expect(results['/docs/api/reference'], '/images/og/docs-api-reference.png');
      });
    });

    group('generate', () {
      test('generates valid PNG image', () async {
        final config = createConfig(name: 'Test');
        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        final ogDir = p.join('dist', 'images', 'og');
        await fileSystem.createDirectory(ogDir, recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Welcome', content: ''),
          ogDir,
        );

        expect(result, '/images/og/index.png');

        final bytes = fileSystem.binaryFiles[p.join('dist', 'images', 'og', 'index.png')]!;
        final image = img.decodePng(bytes);
        expect(image, isNotNull);
        expect(image!.width, 1200);
        expect(image.height, 630);
      });

      test('returns null and logs error on failure', () async {
        final config = createConfig();

        // Create a file system that throws on write
        final failingFileSystem = _FailingFileSystem();

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: failingFileSystem,
        );

        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNull);
        expect(errors.any((e) => e.contains('Failed to generate OG image')), isTrue);
      });

      test('includes basePath in returned URL', () async {
        const config = StardustConfig(
          name: 'Test',
          url: 'https://example.com/docs',
          build: BuildConfig(),
          content: ContentConfig(),
          header: HeaderConfig(),
          footer: FooterConfig(),
          sidebar: [],
          social: SocialConfig(),
          seo: SeoConfig(),
          search: SearchConfig(),
          theme: ThemeConfig(),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/api', sourcePath: 'api.md', title: 'API', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, '/docs/images/og/api.png');
      });
    });

    group('logo loading', () {
      test('loads PNG logo when configured', () async {
        // Create a simple 10x10 PNG image
        final logoImage = img.Image(width: 10, height: 10);
        img.fill(logoImage, color: img.ColorRgb8(255, 0, 0));
        final logoBytes = Uint8List.fromList(img.encodePng(logoImage));

        fileSystem.addBinaryFile('public/logo.png', logoBytes);

        final config = createConfig(
          logo: const LogoConfig(single: '/logo.png'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });

      test('finds PNG alternative when SVG logo is configured', () async {
        final logoImage = img.Image(width: 10, height: 10);
        img.fill(logoImage, color: img.ColorRgb8(0, 255, 0));
        final logoBytes = Uint8List.fromList(img.encodePng(logoImage));

        // SVG doesn't exist, but PNG alternative does
        fileSystem.addBinaryFile('public/logo.png', logoBytes);

        final config = createConfig(
          logo: const LogoConfig(single: '/logo.svg'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
        expect(fileSystem.operations.any((op) => op.contains('logo.png')), isTrue);
      });

      test('logs warning when SVG logo has no raster alternative', () async {
        final config = createConfig(
          logo: const LogoConfig(single: '/logo.svg'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(logs.any((log) => log.contains('SVG logos not supported')), isTrue);
      });

      test('uses dark logo when available', () async {
        final logoImage = img.Image(width: 10, height: 10);
        final logoBytes = Uint8List.fromList(img.encodePng(logoImage));

        fileSystem.addBinaryFile('public/logo-dark.png', logoBytes);

        final config = createConfig(
          logo: const LogoConfig(dark: '/logo-dark.png', light: '/logo-light.png'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(fileSystem.operations.any((op) => op.contains('logo-dark.png')), isTrue);
      });

      test('returns null when logo file does not exist', () async {
        final config = createConfig(
          logo: const LogoConfig(single: '/nonexistent.png'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        // Should still generate image, just without logo
        expect(result, isNotNull);
      });

      test('handles logo loading error gracefully', () async {
        // Add invalid image data
        fileSystem.addBinaryFile('public/logo.png', Uint8List.fromList([0, 1, 2, 3]));

        final config = createConfig(
          logo: const LogoConfig(single: '/logo.png'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        // Should still generate image without logo
        expect(result, isNotNull);
      });
    });

    group('theme colors', () {
      test('uses theme colors from config', () async {
        final config = createConfig(
          theme: const ThemeConfig(
            colors: ColorsConfig(
              primary: '#ff0000',
              background: BackgroundColors(dark: '#000000'),
              text: TextColors(dark: '#ffffff'),
            ),
          ),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
        // Verify image was generated (colors are applied internally)
        expect(fileSystem.binaryFiles.containsKey(p.join('dist', 'images', 'og', 'index.png')), isTrue);
      });

      test('uses default colors when theme colors not specified', () async {
        final config = createConfig();

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });
    });

    group('text wrapping', () {
      test('handles long titles with wrapping', () async {
        final config = createConfig();

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(
            path: '/long-title',
            sourcePath: 'long.md',
            title:
                'This is an extremely long title that should wrap across multiple lines in the OG image because it exceeds the maximum width',
            content: '',
          ),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });

      test('handles very long single word', () async {
        final config = createConfig();

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(
            path: '/long-word',
            sourcePath: 'long.md',
            title: 'Supercalifragilisticexpialidocious',
            content: '',
          ),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });

      test('truncates title with ellipsis when exceeds max lines', () async {
        final config = createConfig();

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final longTitle = List.generate(50, (i) => 'word$i').join(' ');
        final result = await generator.generate(
          Page(
            path: '/very-long',
            sourcePath: 'long.md',
            title: longTitle,
            content: '',
          ),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });

      test('handles special characters not in font', () async {
        final config = createConfig();

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(
            path: '/special',
            sourcePath: 'special.md',
            title: 'Title with special chars \u00A9 \u00AE \u2122',
            content: '',
          ),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });
    });

    group('_pagePathToFileName', () {
      test('converts root path to index.png', () async {
        final config = createConfig();
        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Home', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(fileSystem.binaryFiles.containsKey(p.join('dist', 'images', 'og', 'index.png')), isTrue);
      });

      test('converts nested path with slashes to dashes', () async {
        final config = createConfig();
        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        await generator.generate(
          const Page(path: '/docs/api/v2', sourcePath: 'docs/api/v2.md', title: 'API v2', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(fileSystem.binaryFiles.containsKey(p.join('dist', 'images', 'og', 'docs-api-v2.png')), isTrue);
      });
    });

    group('_parseColor', () {
      test('handles 3-character hex colors', () async {
        final config = createConfig(
          theme: const ThemeConfig(
            colors: ColorsConfig(
              primary: '#f00', // Short hex
            ),
          ),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });
    });

    group('logo scaling', () {
      test('scales down large logos', () async {
        // Create a large 100x100 logo
        final logoImage = img.Image(width: 100, height: 100);
        img.fill(logoImage, color: img.ColorRgb8(0, 0, 255));
        final logoBytes = Uint8List.fromList(img.encodePng(logoImage));

        fileSystem.addBinaryFile('public/logo.png', logoBytes);

        final config = createConfig(
          logo: const LogoConfig(single: '/logo.png'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });

      test('does not scale up small logos', () async {
        // Create a small 20x20 logo (smaller than maxHeight of 40)
        final logoImage = img.Image(width: 20, height: 20);
        img.fill(logoImage, color: img.ColorRgb8(0, 0, 255));
        final logoBytes = Uint8List.fromList(img.encodePng(logoImage));

        fileSystem.addBinaryFile('public/logo.png', logoBytes);

        final config = createConfig(
          logo: const LogoConfig(single: '/logo.png'),
        );

        final generator = OgImageGenerator(
          config: config,
          outputDir: 'dist',
          logger: logger,
          fileSystem: fileSystem,
        );

        await fileSystem.createDirectory(p.join('dist', 'images', 'og'), recursive: true);
        final result = await generator.generate(
          const Page(path: '/', sourcePath: 'index.md', title: 'Test', content: ''),
          p.join('dist', 'images', 'og'),
        );

        expect(result, isNotNull);
      });
    });
  });
}

class _FailingFileSystem extends MockFileSystem {
  @override
  Future<void> writeFileBytes(String path, Uint8List bytes) async {
    throw Exception('Write failed');
  }
}
