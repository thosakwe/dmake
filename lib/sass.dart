import 'dart:io';
import 'package:path/path.dart' as p;
import 'src/manip.dart';
import 'dmake.dart';

Step sass(String input, {bool minify, Iterable<String> loadPaths: const []}) {
  minify ??= isRelease;
  var outputs = ['.css'].map((x) => p.setExtension(input, x));
  return step(
    input,
    outputs,
    () async {
      var args = flatten([
        flag('--scss', p.extension(input) == '.scss'),
        '--style',
        minify ? 'compressed' : 'nested',
        loadPaths.map((x) => option('-I', x)),
        input,
      ]);

      var result = await Process.run('sass', args);

      if (result.exitCode != 0) {
        var invocation = ('sass' + ' ' + args.join(' ')).trim();
        var msg = '`$invocation` failed with exit code ${result.exitCode}.';
        var b = new StringBuffer()
          ..writeln(result.stdout)
          ..writeln(result.stderr);
        log.severe(msg, b.toString().trim());
        return false;
      } else {
        var file = new File(p.setExtension(input, '.css'));
        await file.create(recursive: true);
        await file.writeAsString(result.stdout as String);
        return true;
      }
    },
  );
}
