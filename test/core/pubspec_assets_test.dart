import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every asset folder `pubspec.yaml` declares must hold files. Git keeps no
/// empty folder, so a declared empty one exists here but not on a fresh clone
/// (Codemagic), where the build stops on the missing directory (cleanup audit
/// `19`, run 11: `assets/images/onboarding/`).
void main() {
  final declared = [
    for (final line in File('pubspec.yaml').readAsLinesSync())
      if (RegExp(r'^\s+- (assets/\S*/)\s*$').firstMatch(line) case final m?)
        m.group(1)!,
  ];

  test('pubspec declares asset folders', () {
    expect(declared, contains('assets/translations/'));
  });

  for (final folder in declared) {
    test('$folder holds files', () {
      final files = Directory(folder).existsSync()
          ? Directory(folder).listSync().whereType<File>()
          : const <File>[];
      expect(files, isNotEmpty, reason: '$folder is empty or missing');
    });
  }
}
