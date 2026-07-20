import 'package:stardust/src/utils/text_utils.dart';
import 'package:test/test.dart';

void main() {
  group('levenshtein', () {
    test('identical strings are distance 0', () {
      expect(levenshtein('search', 'search'), equals(0));
    });

    test('counts inserts, deletes, and substitutions', () {
      expect(levenshtein('search', 'serch'), equals(1)); // delete
      expect(levenshtein('serch', 'search'), equals(1)); // insert
      expect(levenshtein('serach', 'search'), equals(2)); // two substitutions
      expect(levenshtein('', 'abc'), equals(3));
      expect(levenshtein('abc', ''), equals(3));
    });
  });

  group('closestMatch', () {
    const candidates = ['search', 'sidebar', 'theme', 'installation'];

    test('finds the nearest within the distance budget', () {
      expect(closestMatch('serch', candidates), equals('search'));
      expect(closestMatch('instalation', candidates), equals('installation'));
    });

    test('returns null when nothing is close enough', () {
      expect(closestMatch('xyz', candidates), isNull);
    });

    test('honors maxDistance', () {
      expect(closestMatch('seaxxh', candidates, maxDistance: 1), isNull);
      expect(closestMatch('seaxxh', candidates, maxDistance: 2), equals('search'));
    });

    test('caseInsensitive matches across case', () {
      expect(closestMatch('SEARCH', candidates, caseInsensitive: true), equals('search'));
      expect(closestMatch('SEARCH', candidates), isNull);
    });
  });
}
