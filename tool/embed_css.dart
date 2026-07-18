import 'dart:io';

import 'package:path/path.dart' as p;

/// Regenerates lib/src/generator/builders/stardust_css.dart from assets/css/.
///
/// Run after any CSS change: `dart run tool/embed_css.dart`
/// The css_sync test fails until the two are in sync.
///
/// Files are embedded in filename order (hence the NN- prefixes); the map key
/// is the filename without prefix and extension.
void main() {
  final files = Directory('assets/css').listSync().whereType<File>().where((f) => f.path.endsWith('.css')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln('no css files found under assets/css');
    exit(1);
  }

  final buffer = StringBuffer('''
// GENERATED FILE — do not edit by hand.
// Source: assets/css/. Regenerate with: dart run tool/embed_css.dart

/// The site stylesheet sections, embedded so the generator works from the
/// compiled binary without needing the css files on disk. Iteration order is
/// the assets/css filename order.
const stardustCssSections = <String, String>{
''');

  for (final file in files) {
    final content = file.readAsStringSync();
    if (content.contains("'''") || content.contains(r'$')) {
      stderr.writeln('${file.path} contains triple quotes or \$ — cannot embed as a raw string');
      exit(1);
    }
    final key = p.basenameWithoutExtension(file.path).replaceFirst(RegExp(r'^\d+-'), '');
    buffer.writeln("  '$key': r'''\n$content''',");
  }

  buffer.writeln('};');
  File('lib/src/generator/builders/stardust_css.dart').writeAsStringSync(buffer.toString());
  stdout.writeln('lib/src/generator/builders/stardust_css.dart regenerated (${files.length} sections)');
}
