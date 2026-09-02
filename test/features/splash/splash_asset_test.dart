import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/splash/presentation/splash_reveal_policy.dart';

/// Guards the shipped splash asset itself, not the code that plays it.
///
/// The decision this pins: the splash must never make a sound. On iOS the
/// player engages the playback audio session category when a file HAS an audio
/// track, and that category deliberately ignores the ring/silent switch — so a
/// muted call is not enough, the track has to be absent. For a marriage app,
/// announcing to a room that someone opened it contradicts the premise.
///
/// `setVolume(0)` in the widget is belt-and-braces. THIS is the guarantee.
void main() {
  final asset = File('assets/animations/logo_qeran_v8_silent.mp4');

  test('the splash asset is present', () {
    expect(asset.existsSync(), isTrue);
  });

  test('carries no audio track at all', () {
    final bytes = asset.readAsBytesSync();

    // An MP4 names each track with an `hdlr` box; an audio one is `soun`, and
    // AAC audio additionally carries `mp4a` / `esds` sample entries. None of
    // the three may appear.
    expect(_contains(bytes, 'soun'), isFalse, reason: 'audio track handler');
    expect(_contains(bytes, 'mp4a'), isFalse, reason: 'AAC sample entry');
    expect(_contains(bytes, 'esds'), isFalse, reason: 'AAC decoder config');
  });

  test('does carry a video track, so the guard above is not vacuous', () {
    // Without this, a zero-byte or wrong file would pass the no-audio test by
    // containing nothing at all.
    final bytes = asset.readAsBytesSync();

    expect(_contains(bytes, 'vide'), isTrue);
    expect(bytes.length, greaterThan(1000));
  });

  test('the length the policy is built on matches the real file', () {
    // SplashRevealPolicy.assetDuration is DECLARED, not discovered — the
    // backstop timer is armed before the player has loaded anything, so it
    // cannot ask. That declaration is only as good as this check: without it,
    // the constant can drift away from the asset and the derived backstop
    // silently loses its headroom.
    final actual = _durationOf(asset.readAsBytesSync());

    expect(
      (SplashRevealPolicy.assetDuration - actual).abs(),
      lessThan(const Duration(milliseconds: 100)),
      reason:
          'policy says ${SplashRevealPolicy.assetDuration.inMilliseconds}ms, '
          'the shipped asset is ${actual.inMilliseconds}ms',
    );
  });

  test('the backstop outlasts the real file, not just the declared length', () {
    final actual = _durationOf(asset.readAsBytesSync());

    expect(const SplashRevealPolicy().safetyCap, greaterThan(actual));
  });
}

/// The movie header box carries the asset length as `duration / timescale`.
Duration _durationOf(Uint8List bytes) {
  final at = _indexOf(bytes, 'mvhd');
  expect(at, isNonNegative, reason: 'no mvhd box — not a readable MP4');
  final data = ByteData.sublistView(bytes);
  final version = bytes[at + 4];
  // Version 0 stores 32-bit fields; version 1 widens them and shifts the
  // offsets, so both layouts have to be read on their own terms.
  final timescale = version == 0
      ? data.getUint32(at + 16)
      : data.getUint32(at + 24);
  final ticks = version == 0
      ? data.getUint32(at + 20)
      : data.getUint64(at + 28);
  expect(timescale, greaterThan(0));
  return Duration(milliseconds: (ticks * 1000 / timescale).round());
}

bool _contains(List<int> haystack, String needle) =>
    _indexOf(haystack, needle) >= 0;

/// Byte offset of an ASCII box name, or -1.
int _indexOf(List<int> haystack, String needle) {
  final pattern = needle.codeUnits;
  for (var i = 0; i <= haystack.length - pattern.length; i++) {
    var hit = true;
    for (var j = 0; j < pattern.length; j++) {
      if (haystack[i + j] != pattern[j]) {
        hit = false;
        break;
      }
    }
    if (hit) return i;
  }
  return -1;
}
