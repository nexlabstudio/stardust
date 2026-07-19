import 'dart:io';

/// Regenerates lib/src/content/utils/lucide_icons.dart from the lucide-static
/// npm package, so icons render as build-time inline SVG with no CDN script.
///
/// Run to upgrade the icon set: `dart run tool/vendor_lucide.dart [version]`
void main(List<String> args) async {
  final version = args.firstOrNull ?? '1.25.0';
  final url = 'https://registry.npmjs.org/lucide-static/-/lucide-static-$version.tgz';
  final workDir = Directory.systemTemp.createTempSync('lucide_vendor');

  try {
    stdout.writeln('Downloading lucide-static $version...');
    final tarball = File('${workDir.path}/lucide.tgz');
    final client = HttpClient();
    final response = await (await client.getUrl(Uri.parse(url))).close();
    if (response.statusCode != 200) {
      stderr.writeln('Download failed: HTTP ${response.statusCode}');
      exit(1);
    }
    await response.pipe(tarball.openWrite());
    client.close();

    final extract = Process.runSync('tar', ['-xzf', tarball.path, '-C', workDir.path]);
    if (extract.exitCode != 0) {
      stderr.writeln('Extract failed: ${extract.stderr}');
      exit(1);
    }

    final iconsDir = Directory('${workDir.path}/package/icons');
    final svgInner = RegExp(r'<svg[^>]*>\s*(.*?)\s*</svg>', dotAll: true);
    final icons = <String, String>{};

    final files = iconsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.svg')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last.replaceAll('.svg', '');
      final content = file.readAsStringSync();
      if (svgInner.firstMatch(content)?.group(1) case final inner?) {
        icons[name] = inner.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
      }
    }

    if (icons.length < 500) {
      stderr.writeln('Suspiciously few icons (${icons.length}) — aborting');
      exit(1);
    }

    final buffer = StringBuffer('''
// GENERATED FILE — do not edit by hand.
// Source: lucide-static@$version (https://lucide.dev, ISC license).
// Regenerate with: dart run tool/vendor_lucide.dart

/// Inner SVG markup per Lucide icon name, rendered inline at build time.
const lucideIconVersion = '$version';
const lucideIcons = <String, String>{
''');
    for (final entry in icons.entries) {
      buffer.writeln("  '${entry.key}': '${entry.value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}',");
    }
    buffer.writeln('};');

    File('lib/src/content/utils/lucide_icons.dart').writeAsStringSync(buffer.toString());
    Process.runSync('dart', ['format', '-l', '120', 'lib/src/content/utils/lucide_icons.dart']);
    stdout.writeln('lib/src/content/utils/lucide_icons.dart regenerated (${icons.length} icons)');
  } finally {
    workDir.deleteSync(recursive: true);
  }
}
