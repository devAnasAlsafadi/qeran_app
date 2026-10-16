import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tools that only generate files stay out of the shipped app (cleanup audit
/// `19`, run 11): a runtime dependency ships its native plugin even when no
/// Dart code calls it.
void main() {
  /// The pubspec sections (`dependencies` / `dev_dependencies`) each package
  /// is listed under.
  Map<String, Set<String>> sections() {
    final found = <String, Set<String>>{};
    String? section;
    for (final line in File('pubspec.yaml').readAsLinesSync()) {
      if (RegExp(r'^(\w+):').firstMatch(line) case final m?) {
        section = m.group(1);
      } else if (RegExp(r'^  (\w+):').firstMatch(line) case final m?) {
        if (section == 'dependencies' || section == 'dev_dependencies') {
          (found[m.group(1)!] ??= {}).add(section!);
        }
      }
    }
    return found;
  }

  test('pubspec sections parse', () {
    expect(sections()['flutter_bloc'], {'dependencies'});
    expect(sections()['mocktail'], {'dev_dependencies'});
  });

  test('flutter_native_splash is a dev dependency only', () {
    expect(sections()['flutter_native_splash'], {'dev_dependencies'});
  });

  // The Android icons are hand-made (12% inset); a run with Android on would
  // overwrite them. `android: false` also gates the adaptive and monochrome
  // layers.
  test('flutter_launcher_icons leaves Android alone', () {
    final android = [
      for (final line in File('flutter_launcher_icons.yaml').readAsLinesSync())
        if (RegExp(r'^  android:\s*(.+?)\s*$').firstMatch(line) case final m?)
          m.group(1),
    ];
    expect(android, ['false']);
  });
}
