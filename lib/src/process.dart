import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'top_level.dart';

Future<bool> Function() run_process(String executable,
    {Iterable<String> arguments: const [],
    String workingDirectory,
    Map<String, String> environment: const {}}) {
  return () async {
    var result = await Process.run(executable, arguments.toList(),
        workingDirectory: workingDirectory,
        environment: environment,
        stdoutEncoding: utf8,
        stderrEncoding: utf8);

    if (result.exitCode != 0) {
      var invocation = (executable + ' ' + arguments.join(' ')).trim();
      var msg = '`$invocation` failed with exit code ${result.exitCode}.';
      var b = new StringBuffer()
        ..writeln(result.stdout)
        ..writeln(result.stderr);
      log.severe(msg, b.toString().trim());
      return false;
    } else {
      return true;
    }
  };
}
