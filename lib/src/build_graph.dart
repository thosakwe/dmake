import 'dart:async';
import 'dart:collection';
import 'step.dart';

final BuildGraph buildGraph = new BuildGraph._();

Step step(String input, Iterable<String> outputs,
    FutureOr<bool> Function() callback) {
  var step = new Step(
      input, new SplayTreeSet<String>.from(outputs).toList(), callback);
  buildGraph._steps.add(step);
  return step;
}

class BuildGraph {
  final Set<Step> _steps = new Set<Step>();

  BuildGraph._();

  UnmodifiableListView<Step> get steps =>
      new UnmodifiableListView<Step>(_steps);
}
