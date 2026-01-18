import 'package:stardust/src/cli/cli_runner.dart';

Future<void> main(List<String> args) async =>
    await StardustCliRunner().run(args);
