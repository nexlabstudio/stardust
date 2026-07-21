import 'package:stardust/src/config/config.dart';
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

  group('VersionEntry.fromYaml', () {
    test('reads an optional per-version sidebar', () {
      final entry = VersionEntry.fromYaml({
        'version': '1.0',
        'path': '/v1/',
        'sidebar': [
          {
            'group': 'Guides',
            'pages': ['index', 'legacy'],
          },
        ],
      });

      expect(entry.sidebar?.single.group, 'Guides');
      expect(entry.sidebar?.single.pages.map((p) => p.slug), ['index', 'legacy']);
    });

    test('leaves the sidebar null when not given', () {
      expect(VersionEntry.fromYaml({'version': '1.0', 'path': '/v1/'}).sidebar, isNull);
    });
  });

  group('equality', () {
    test('DirSource compares by dir and never equals another type', () {
      expect(const DirSource('a') == const DirSource('a'), isTrue);
      expect(const DirSource('a') == const DirSource('b'), isFalse);
      expect(const DirSource('a') == const GitSource('a'), isFalse);
      expect(const DirSource('a').hashCode, const DirSource('a').hashCode);
    });

    test('GitSource compares by ref and never equals another type', () {
      expect(const GitSource('r') == const GitSource('r'), isTrue);
      expect(const GitSource('r') == const GitSource('s'), isFalse);
      expect(const GitSource('r') == const DirSource('r'), isFalse);
      expect(const GitSource('r').hashCode, const GitSource('r').hashCode);
    });
  });
}
