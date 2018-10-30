# dmake
Simple, flexible task engine in Dart.

In `tool/all.dart`:

```dart
import 'package:dmake/dmake.dart';
import 'package:dmake/dart.dart';

main(List<String> args) {
  make(args, () {
    all(glob('web/*.dart', recursive: false), dart2js);
  });
}
```

Then, run `pub run dmake`.
Run `pub run dmake --help` for help.

You can also `pub global activate dmake`.