import 'package:path/path.dart' as p;
import 'package:stardust/src/generator/locale_materializer.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

void main() {
  group('LocaleContentMaterializer', () {
    late MockFileSystem fileSystem;

    setUp(() => fileSystem = MockFileSystem());

    test('merges translations over the default and reports the fallbacks', () async {
      fileSystem.addFile('docs/index.md', '# Home');
      fileSystem.addFile('docs/guide.md', '# Guide');
      fileSystem.addFile('docs/api/auth.md', '# Auth');
      fileSystem.addFile('docs/es/guide.md', '# Guía');

      final result = await LocaleContentMaterializer(fileSystem: fileSystem).materialize(
        defaultDir: 'docs',
        translatedDir: p.join('docs', 'es'),
        excludeSubdirs: {'es'},
      );

      expect(fileSystem.fileAt(p.join(result.dir, 'guide.md')), '# Guía', reason: 'translation wins');
      expect(fileSystem.fileAt(p.join(result.dir, 'index.md')), '# Home', reason: 'fallback to default');
      expect(fileSystem.fileAt(p.join(result.dir, 'api', 'auth.md')), '# Auth');
      expect(result.untranslated, {'/', '/api/auth'}, reason: 'guide was translated, the rest fell back');
    });

    test('excludes locale subdirs from the default content', () async {
      fileSystem.addFile('docs/index.md', '# Home');
      fileSystem.addFile('docs/es/index.md', '# Inicio');
      fileSystem.addFile('docs/fr/index.md', '# Accueil');

      final result = await LocaleContentMaterializer(fileSystem: fileSystem).materialize(
        defaultDir: 'docs',
        translatedDir: p.join('docs', 'es'),
        excludeSubdirs: {'es', 'fr'},
      );

      expect(fileSystem.hasFile(p.join(result.dir, 'es', 'index.md')), isFalse);
      expect(fileSystem.hasFile(p.join(result.dir, 'fr', 'index.md')), isFalse);
      expect(result.untranslated, isEmpty, reason: 'index.md was translated');
    });

    test('missing translation dir leaves every page untranslated', () async {
      fileSystem.addFile('docs/index.md', '# Home');

      final result = await LocaleContentMaterializer(fileSystem: fileSystem)
          .materialize(defaultDir: 'docs', translatedDir: p.join('docs', 'de'));

      expect(result.untranslated, {'/'});
    });
  });
}
