import 'dart:io';

/// Regenerates lib/src/config/stardust_schema.dart from schema/stardust.json.
///
/// Run after any schema change: `dart run tool/embed_schema.dart`
/// The schema_sync test fails until the two files match.
void main() {
  final json = File('schema/stardust.json').readAsStringSync();
  if (json.contains("'''")) {
    stderr.writeln('schema/stardust.json contains triple quotes — cannot embed');
    exit(1);
  }

  File('lib/src/config/stardust_schema.dart').writeAsStringSync('''
// GENERATED FILE — do not edit by hand.
// Source: schema/stardust.json. Regenerate with: dart run tool/embed_schema.dart

/// The stardust.yaml JSON schema, embedded so the config validator works
/// from the compiled binary without needing the schema file on disk.
const stardustSchemaJson = r\'\'\'
$json\'\'\';
''');
  stdout.writeln('lib/src/config/stardust_schema.dart regenerated');
}
