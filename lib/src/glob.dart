import 'dart:io';
import 'package:glob/glob.dart';
import 'top_level.dart';

List<String> glob(String pattern,
    {bool caseSensitive, bool recursive: true, bool followLinks: true}) {
  try {
    var g = new Glob(pattern, recursive: true, caseSensitive: caseSensitive);
    return g.listSync(followLinks: followLinks).map((f) => f.path).toList();
  } on IOException {
    log.warning(
        "Couldn't list files under glob '$pattern'; you may have a typo.");
    return [];
  }
}
