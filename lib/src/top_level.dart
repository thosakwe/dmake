import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:graphs/graphs.dart';
import 'package:io/ansi.dart';
import 'package:logging/logging.dart';
import 'build_graph.dart';
import 'step.dart';

bool get isRelease => Zone.current[#isRelease] as bool;

Logger get log => Zone.current[#log] as Logger ?? _topLevel;

final Logger _topLevel = new Logger('dmake');

Future make(List<String> args, FutureOr Function() callback) {
  var sw = new Stopwatch();
  hierarchicalLoggingEnabled = true;

  var argParser = new ArgParser()
    ..addFlag('help', help: 'Print this help information.˝', negatable: false)
    ..addFlag('release', help: 'Build in release mode.', negatable: false)
    ..addFlag('verbose', help: 'Print verbose output.', negatable: false);

  try {
    var argResults = argParser.parse(args);

    if (argResults['help'] as bool) {
      stdout
        ..writeln('usage: dmake [options...]')
        ..writeln()
        ..writeln(argParser.usage);
      return new Future.value();
    }

    _topLevel.onRecord.listen((rec) {
      var color = defaultForeground;

      if (rec.level == Level.SEVERE) {
        color = red;
      } else if (rec.level == Level.INFO) {
        color = cyan;
      } else if (rec.level == Level.WARNING) {
        color = yellow;
      } else if (rec.level <= Level.CONFIG) {
        color = lightGray;
      }

      var level = wrapWith(rec.level.toString(), [styleBold, color]);
      print('$level: ${darkGray.wrap(rec.loggerName)}: ${rec.message}');

      if (argResults['verbose'] as bool) {
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      }
    });

    var zone =
        Zone.current.fork(zoneValues: {#isRelease: argResults['release']});

    return zone.run(() async {
      await callback();

      var components = stronglyConnectedComponents<String, Step>(
          buildGraph.steps,
          (s) => s.input,
          (s) => buildGraph.steps.where((x) => s.outputs.contains(x.input)));

      sw.start();
      for (var cmp in components) {
        for (var step in cmp) {
          var input = new File(step.input);
          var shouldRun = !await input.exists();

          if (!shouldRun) {
            // If the file exists, maybe an output has changed.
            // Check all the timestamps.
            var stamp = await input.lastModified();

            for (var output in step.outputs) {
              var f = new File(output);

              if (!await f.exists()) {
                shouldRun = true;
                break;
              } else {
                var s = await f.lastModified();

                if (s.isBefore(stamp)) {
                  shouldRun = true;
                  break;
                }
              }
            }
          }

          if (shouldRun) {
            log.info(
                'Building ${step.outputs.map(darkGray.wrap).join(', ')} from ${step.input}...');
            await step.callback();
          }
        }
      }

      sw.stop();
      log.info('Done in ${sw.elapsedMilliseconds}ms');
    });
  } on ArgParserException catch (e) {
    stderr.writeln('${red.wrap('fatal error: ')} ${e.message}');
    return new Future.value();
  } finally {
    sw.stop();
  }
}
