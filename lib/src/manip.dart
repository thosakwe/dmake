import 'step.dart';

List<String> flag(String name, bool value) {
  return value == true ? [name] : [];
}

List<String> flatten(Iterable stuff) {
  return stuff.fold<List<String>>([], (out, x) {
    if (x is Iterable) {
      return out..addAll(flatten(x));
    } else if (x == null) {
      return out;
    } else {
      var s = x.toString();
      return s.trim().isEmpty ? out : out
        ..add(s);
    }
  });
}

List<String> exclude(Iterable<String> arr, Iterable<String> forbidden) {
  return arr.where((x) => !forbidden.contains(x)).toList();
}

void all(Iterable<String> sources, Step Function(String) f) {
  sources.forEach(f);
}
