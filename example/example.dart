import 'package:dmake/dmake.dart';
import 'package:dmake/dart.dart';

main(List<String> args) {
  make(args, () {
    // Run all web/ entrypoints through dart2js.
    all(glob('web/*.dart', recursive: false), dart2js);
  });
}
