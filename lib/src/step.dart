import 'dart:async';

class Step {
  final String input;

  final List<String> outputs;

  final FutureOr<bool> Function() callback;

  Step(this.input, this.outputs, this.callback);
}
