import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/dartdoc/dartdoc_generator.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

void main() {
  group('DartdocGenerator.buildTopBar', () {
    test('renders the site name and a back-to-docs link', () {
      final bar = DartdocGenerator.buildTopBar('My Docs', 'https://example.com');

      expect(bar, contains('class="sd-apibar"'));
      expect(bar, contains('My Docs · API reference'));
      expect(bar, contains('href="https://example.com">← Back to docs'));
    });

    test('escapes the name and url', () {
      final bar = DartdocGenerator.buildTopBar('A & B <x>', 'https://e.com/"');

      expect(bar, contains('A &amp; B &lt;x&gt;'));
      expect(bar, isNot(contains('A & B <x>')));
      expect(bar, contains('https://e.com/&quot;'));
    });
  });

  group('DartdocGenerator.homeHref', () {
    test('is / for a root deploy', () {
      expect(DartdocGenerator.homeHref(const StardustConfig(name: 'X')), '/');
    });

    test('respects a subpath from build.basePath', () {
      const config = StardustConfig(name: 'X', build: BuildConfig(basePath: '/docs'));
      expect(DartdocGenerator.homeHref(config), '/docs/');
    });

    test('respects a subpath extracted from url', () {
      const config = StardustConfig(name: 'X', url: 'https://acme.github.io/pkg');
      expect(DartdocGenerator.homeHref(config), '/pkg/');
    });
  });

  group('DartdocGenerator.injectChrome', () {
    const bar = '<div class="sd-apibar">BAR</div>';

    test('inserts the top-bar right after <body> (with attributes)', () {
      final out = DartdocGenerator.injectChrome('<html><body class="light">X</body>', bar);

      expect(out, contains('<body class="light"><div class="sd-apibar">BAR</div>'));
    });

    test('tags dartdoc content column (not the sidebar-wrapping <main>)', () {
      const page = '<body><main><div id="dartdoc-sidebar-left">nav</div>'
          '<div id="dartdoc-main-content">content</div></main></body>';
      final out = DartdocGenerator.injectChrome(page, bar);

      expect(out, contains('id="dartdoc-main-content" data-pagefind-body'));
      expect(out, isNot(contains('<main data-pagefind-body')));
    });

    test('no-ops the pagefind tag on pages without the content column', () {
      final out = DartdocGenerator.injectChrome('<body><div>search page</div></body>', bar);

      expect(out, isNot(contains('data-pagefind-body')));
      expect(out, contains('BAR'));
    });
  });

  group('DartdocGenerator.generate (real dart doc)', () {
    test('produces API pages with the Stardust top-bar and pagefind body', () async {
      final pkg = await Directory.systemTemp.createTemp('stardust-dd-');
      final out = await Directory.systemTemp.createTemp('stardust-dd-out-');
      Future<void> write(String rel, String content) async {
        final file = File(p.join(pkg.path, rel));
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      }

      try {
        await write('pubspec.yaml', 'name: fixture_pkg\nenvironment:\n  sdk: ^3.0.0\n');
        await write(
            'lib/fixture_pkg.dart', '/// A greeter.\nclass Greeter {\n  /// Greet.\n  String greet() => "hi";\n}\n');
        await Process.run('dart', ['pub', 'get'], workingDirectory: pkg.path);

        final stale = File(p.join(out.path, 'stale.html'));
        await stale.writeAsString('from a previous run');

        const config = StardustConfig(name: 'Fixture', url: 'https://x.dev');
        final pages = await DartdocGenerator(
          packagePath: pkg.path,
          outputDir: out.path,
          config: config,
          logger: Logger(onLog: (_) {}),
        ).generate();

        expect(pages, greaterThan(0));
        expect(stale.existsSync(), isFalse, reason: 'output dir should be cleared before writing');
        final classPage = File(p.join(out.path, 'fixture_pkg', 'Greeter-class.html'));
        expect(classPage.existsSync(), isTrue);
        final html = classPage.readAsStringSync();
        expect(html, contains('class="sd-apibar"'));
        expect(html, contains('id="dartdoc-main-content" data-pagefind-body'));
      } finally {
        await pkg.delete(recursive: true);
        await out.delete(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
