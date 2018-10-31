import 'package:path/path.dart' as p;
import 'src/manip.dart';
import 'dmake.dart';

Step dartdevc(String input, {String module: 'amd'}) {
  var outputs = ['.dart.js', '.dart.js.sum', '.dart.js.map']
      .map((x) => p.setExtension(input, x));
  var output = p.setExtension(input, '.dart.js');
  return step(
      input,
      outputs,
      run_process('dartdevc',
          arguments: flatten(['--out', output, '--modules', module, input])));
}

Step dart2js(String input, {bool minify}) {
  minify ??= isRelease;
  var outputs = ['.dart.js', '.dart.js.deps', '.dart.js.map']
      .map((x) => p.setExtension(input, x));
  var output = p.setExtension(input, '.dart.js');
  return step(
      input,
      outputs,
      run_process('dart2js',
          arguments: flatten(['-o', output, flag('-m', minify), input])));
}
