import 'package:stardust/src/config/version_source.dart';
import 'package:stardust/src/utils/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('VersionSource.fromYaml', () {
    test('reads a bare string as a content directory', () {
      expect(VersionSource.fromYaml('versions/1.0'), const DirSource('versions/1.0'));
    });

    test('reads {tag} and {ref} maps as git sources', () {
      expect(VersionSource.fromYaml({'tag': 'v1.0.0'}), const GitSource('v1.0.0'));
      expect(VersionSource.fromYaml({'ref': 'release/1.x'}), const GitSource('release/1.x'));
    });

    test('rejects a map that is neither tag nor ref', () {
      expect(() => VersionSource.fromYaml({'branch': 'main'}), throwsA(isA<ConfigException>()));
    });
  });
}
