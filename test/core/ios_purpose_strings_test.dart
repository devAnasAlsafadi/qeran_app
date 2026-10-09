import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F1: the iOS permission prompts (camera, microphone, photo library) in both
/// languages — English in `Info.plist` and `en.lproj`, Arabic in `ar.lproj`,
/// and both files in the Runner's resources, since no Mac checks the project.
const _keys = [
  'NSCameraUsageDescription',
  'NSMicrophoneUsageDescription',
  'NSPhotoLibraryUsageDescription',
];

final _arabic = RegExp('[؀-ۿ]');

/// `"key" = "value";` lines of an `InfoPlist.strings`.
Map<String, String> _strings(String lang) => {
  for (final m in RegExp(r'^"(\w+)" = "(.*)";\s*$', multiLine: true).allMatches(
    File('ios/Runner/$lang.lproj/InfoPlist.strings').readAsStringSync(),
  ))
    m.group(1)!: m.group(2)!,
};

/// The `<string>` right after `<key>[key]</key>` in `Info.plist`.
String _plistValue(String plist, String key) => RegExp(
  '<key>$key</key>\\s*<string>([^<]*)</string>',
).firstMatch(plist)!.group(1)!;

void main() {
  test(
    'each prompt is English in Info.plist and en.lproj, Arabic in ar.lproj',
    () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final en = _strings('en');
      final ar = _strings('ar');

      expect(en.keys, unorderedEquals(_keys));
      expect(ar.keys, unorderedEquals(_keys));
      for (final key in _keys) {
        expect(_plistValue(plist, key), en[key], reason: key);
        expect(en[key], isNot(matches(_arabic)), reason: key);
        expect(ar[key], matches(_arabic), reason: key);
      }
    },
  );

  test('both files are in the Runner target, and Arabic is a known region', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(project, contains('path = en.lproj/InfoPlist.strings;'));
    expect(project, contains('path = ar.lproj/InfoPlist.strings;'));
    expect(project, contains('/* InfoPlist.strings in Resources */,'));
    expect(
      project,
      matches(RegExp(r'knownRegions = \(\s*en,\s*Base,\s*ar,\s*\);')),
    );
  });

  test('the Codemagic build fails unless both reach the app', () {
    final ci = File('codemagic.yaml').readAsStringSync();

    expect(ci, contains('for LPROJ in ar.lproj en.lproj; do'));
    expect(ci, contains(r'Runner.app/$LPROJ/InfoPlist.strings'));
  });
}
