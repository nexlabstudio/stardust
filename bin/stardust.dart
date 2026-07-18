import 'dart:io';

import 'package:stardust/src/cli/cli_runner.dart';

Future<void> main(List<String> args) async {
  exitCode = await StardustCliRunner().run(args);
}
