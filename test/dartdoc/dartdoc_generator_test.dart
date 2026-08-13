import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/dartdoc/dartdoc_generator.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:stardust/src/utils/logger.dart';
import 'package:test/test.dart';

void main() {
  group('DartdocGenerator.buildTopBar', () {
    test('renders name, API badge, back-to-docs link, and adapts to dark theme', () {
      final bar = DartdocGenerator.buildTopBar(name: 'My Docs', homeUrl: '/docs/', primaryColor: '#6366f1');

      expect(bar, contains('class="sd-apibar"'));
      expect(bar, contains('My Docs'));
      expect(bar, contains('sd-apibar__badge'));
      expect(bar, contains('href="/docs/"'));
      expect(bar, contains('← Back to docs'));
      expect(bar, contains('.dark-theme .sd-apibar')); // theme-adaptive
    });

    test('uses the site primary color as the accent', () {
      final bar = DartdocGenerator.buildTopBar(name: 'X', homeUrl: '/', primaryColor: '#ff3366');

      expect(bar, contains('background:#ff3366'));
    });

    test('rejects a hostile primary color, falling back to the default accent', () {
      final bar = DartdocGenerator.buildTopBar(name: 'X', homeUrl: '/', primaryColor: 'red;}</style><script>');

      expect(bar, isNot(contains('<script>')));
      expect(bar, isNot(contains('red;}')));
      expect(bar, contains('background:#6366f1')); // fell back to the default
    });

    test('renders a single logo image when a light logo is given without a distinct dark one', () {
      final bar = DartdocGenerator.buildTopBar(name: 'X', homeUrl: '/', primaryColor: '#000', logoLight: '/logo.svg');

      expect(bar, contains('<img src="/logo.svg" alt="">'));
      expect(bar, isNot(contains('class="sd-logo-light"')));
    });

    test('renders light and dark logo variants when both differ', () {
      final bar = DartdocGenerator.buildTopBar(
        name: 'X',
        homeUrl: '/',
        primaryColor: '#000',
        logoLight: '/l.svg',
        logoDark: '/d.svg',
      );

      expect(bar, contains('class="sd-logo-light" src="/l.svg"'));
      expect(bar, contains('class="sd-logo-dark" src="/d.svg"'));
    });

    test('escapes the name and url', () {
      final bar = DartdocGenerator.buildTopBar(name: 'A & B <x>', homeUrl: '/"', primaryColor: '#000');

      expect(bar, contains('A &amp; B &lt;x&gt;'));
      expect(bar, isNot(contains('A & B <x>')));
      expect(bar, contains('href="/&quot;"'));
    });

    test('uses and escapes localized API and back-to-docs labels', () {
      final bar = DartdocGenerator.buildTopBar(
        name: 'X',
        homeUrl: '/',
        primaryColor: '#000',
        apiLabel: 'API <reference> & "guide"',
        backToDocs: "Retour aux docs & l'accueil <ici>",
      );

      expect(bar, contains('API &lt;reference&gt; &amp; &quot;guide&quot;'));
      expect(bar, contains('Retour aux docs &amp; l&#39;accueil &lt;ici&gt;'));
      expect(bar, isNot(contains('API <reference>')));
      expect(bar, isNot(contains("l'accueil <ici>")));
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

    test('injects the top-bar and theme-sync after <body> (with attributes)', () {
      final out = DartdocGenerator.injectChrome('<html><body class="light">X</body>', bar);

      expect(out, contains('<div class="sd-apibar">BAR</div>'));
      expect(out.indexOf('<div class="sd-apibar">'), greaterThan(out.indexOf('<body')));
    });

    test('injects a two-way theme-sync script (site theme <-> dartdoc)', () {
      final out = DartdocGenerator.injectChrome('<body></body>', bar);

      expect(out, contains('localStorage.getItem("theme")')); // reads the site key
      expect(out, contains('colorTheme')); // writes dartdoc's key
      expect(out, contains('MutationObserver')); // mirrors dartdoc's toggle back
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

  group('DartdocGenerator.generate error handling', () {
    test('throws a ContentException when dart doc cannot be launched', () async {
      final out = await Directory.systemTemp.createTemp('stardust-dd-err-');
      try {
        final generator = DartdocGenerator(
          packagePath: '/no/such/package/path/zzz', // missing working dir -> ProcessException
          outputDir: out.path,
          config: const StardustConfig(name: 'X'),
          logger: Logger(onLog: (_) {}),
        );
        await expectLater(generator.generate(), throwsA(isA<ContentException>()));
      } finally {
        await out.delete(recursive: true);
      }
    });

    test('throws a ContentException when dart doc exits non-zero', () async {
      final pkg = await Directory.systemTemp.createTemp('stardust-dd-nopub-'); // exists, no pubspec
      final out = await Directory.systemTemp.createTemp('stardust-dd-err2-');
      try {
        final generator = DartdocGenerator(
          packagePath: pkg.path,
          outputDir: out.path,
          config: const StardustConfig(name: 'X'),
          logger: Logger(onLog: (_) {}),
        );
        await expectLater(generator.generate(), throwsA(isA<ContentException>()));
      } finally {
        await pkg.delete(recursive: true);
        await out.delete(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 1)));
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

        const config = StardustConfig(
          name: 'Fixture',
          url: 'https://x.dev',
          logo: LogoConfig(single: '/logo.svg'),
          i18n: I18nConfig(
            strings: I18nStrings(
              dartdocApi: 'Référence & API',
              dartdocBackToDocs: 'Retour <aux docs>',
            ),
          ),
        );
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
        expect(html, contains('Référence &amp; API'));
        expect(html, contains('Retour &lt;aux docs&gt;'));
        expect(html, isNot(contains('← Back to docs')));
        expect(html, contains('id="dartdoc-main-content" data-pagefind-body'));
      } finally {
        await pkg.delete(recursive: true);
        await out.delete(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
