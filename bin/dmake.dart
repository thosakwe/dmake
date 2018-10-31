import 'dart:io';
import 'package:args/args.dart';
import 'package:dmake/dmake.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;

var argParser = new ArgParser()
  ..addFlag('help',
      abbr: 'h', negatable: false, help: 'Print this help information.')
  ..addOption('target',
      abbr: 't',
      defaultsTo: 'all',
      help: 'The name of the Dart file under tool/ to run.');

main(List<String> args) async {
  try {
    var argResults = argParser.parse(args);

    if (argResults['help'] as bool) {
      stdout
        ..writeln('usage: dmake [options...]')
        ..writeln()
        ..writeln(argParser.usage);
      return;
    }

    var target = argResults['target'] as String;
    var filename = p.join('tool', p.setExtension(target, '.dart'));

    if (!await new File(filename).exists()) {
      throw new ArgParserException(
          'make: *** No rule to make target `$target`.  Stop.');
    }

    // Try to snapshot it
    var snapshot = p.setExtension(
        p.join('.dart_tool', 'dmake', 'snapshots', p.basename(filename)),
        '.snapshot.${isRelease ? 'release' : 'development'}.dart2');

    var shouldRegen = !await new File(snapshot).exists();

    if (!shouldRegen) {
      var fStamp = await new File(filename).lastModified();
      var sStamp = await new File(snapshot).lastModified();
      shouldRegen = sStamp.isBefore(fStamp);
    }

    if (shouldRegen) {
      print(lightGray.wrap('Snapshotting $filename into $snapshot...'));
      await new Directory(p.dirname(snapshot)).create(recursive: true);

      var result = await Process.run(
          Platform.executable, ['--snapshot=$snapshot', filename]);

      if (result.exitCode != 0) {
        snapshot = filename;
      }
    }

    // Next, start the snapshot.
    var dart = await Process.start(Platform.resolvedExecutable,
        flatten([snapshot, argResults.rest.skip(1)]),
        mode: ProcessStartMode.inheritStdio);

    exitCode = await dart.exitCode;
  } on ArgParserException catch (e) {
    exitCode = ExitCode.usage.code;
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln('usage: dmake [options...]')
      ..writeln()
      ..writeln(argParser.usage);
  }
}
