import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Xcode project file, not any Dart code.
///
/// `GoogleService-Info.plist` sat in `ios/Runner/` for months while
/// `project.pbxproj` never mentioned it, so it was never copied into the app
/// bundle and the Google Sign-In plugin had no client ID to read. That is the
/// iOS sign-in failure the App Store review hit — a file present in the folder
/// but absent from the target.
///
/// Nothing on a Windows machine can compile an Xcode project, so this test is
/// the only automated check that survives here. It traces the CHAIN Xcode
/// builds — file on disk → PBXFileReference → PBXBuildFile pointing at that
/// reference → the Runner Resources phase listing that build file — because
/// each link can exist while the next one is missing, and the broken state we
/// are fixing had three of the four absent.
///
/// It cannot tell you the build succeeds. Only a real `xcodebuild` can, and
/// the pass condition there is `Runner.app/GoogleService-Info.plist` existing
/// in the artifact — a green build alone proves nothing, since the broken
/// state built green too.
void main() {
  final plist = File('ios/Runner/GoogleService-Info.plist');
  final project = File('ios/Runner.xcodeproj/project.pbxproj');
  late String src;

  setUpAll(() {
    src = project.readAsStringSync();
  });

  const plistName = 'GoogleService-Info.plist';

  // The Runner target's Copy Bundle Resources phase, and the RunnerTests one
  // it must never leak into.
  const runnerResources = '97C146EC1CF9000F007C117D';
  const testsResources = '331C807F294A63A400263BE5';

  test('the plist is actually on disk', () {
    // A registration pointing at a missing file is worse than no registration:
    // it builds, and the bundle still has nothing to read.
    expect(plist.existsSync(), isTrue);
    expect(project.existsSync(), isTrue);
  });

  group('the registration chain', () {
    test('a PBXFileReference names the plist', () {
      expect(
        _fileRefUuid(src, plistName),
        isNotNull,
        reason: 'the project does not know the file exists',
      );
    });

    test('a PBXBuildFile wraps that exact file reference', () {
      final ref = _fileRefUuid(src, plistName)!;

      expect(
        _buildFileUuid(src, ref),
        isNotNull,
        reason: 'a file reference alone is a navigator entry, not a build '
            'input — the PBXBuildFile is what a phase can list',
      );
    });

    test('the Runner Resources phase lists that build file', () {
      final ref = _fileRefUuid(src, plistName)!;
      final build = _buildFileUuid(src, ref)!;

      expect(
        _phaseBody(src, runnerResources),
        contains(build),
        reason: 'THIS is the line whose absence caused the sign-in failure: '
            'the file was in the project and not in the target, so it was '
            'never copied into Runner.app',
      );
    });

    test('the chain is followed by UUID, not by name appearing somewhere', () {
      final ref = _fileRefUuid(src, plistName)!;
      final build = _buildFileUuid(src, ref)!;

      // A build file pointing at a DIFFERENT reference would still put the
      // plist's name in the file and still put a UUID in the phase. What makes
      // it real is that these two are linked.
      expect(build, isNot(ref));
      expect(
        RegExp('$build /\\* [^*]* \\*/ = \\{isa = PBXBuildFile; fileRef = $ref')
            .hasMatch(src),
        isTrue,
        reason: 'the build file in the phase must resolve to the plist itself',
      );
    });
  });

  test('RunnerTests does not carry it', () {
    final ref = _fileRefUuid(src, plistName)!;
    final build = _buildFileUuid(src, ref)!;

    expect(
      _phaseBody(src, testsResources),
      isNot(contains(build)),
      reason: 'the test bundle is not the app bundle — registering it there '
          'reads as success and ships nothing',
    );
  });

  test('the lookup reports nothing for a file that is not registered', () {
    // Without this, a helper that matched too loosely would report every
    // assertion above as passing no matter what the project said.
    expect(_fileRefUuid(src, 'NotARealFile.plist'), isNull);
    expect(_buildFileUuid(src, 'DEADBEEFDEADBEEFDEADBEEF'), isNull);
  });

  test('the plist identifies the same app the Runner target builds', () {
    // A correctly registered plist for the WRONG bundle id fails at runtime in
    // exactly the way we are trying to fix.
    final bundleId = RegExp(
      r'<key>BUNDLE_ID</key>\s*<string>([^<]+)</string>',
    ).firstMatch(plist.readAsStringSync())?.group(1);
    expect(bundleId, isNotNull);

    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
        .allMatches(src)
        .map((m) => m.group(1)!)
        .where((id) => !id.endsWith('.RunnerTests'))
        .toList();

    expect(
      ids,
      hasLength(3),
      reason: 'Debug, Release and Profile — a missing one means a config that '
          'ships under an identity nothing checked',
    );
    expect(ids.toSet(), <String>{bundleId!});
  });
}

/// UUID of the `PBXFileReference` whose comment names [fileName], or null.
String? _fileRefUuid(String src, String fileName) => RegExp(
      '([0-9A-F]{24}) /\\* ${RegExp.escape(fileName)} \\*/ = '
      r'\{isa = PBXFileReference;',
    ).firstMatch(src)?.group(1);

/// UUID of the `PBXBuildFile` pointing at [fileRefUuid], or null.
String? _buildFileUuid(String src, String fileRefUuid) => RegExp(
      '([0-9A-F]{24}) /\\* [^*]* \\*/ = '
      '\\{isa = PBXBuildFile; fileRef = $fileRefUuid',
    ).firstMatch(src)?.group(1);

/// The body of a build phase, from its opening brace to the closing `};`.
///
/// Safe to bound on the first `};` — a phase's `files` list is parenthesised,
/// so no nested brace intervenes.
String _phaseBody(String src, String phaseUuid) {
  final start = src.indexOf('$phaseUuid /* Resources */ = {');
  expect(start, isNot(-1), reason: 'build phase $phaseUuid not found');
  return src.substring(start, src.indexOf('};', start));
}
