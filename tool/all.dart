import 'package:dmake/dmake.dart';
import 'package:dmake/dart.dart';
import 'package:dmake/sass.dart';

main(List<String> args) {
  make(args, () {
    if (isRelease) {
      // Build to JS in release mode.
      dart2js('web/main.dart');
    } else {
      // Run all web/ files through dartdevc.
      all(glob('web/*.dart', recursive: false), dartdevc);
    }

    // Compile SASS files.
    all(glob('web/*.sass'), sass);
  });
}
