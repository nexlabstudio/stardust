import 'package:path/path.dart' as p;
import 'package:stardust/src/generator/locale_materializer.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('LocaleContentMaterializer', () {
    late MockFileSystem fileSystem;

    setUp(() => fileSystem = MockFileSystem());

    Future<({String dir, Set<String> untranslated})> materialize({
      Set<String> excludeSubdirs = const {'es'},
      Set<String> localeCodes = const {'es'},
    }) =>
        LocaleContentMaterializer(fileSystem: fileSystem).materialize(
          defaultDir: 'docs',
          localeCode: 'es',
          subdir: p.join('docs', 'es'),
          excludeSubdirs: excludeSubdirs,
          localeCodes: localeCodes,
        );

    test('resolves subdirectory translations and reports the fallbacks', () async {
      fileSystem.addFile('docs/index.md', '# Home');
      fileSystem.addFile('docs/guide.md', '# Guide');
      fileSystem.addFile('docs/api/auth.md', '# Auth');
      fileSystem.addFile('docs/es/guide.md', '# Guía');

      final result = await materialize();

      expect(fileSystem.fileAt(p.join(result.dir, 'guide.md')), '# Guía', reason: 'subdir translation wins');
      expect(fileSystem.fileAt(p.join(result.dir, 'index.md')), '# Home', reason: 'fallback to default');
      expect(result.untranslated, {'/', '/api/auth'});
    });

    test('resolves locale-suffixed siblings and keeps them out of the base set', () async {
      fileSystem.addFile('docs/index.md', '# Home');
      fileSystem.addFile('docs/guide.md', '# Guide');
      fileSystem.addFile('docs/guide.es.md', '# Guía');

      final result = await materialize(excludeSubdirs: const {});

      expect(fileSystem.fileAt(p.join(result.dir, 'guide.md')), '# Guía', reason: 'suffix translation used');
      expect(fileSystem.hasFile(p.join(result.dir, 'guide.es.md')), isFalse, reason: 'suffix file is not a page');
      expect(result.untranslated, {'/'}, reason: 'only index fell back');
    });

    test('prefers a suffix sibling over a subdirectory translation', () async {
      fileSystem.addFile('docs/guide.md', '# Guide');
      fileSystem.addFile('docs/guide.es.md', '# Suffix');
      fileSystem.addFile('docs/es/guide.md', '# Subdir');

      final result = await materialize();

      expect(fileSystem.fileAt(p.join(result.dir, 'guide.md')), '# Suffix');
    });

    test('excludes other locales suffix files and subdirs from the base set', () async {
      fileSystem.addFile('docs/index.md', '# Home');
      fileSystem.addFile('docs/index.fr.md', '# Accueil');
      fileSystem.addFile('docs/fr/guide.md', '# Guide FR');

      final result = await materialize(excludeSubdirs: const {'es', 'fr'}, localeCodes: const {'es', 'fr'});

      expect(fileSystem.hasFile(p.join(result.dir, 'index.fr.md')), isFalse);
      expect(fileSystem.hasFile(p.join(result.dir, 'fr', 'guide.md')), isFalse);
      expect(result.untranslated, {'/'});
    });

    test('missing translations leave every page untranslated', () async {
      fileSystem.addFile('docs/index.md', '# Home');

      expect((await materialize()).untranslated, {'/'});
    });
  });
}
