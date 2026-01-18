import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/build_command.dart';
import 'commands/dev_command.dart';
import 'commands/init_command.dart';
import 'commands/openapi_command.dart';

/// Main CLI runner for Stardust
class StardustCliRunner extends CommandRunner<int> {
  StardustCliRunner()
      : super(
          'stardust',
          'A Dart-native documentation framework. Beautiful docs, zero config.',
        ) {
    addCommand(InitCommand());
    addCommand(BuildCommand());
    addCommand(DevCommand());
    addCommand(OpenApiCommand());

    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the version of Stardust.',
    );
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      if (argResults['version'] == true) {
        stdout.writeln('Stardust v0.1.0');
        return 0;
      }

      final result = await runCommand(argResults);
      return result ?? 0;
    } on UsageException catch (e) {
      stderr.writeln(e.message);
      stderr.writeln('');
      stderr.writeln(e.usage);
      return 64;
    } catch (e, stackTrace) {
      stderr.writeln('Error: $e');
      stderr.writeln(stackTrace);
      return 1;
    }
  }
}
