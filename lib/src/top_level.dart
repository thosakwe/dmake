import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:graphs/graphs.dart';
import 'package:io/ansi.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/transformers.dart';
import 'package:watcher/watcher.dart';
import 'build_graph.dart';
import 'step.dart';

bool get isRelease => Zone.current[#isRelease] as bool ?? false;

Logger get log => Zone.current[#log] as Logger ?? _topLevel;

final Logger _topLevel = new Logger('dmake');

Future make(List<String> args, FutureOr Function() callback) async {
  var sw = new Stopwatch();
  hierarchicalLoggingEnabled = true;

  var argParser = new ArgParser()
    ..addFlag('help', help: 'Print this help information.˝', negatable: false)
    ..addFlag('release', help: 'Build in release mode.', negatable: false)
    ..addFlag('watch',
        help: 'Watch for file changes.', abbr: 'w', negatable: false)
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

    await callback();

    if (buildGraph.steps.isEmpty) {
      log.severe('No targets specified.');
      return exitCode = 1;
    }

    var components = stronglyConnectedComponents<String, Step>(
        buildGraph.steps,
        (s) => s.input,
        (s) => buildGraph.steps.where((x) => s.outputs.contains(x.input)));

    return await zone.run(() async {
      Future doBuild() async {
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
        log.info('Done in ${sw.elapsedMilliseconds}ms.');
      }

      await doBuild();

      if (argResults['watch'] as bool) {
        // Changes to items in the first level will trigger builds...
        for (var step in components[0]) {
          new FileWatcher(step.input)
              .events
              .transform(new DebounceStreamTransformer(
                  const Duration(milliseconds: 250)))
              .listen((ev) async {
            if (ev.type != ChangeType.REMOVE) {
              log.info('${step.input} changed. Rebuilding...');
              await doBuild();
            }
          });
        }
      }
    });
  } on ArgParserException catch (e) {
    stderr.writeln('${red.wrap('fatal error: ')} ${e.message}');
    return null;
  } finally {
    sw.stop();
  }
}
