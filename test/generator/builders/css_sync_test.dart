import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stardust/src/generator/builders/stardust_css.dart';
import 'package:test/test.dart';

void main() {
  group('css sync', () {
    test('embedded sections match assets/css/', () {
      final files = Directory('assets/css').listSync().whereType<File>().where((f) => f.path.endsWith('.css')).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      final keys = files.map((f) => p.basenameWithoutExtension(f.path).replaceFirst(RegExp(r'^\d+-'), '')).toList();
      expect(
        stardustCssSections.keys.toList(),
        equals(keys),
        reason: 'assets/css/ changed — run `dart run tool/embed_css.dart` to regenerate',
      );

      for (final (index, file) in files.indexed) {
        expect(
          stardustCssSections[keys[index]]?.replaceAll('\r\n', '\n'),
          equals(file.readAsStringSync().replaceAll('\r\n', '\n')),
          reason: '${file.path} changed — run `dart run tool/embed_css.dart` to regenerate',
        );
      }
    });
  });
}
