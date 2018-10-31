# dmake
Simple, flexible build system in Dart.
Supports incremental builds, file watching,
and snapshotting for faster startup.

## Usage
`dmake` is a DSL that creates a simple graph of inputs
and outputs.

Try compiling a Dart app! In `tool/all.dart`:

```dart
import 'package:dmake/dmake.dart';
import 'package:dmake/dart.dart';

main(List<String> args) {
  make(args, () {
    if (isRelease) {
      // Build to JS in release mode.
      dart2js('web/main.dart');
    } else {
      // Run all web/ files through dartdevc.
      all(glob('web/*.dart', recursive: false), dartdevc);
    }
  });
}
```

Then, run `dart tool/all.dart`. All of your `.dart` files in
`web/` will be built to JavaScript via the Dart dev compiler.

### Release mode
It's pretty common to have different build rules in debug and
release mode. To switch over to `dart2js`, run
`dart tool/all.dart --release`.

### Snapshotting Builds
Build systems are called very often, and therefore should
start up *quickly*.
Using the `dmake` executable, you can easily snapshot your
build script.

To create a snapshot of `tool/all.dart`, just
run `pub run dmake`.

If you had another file, say, `tool/foo.dart`, the command
would become `pub run dmake -t foo`.

The single caveat is that to distinguish between arguments
passed to the `dmake` toplevel and to your actual script,
you need to separate them with a `--`.

For example, to run in release mode:

```bash
pub run dmake -- --release
```

Run `pub run dmake --help` for help.

You can also `pub global activate dmake`. In this case,
you can simply run `dmake`, `dmake -t foo`, etc.

## Infrastructure
`dmake` includes utilities for quickly building files in different languages:
* `package:dmake/dart.dart`
* `package:dmake/sass.dart`